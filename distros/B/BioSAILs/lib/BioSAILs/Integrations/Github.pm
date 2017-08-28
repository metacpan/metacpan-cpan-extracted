package BioSAILs::Integrations::Github;

use MooseX::App::Role;
use namespace::autoclean;

use Git::Wrapper;
use Git::Wrapper::Plus::Ref::Tag;
use Git::Wrapper::Plus::Tags;
use Git::Wrapper::Plus::Branches;

use Try::Tiny;

use Sort::Versions;
use Version::Next qw/next_version/;

use Cwd;
use List::Util qw(uniq);
use File::Path qw(make_path);
use File::Slurp;
use File::Spec;
use File::Temp qw/ tempfile tempdir /;
use Capture::Tiny ':all';
use Data::Dumper;
use DateTime;

with 'BioSAILs::Utils';

option 'version' => (
    is        => 'rw',
    required  => 0,
    predicate => 'has_version',
    documentation =>
      'Submission version. Each version has a corresponding git tag.'
      . ' See the difference between tags with `git diff tag1 tag2`.'
      . ' Tags are always version numbers, starting with 0.01.',
);

option 'autocommit' => (
    traits        => ['Bool'],
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    documentation => 'Always commit files.',
    handles       => { no_autocommit => 'unset', },
);

=head3 tags

Additional tags for commit message

=cut

option 'tags' => (
    traits        => ['Array'],
    is            => 'rw',
    isa           => 'ArrayRef',
    documentation => 'Annotate with tags.',
    required      => 0,
    default       => sub { [] },
    handles       => {
        has_tags   => 'count',
        count_tags => 'count',
        join_tags  => 'join',
        all_tags   => 'elements',
    },
    cmd_aliases => ['t'],
    cmd_split   => qr/,/,
);

option 'message' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    predicate     => 'has_message',
    cmd_aliases   => ['m'],
    default       => 'hpcrunner commit',
    documentation => 'Message to use for git commit',
);

has 'git_dir' => (
    is        => 'rw',
    isa       => 'Str',
    default   => sub { return cwd() },
    predicate => 'has_git_dir',
);

has 'git' => (
    is        => 'rw',
    predicate => 'has_git',
    required  => 0,
);

has 'current_branch' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_current_branch',
);

has 'remote' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_remote',
);

has 'tag_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'hpcrunner',
);

=head2 Subroutines

=cut

=head3 init_git

Create a new Git::Wrapper object

=cut

sub init_git {
    my $self = shift;

    my $git = Git::Wrapper->new( cwd() )
      or die print "Could not initialize Git::Wrapper $!\n";

    try {
        my @output = $git->rev_parse(qw(--show-toplevel));
        $self->git_dir( $output[0] );
        $git = Git::Wrapper->new( $self->git_dir );
        $self->git($git);
    }

}

sub git_info {
    my $self = shift;

    return unless $self->has_git;

    $self->branch_things;
    $self->get_version;
}

=head3 dirty_run

Check for uncommited files
#TODO add in option for autocommiting

=cut

sub dirty_run {
    my $self = shift;

    return unless $self->has_git;

    my $dirty_flag = $self->git->status->is_dirty;

    if ( $dirty_flag && !$self->autocommit ) {
    $self->app_log->warn(
        "There are uncommited files in your repo!\n\tPlease commit these files."
    );
    }
    elsif ( $dirty_flag && $self->autocommit ) {
        $self->commit_git_files;
    }
}

sub commit_git_files {
    my $self = shift;
        $self->app_log->warn( "There are uncommited files in your repo!\n\t"
              . "We will try to commit these files before running.\n" );

    try {
        my $cmd = 'git add -A';
        $self->run_short_command($cmd);

        my $msg = $self->gen_git_commit_message;
        my ( $fh, $filename ) = tempfile();
        write_file( $filename, $msg );

        $cmd = 'git commit -F ' . $filename;
        my $res = $self->run_short_command($cmd);

        $self->app_log->info("Successfully commited files to git.");
    }
    catch {
        $self->app_log->warn("Were not able to commit files to git");
        $self->app_log->warn( "STDERR: " . $_->error );
        $self->app_log->warn( "STDOUT: " . $_->output );
        $self->app_log->warn( "STATUS: " . $_->status );
    }
}

sub gen_git_commit_message {
    my $self = shift;

    my $dt = DateTime->now( time_zone => 'local' );
    my $text = "";
    $text .= $self->message . "\n";
    $text .= "[DateTime]: $dt\n";
    if ( $self->count_tags ) {
        $text .= "[ Tags ]: " . $self->join_tags(', ') . "\n";
    }

    return $text;
}

sub branch_things {
    my $self = shift;

    return unless $self->has_git;
    my $current;

    try {
        my $branches = Git::Wrapper::Plus::Branches->new( git => $self->git );

        for my $branch ( $branches->current_branch ) {
            $self->current_branch( $branch->name );
        }
    }
    catch {
        $self->current_branch('master');
    }
}

sub git_config {
    my ($self) = @_;

    return unless $self->has_git;

    #First time we run this we want the name, username, and email
    my @output = $self->git->config(qw(--list));

    my %config = ();
    foreach my $c (@output) {
        my @words = split /=/, $c;
        $config{ $words[0] } = $words[1];
    }
    return \%config;
}

sub git_logs {
    my ($self) = shift;

    return unless $self->has_git;
    my @logs = $self->git->log;
    return \@logs;
}

sub get_version {
    my ($self) = shift;

    return unless $self->has_git;
    return if $self->has_version;

    my $cmd =
        'git describe --tags '
      . '$(git rev-list --tags --max-count=1 )'
      . ' --match "hpcrunner*"';

    my $res = $self->run_short_command($cmd);

    my @versions;
    ##These exit codes are screwy...
    if ( defined $res->{exit_code} ) {
        foreach my $buf ( @{ $res->{full_buffer} } ) {
            chomp($buf);
            if ( $buf =~ m/^hpcrunner-\d+\.\d+/ ) {
                push( @versions, $buf );
            }
        }
    }
    @versions = () unless @versions;

    ##TODO Make this dynamic - should be the prefix
    if ( @versions && $#versions >= 0 ) {
        my $version = $versions[0];
        $version =~ s/hpcrunner-//g;
        my $pv = next_version($version);
        $pv = "$pv";
        $self->version( 'hpcrunner-' . $pv );
    }
    else {
        $self->version('hpcrunner-0.01');
    }

    $self->git_create_tags;
    $self->git_push_tags;
}

sub git_create_tags {
    my $self = shift;
    my ( $fh, $filename ) = tempfile();

    my $text = "BioSAILs Commit\n\n";

    if ( $self->count_tags ) {
        $text .= "[ Version ]: " . $self->version . "\n";
        $text .= "[ Tags ]: " . $self->join_tags(', ') . "\n";
    }
    write_file( $filename, $text );
    my $git_command = "git tag -a " . $self->version . " -F " . $filename;
    my $res         = $self->run_short_command($git_command);
}

#TODO Make this an option
sub git_push_tags {
    my ($self) = shift;

    $self->app_log->debug('Pushing git tags...');
    return unless $self->has_git;
    return unless $self->has_version;

    if ( $self->git->status->is_dirty ) {
        $self->app_log->fatal(
            "We have noticed a dirty commit while trying to generate tags...\n"
        );
    }
    return if $self->git->status->is_dirty;

    my @remote = $self->git->remote;

    foreach my $remote (@remote) {
        $self->git->push( { tags => 1 }, $remote );
    }

}

1;
