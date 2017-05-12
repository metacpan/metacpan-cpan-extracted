use strict; use warnings;
package App::AYCABTU;
our $VERSION = '0.13';

use Mouse;
use Getopt::Long;
use YAML::XS;
use Capture::Tiny 'capture';

has config => (is => 'ro', default => sub{[]});

has file => (is => 'ro', default => 'AYCABTU');
has action => (is => 'ro', default => 'list');
has show => (is => 'ro', default => '');
has tags => (is => 'ro', default => sub{[]});
has names => (is => 'ro', default => sub{[]});
has all => (is => 'ro', default => 0);
has quiet => (is => 'ro', default => 0);
has verbose => (is => 'ro', default => 0);
has args => (is => 'ro', default => sub{[]});

has repos => (is => 'ro', default => sub{[]});

my ($prefix, $error, $quiet, $normal, $verbose);

sub run {
    my $self = shift;
    my @opts = @_
        ? @_
        : split /\s+/, ($ENV{AYCABTU_DEFAULT_OPTS} || '');
    $self->get_options(@opts);
    $self->read_config();
    $self->select_repos();
    if (not @{$self->repos} and not @{$self->names}) {
        print "No repositories selected. Try --all.\n";
        return;
    }
    my $action = $self->action;
    my $method = "action_$action";
    die "Can't perform action '$action'\n"
        unless $self->can($method);
    for my $entry (@{$self->repos}) {
        ($prefix, $error, $quiet, $normal, $verbose) = ('') x 5;
        $self->$method($entry);
        $verbose ||= $normal;
        $normal ||= $quiet;
        my $msg =
            $error ? $error :
            $self->verbose ? $verbose :
            $self->quiet ? $quiet :
            $normal;
        $msg = "$prefix$msg\n" if $msg;
        print $msg;
    }
    if (@{$self->names}) {
        warn "The following names were not found: @{$self->names}\n";
    }
}

sub get_options {
    my $self = shift;
    local @ARGV = @_;
    GetOptions(
        'file=s' => sub { $self->file($_[1]) },
        'verbose' => sub { $self->verbose(1) },
        'quiet' => sub { $self->quiet(1) },
        'list' => sub { $self->action('list') },
        'update' => sub { $self->action('update') },
        'status' => sub { $self->action('status') },
        'show=s' => sub { $self->action('show'); $self->show($_[1]) },
        'all' => sub { $self->all(1) },
        'tags=s' => sub {
            my $tags = $_[1] or return;
            push @{$self->tags}, [split ',', $tags];
        },
        'help' => \&help,
    );
    no warnings;
    my $names;
    if (1 or not -t stdin) {
        $names = [
            map {
                s!/$!!;
                /^(\d+)-(\d+)?$/ ? ($1..$2) :
                /^(\d+)$/ ? ($1) :
                (-d) ? ($_) :
                ();
            } @ARGV
        ];
    }
    else {
        $names = [ split /\s+/, do {local $/; <stdin>} ]
    }
    $self->names($names);
    die "Can't locate aycabtu config file '${\ $self->file}'. Use --file=... option\n"
        if not -e $self->file and not @{[glob $self->file . '*']};
}

sub read_yaml {
    my $self = shift;
    my @files = glob($self->file . '*');
    my $yaml = '';
    local $/;
    for my $file (@files) {
        open Y, $file;
        $yaml .= <Y>;
    }
    return $yaml;
}

sub read_config {
    my $self = shift;
    my $yaml = $self->read_yaml();
    my $config = YAML::XS::Load($yaml);
    $self->config($config);
    die $self->file . " must be a YAML sequence of mapping"
        if (ref($config) ne 'ARRAY') or grep {
            ref ne 'HASH'
        } @$config;
    my $count = 1;
    for my $entry (@$config) {
        my $repo = $entry->{repo}
            or die "No 'repo' field for entry $count";

        $entry->{_num} = $count++;

        $entry->{name} ||= '';
        if (not $entry->{name} and $repo =~ /.*\/(.*).git$/) {
            my $name = $1;
            # XXX This should be configable.
            $name =~ s/\.wiki$/-wiki/;
            $entry->{name} = $name;
        }

        my $type = $entry->{type}  || '';
        $type ||=
            ($repo =~ /\.git$/) ? 'git' :
            ($repo =~ /svn/) ? 'svn' :
            '';
        $entry->{type} = $type;

        my $tags = $entry->{tags} || '';

        my $set = $tags ? { map {($_, 1)} split /[\s\,]+/, $tags } : {};
        my $str = $repo;
        $str =~ s/\/$//;
        $str =~ s/\/trunk$//;
        $str =~ s/.*\///;
        my $subst = {
            py => 'python',
            pm => 'perl',
        };
        $set->{$_} = 1 for map {$subst->{$_} || $_} split /[^\w]+/, $str;
        $set->{$type} = 1;
        delete $set->{''};

        $entry->{tags} = [ sort map lc, keys %$set ];
    }
}

