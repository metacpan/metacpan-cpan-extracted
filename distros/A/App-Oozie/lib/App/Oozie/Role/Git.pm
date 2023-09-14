package App::Oozie::Role::Git;
$App::Oozie::Role::Git::VERSION = '0.006';
use 5.010;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Types::Common qw( IsDir );
use File::Find::Rule;
use Git::Repository;
use Moo::Role;
use Text::Trim      qw( trim  );
use Types::Standard qw( CodeRef );
use MooX::Options;

option gitfeatures => (
    is        => 'rw',
    default   => 0,
    negatable => 1,
    doc       => 'Enable git features?',
);

option gitforce => (
    is       => 'rw',
    doc      => 'Force deployment despite git check failure(s)',
);

option git_repo_path => (
    is      => 'rw',
    isa     => IsDir,
    format  => 's',
    doc     => 'Git repository base path for workflows',
    default => sub { },
);

has git_deploy_tag_pattern => (
    is      => 'rw',
    default => sub { qr// },
);

has git_tag_fetcher => (
    is      => 'rw',
    isa     => CodeRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return if ! $self->gitfeatures;
        die "git_tag_fetcher was not set!";
    },
);

has dirty_deployed_files => (
    is => 'rw',
    default => sub {return 0},
    );

has git => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        return if ! $self->gitfeatures;
        return Git::Repository->new( work_tree => $self->git_repo_path );
    },
    lazy => 1,
);

sub get_latest_git_commit {
    my $self = shift;
    die "Git features are disabled!" if ! $self->gitfeatures;
    $self->git->run( 'rev-parse' => 'HEAD' );
}

sub get_git_status {
    my $self = shift;
    die "Git features are disabled!" if ! $self->gitfeatures;
    $self->git->run( status => qw( -s -b --porcelain ) );
}

sub get_git_sha1_of_folder {
    my $self = shift;
    my $folder = shift;

    die "Git features are disabled!" if ! $self->gitfeatures;

    my $repo_dir = $self->git_repo_path;
    my $git      = $self->git;

    return $git->run('rev-list',"-1","HEAD","--",$folder);
}

sub get_git_info_on_all_files_in {
    my $self = shift;
    my $folder = shift;

    die "Git features are disabled!" if ! $self->gitfeatures;

    my $logger   = $self->logger;

    my @all_files_in_folder = File::Find::Rule
                                ->file
                                ->extras({ follow => 1 })
                                ->in( $folder );

    # Note that this ideally should be kept up-to-date with lib/ttree.cfg
    @all_files_in_folder = grep { $_ !~ /.sw[a-z]$/ } @all_files_in_folder;

    $logger->info(
        sprintf 'Collecting git logs for %d files (this might take a while)',
                    scalar @all_files_in_folder,
    );

    my @git_file_info_log = $self->_probe_git_for_file_history(
                                \@all_files_in_folder
                            );

    $logger->info('git information collected');

    return @git_file_info_log;
}

sub _probe_git_for_file_history {
    my $self = shift;
    my $files = shift;
    my @rv;

    foreach my $file ( @{ $files } ) {
        push @rv, $self->_collect_git_info( $file );
    }

    return @rv;
}

sub _collect_git_info {
    my $self     = shift;
    my $rel_file = shift;

    my $repo_dir = $self->git_repo_path;
    my $verbose  = $self->verbose;
    my $logger   = $self->logger;

    my $git_info = "";

    my $file = File::Spec->abs2rel($rel_file, $repo_dir);
    my $got_basic_data = 1;

    if ( $verbose ) {
        $logger->debug( sprintf '... processing %s ... ', $file );
    }

    eval {
        $git_info = $self->git->run("ls-files", "-s", $file);
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        $git_info = "$eval_error Have you set GIT_TREE to point to the repo you are deploying from, before running the script?";
        $got_basic_data = 0;
    };

    if ( ! $git_info) {
        $git_info = "No git data available for $file (not part of repository or the deployment is not being made from the repo this script knows of, see above)";
        $got_basic_data = 0;
    }

    if ( $got_basic_data ) {
        # slow
        $git_info .= sprintf " (%s)", $self->_collect_git_mtime( $file );
    }

    return $git_info;
}

sub _collect_git_mtime {
    # slow
    my $self = shift;
    my $file = shift;

    my $rv;

    $rv = eval {
        my @latest_git_log_record_for_file = $self->git->run("log", "-1", "--", $file);

        my $date_line_prefix        = "Date:";
        my $date_line_prefix_length = length($date_line_prefix);

        foreach my $line (@latest_git_log_record_for_file) {
            if (    length($line) > $date_line_prefix_length
                and substr($line, 0, $date_line_prefix_length) eq $date_line_prefix
             ) {
                 return trim
                         substr($line,
                                $date_line_prefix_length,
                                length($line) - $date_line_prefix_length
                         )
                 ;
            }
        }

        1;
    } or do {
        $rv = "Failed to get modification date. ".$@;
    };

    return $rv;
}