sub select_repos {
    my $self = shift;

    my $config = $self->config;
    my $repos = $self->repos;
    my $names = $self->names;

    my $last = 0;
OUTER:
    for my $entry (@$config) {
        last if $last;
        next if $entry->{skip};
        $last = 1 if $entry->{last};

        if ($self->all) {
            push @$repos, $entry;
            next;
        }
        my ($num, $name) = @{$entry}{qw(_num name)};
        if (@$names) {
            if (grep {$_ eq $name or $_ eq $num} @$names) {
                push @$repos, $entry;
                @$names = grep {$_ !~ /^(\Q$name\E|$num)$/} @$names;
                next;
            }
        }
        for my $tags (@{$self->tags}) {
            if ($tags) {
                my $count = scalar grep {
                    my $t = $_;
                    grep {$_ eq $t} @{$entry->{tags}};
                } @$tags;
                if ($count == @$tags) {
                    push @$repos, $entry;
                    next OUTER;
                }
            }
        }
    }
}

sub action_update {
    my $self = shift;
    my $entry = shift;
    $self->_check(update => $entry) or return;
    my ($num, $name) = @{$entry}{qw(_num name)};
    $prefix = "$num) Updating $name... ";
    $self->git_update($entry);
}

sub action_status {
    my $self = shift;
    my $entry = shift;
    $self->_check('check status' => $entry) or return;
    my ($num, $name) = @{$entry}{qw(_num name)};
    $prefix = "$num) Status for $name... ";
    $self->git_status($entry);
}

sub action_list {
    my $self = shift;
    my $entry = shift;
    my ($num, $repo, $name, $type, $tags) = @{$entry}{qw(_num repo name type tags)};
    $prefix = "$num) ";
    $quiet = $name;
    $normal = sprintf " %-25s %-4s %-50s", $name, $type, $repo;
    $verbose = "$normal\n    tags: @$tags";
}

sub action_show {
    my $self = shift;
    my $entry = shift;
    my $show = $self->show;
    $prefix = '';
    if ($show =~ /^(nums?|numbers?)$/) {
        $quiet = $entry->{_num};
    }
    elsif ($show =~ /^names?$/) {
        $quiet = $entry->{name};
    }
    elsif ($show =~ /^tags?$/) {
        my $set = {};
        for my $repo (@{$self->repos}) {
            $set->{$_} = 1 for @{$repo->{tags}};
        }
        my @tags = sort keys %$set;
        print "@tags\n";
        exit;
    }
    else {
        $error = "Invalid type '$show' to show.";
    }
}

sub _check {
    my $self = shift;
    my $action = shift;
    my $entry = shift;
    my ($num, $repo, $name, $type) = @{$entry}{qw(_num repo name type)};
    if (not $name) {
        $error = "Can't $action $repo. No name.";
        return;
    }
    if (not $type) {
        $error = "Can't $action $name. Unknown type.";
        return;
    }
    if ($type ne 'git') {
        $error = "Can't $action $name. Type $type not yet supported.";
        return;
    }
    return 1;
}

sub git_update {
    my $self = shift;
    my $entry = shift;
    my ($repo, $name) = @{$entry}{qw(repo name)};
    if (not -d $name) {
        my $cmd = "git clone $repo $name";
        my ($o, $e) = capture { system($cmd) };
        if ($e =~ /\S/) {
            $quiet = 'Error';
            $verbose = "\n$o$e";
        }
        else {
            $normal = 'Done';
        }
    }
    elsif (-d "$name/.git") {
        my ($o, $e) = capture { system("cd $name; git pull origin master") };
        if ($o eq "Already up-to-date.\n") {
            $normal = "Already up to date";
        }
        elsif ($e) {
            $quiet = "Failed";
            $verbose = "\n$o$e";
        }
        else {
            $quiet = "Updated";
            $verbose = "\n$o$e";
        }
    }
    else {
        $quiet = "Skipped";
    }
}

sub git_status {
    my $self = shift;
    my $entry = shift;
    my ($repo, $name) = @{$entry}{qw(repo name)};
    if (not -d $name) {
        $error = "No local repository";
    }
    elsif (-d "$name/.git") {
        my ($o, $e) = capture { system("cd $name; git status") };
        if ($o =~ /^nothing to commit/m and
            not $e
        ) {
            if ($o =~ /Your branch is ahead .* by (\d+) /) {
                $quiet = "Ahead by $1";
                $verbose = "\n$o$e";
            }
            else {
                $normal = "OK";
            }
        }
        else {
            $quiet = "Dirty";
            $verbose = "\n$o$e";
        }
    }
    else {
        $quiet= "Skipped";
    }
}

sub help {
    print <<'...';
Usage:
    aycabtu [ options ] action selectors

Options:
    --file=file     # aycabtu config file. Default: 'AYCABTU'
    --verbose       # Show more information
    --quiet         # Show less information

Action:
    --list          # List the selected repos (default action)
    --update        # Checkout or update the selected repos
    --status        # Get status info on the selected repos
    --show=aspect   # Show some aspect of the selected repos

Show Aspects:
    numbers         # Show the numbers of the selected repos
    names           # Show the numbers of the selected repos
    tags            # Show ALL tags of selected repos

Selector:
    --all           # Use all the repos in the config file
    --tags=tags     # Select repos matching all the tags
                      Can be used more than once
    names           # A list of the names to to select. You can use
                    # multiple names and file globbing, like this:

        aycabtu --update foo-repo bar-*-repo

...
    exit;
}

1;