sub verify_git_tag {
    my $self = shift;

    die "Git features are disabled!" if ! $self->gitfeatures;

    my $oozie_base_dir = $self->local_oozie_code_path;
    my $repo_dir       = $self->git_repo_path;
    my $logger         = $self->logger;

    # If you are using http://git-deploy.github.io/ (for example)
    # then you may have tagged releases for live code which you
    # can have a check against in here.
    my $git_tag        = $self->git_tag_fetcher->() || die "Failed to locate a git tag!";
    my $gitforce       = $self->gitforce;

    my $git = $self->git;

    my $verify;
    eval {
        $verify = $git->run(
                    'show-ref',
                        '--tags',
                        '--verify',
                        'refs/tags/' . $git_tag,
                );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        if ( $eval_error =~ m{ fatal: .* \Qnot a valid ref\E  }xms ) {
            $logger->error(
                "Your repo does not seem to have the current live git-deploy tag.",
                "Be sure that your repo is up to date if you're using a local copy!",
                "If you are in a branch, be sure to have the latest changes (merge/rebase)."
            );
        }
        else {
            $logger->error( "Unknown error returned from git: $eval_error" );
        }
        $logger->logdie( 'Failed' ) if ! $gitforce;
    };

    $logger->info( "The current live tag `$git_tag` exists in the repo (that doesn't show that the repo is up to date)" );

    $logger->info( 'Probing the git status. This might take some time depending on the number of files and the state of the filesystem' );

    my(@dirty);
    eval {
        @dirty = $git->run('status', '--porcelain');
        $logger->info( 'Collected the git status' );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        if ( $eval_error =~ m{ \QNot a git repository (or any of the parent directories):\E }xms ) {
            $logger->error(
                "The repo directory $repo_dir is not a valid git repository.",
                " Please deploy from a repo",
            );
        }
        else {
            $logger->error( "git returned unknown error: $eval_error" );
        }
        $logger->logdie( 'Failed' ) if ! $gitforce;
    };

    return if not @dirty && !$gitforce;

    # 'M file', '?? file'
    @dirty = map { (split m{\s+}, trim($_), 2)[1] } @dirty;

    my $fail = 0;
    foreach my $dirt ( @dirty ) {
        my $test = $repo_dir . '/' . $dirt;
        if ( $test =~ m{ \A \Q$oozie_base_dir\E (.*) \z }xms) {
            $test = $1;
            $logger->warn( "The oozie workflow directory has untracked changes in $dirt" );
            $fail++;
        }
        else {
            $logger->warn( "Git reported a modified/new file in the repo: $test (ignoring as it's not in the workflow directory)" );
        }
        $self->dirty_deployed_files($fail);
    }

    if ( $fail ) {
        $logger->error( "Git tree is not clean and there are $fail untracked changes in the workflow path. Please deploy from a clean repo" );
        $logger->logdie( 'Failed' ) if ! $gitforce;
        $logger->warn( "Proceeding anyway, I hope you KNOW WHAT YOU'RE DOING" );
    }

    if ( !$fail || $fail && $gitforce ) {
        $logger->info( "The related paths are clean as far as git and this tool is concerned" );
    }

    return;
}

sub get_latest_git_tag {
    my $self = shift;

    die "Git features are disabled!" if ! $self->gitfeatures;

    my $pat  = $self->git_deploy_tag_pattern;
    my $latest_tag;

    eval {
        my $git = $self->git;

        my @all_tags = $git->run(
                            "for-each-ref",
                                '--sort=taggerdate',
                                '--format' => q['%(refname)'],
                                'refs/tags'
                        );

        for my $tag ( @all_tags ) {
            chomp $tag;
            $tag =~ s{ .+? \Qrefs/tags/\E }{}xms;
            $tag =~ s{ ['] \z }{}xms;
            next if $tag !~ $pat;
            $latest_tag = $tag;
        }
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        return "Failed to find latest tag in the git repo: ". $eval_error;
    };

    return $latest_tag || "Latest git tag not found in git repo";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Role::Git

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::Git';

    sub some_method {
        my $self = shift;
        if ( my $git = $self->git ) {
            # ...
        }
    }

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 NAME

App::Oozie::Role::Git - Internal role for git operations.

=head1 Methods

=head2 get_git_info_on_all_files_in

=head2 get_git_sha1_of_folder

=head2 get_git_status

=head2 get_latest_git_commit

=head2 get_latest_git_tag

=head2 verify_git_tag

=head1 Accessors

=head2 Overridable from cli

=head3 git_repo_path

=head3 gitfeatures

=head3 gitforce

=head2 Overridable from sub-classes

=head3 dirty_deployed_files

=head3 git

=head3 git_deploy_tag_pattern

=head3 git_tag_fetcher

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
