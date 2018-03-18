package App::Wax;

use 5.008008;

use Digest::SHA qw(sha1_hex);
use File::Slurp qw(read_file write_file);
use File::Spec;
use File::Temp;
use IPC::System::Simple qw(EXIT_ANY $EXITVAL systemx);
use LWP::UserAgent;
use Method::Signatures::Simple;
use MIME::Types;
use Mouse;
use Parallel::parallel_map qw(parallel_map);
use Pod::Usage qw(pod2usage);
use Try::Tiny qw(try catch);
use URI::Split qw(uri_split);

our $VERSION = '2.1.0';

# defaults
use constant {
    CACHE      => 0,
    ENV_PROXY  => 1,
    EXTENSION  => qr/.(\.(?:(tar\.(?:bz|bz2|gz|lzo|Z))|(?:[ch]\+\+)|(?:\w+)))$/i,
    INDEX      => '%s.index.txt',
    MIRROR     => 0,
    NAME       => 'wax',
    SEPARATOR  => '--',
    TEMPLATE   => 'XXXXXXXX',
    TIMEOUT    => 60,
    USER_AGENT => 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:50.0) Gecko/20100101 Firefox/50.0',
    VERBOSE    => 0,
};

# errors
use constant {
    OK                  =>  0,
    E_DOWNLOAD          => -1,
    E_INVALID_OPTION    => -2,
    E_INVALID_OPTIONS   => -3,
    E_INVALID_DIRECTORY => -4,
    E_NO_ARGUMENTS      => -5,
    E_NO_COMMAND        => -6,
};

has app_name => (
    is      => 'rw',
    isa     => 'Str',
    default => NAME,
);

has cache => (
    is      => 'rw',
    isa     => 'Bool',
    default => CACHE,
    trigger => \&_check_keep,
);

has directory => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_directory',
    required  => 0,
    trigger   => \&_check_directory,
);

has keep => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    writer   => '_set_keep',
);

has _lwp_user_agent => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    builder => '_build_lwp_user_agent',
);

# this should really be a class attribute, but there's no MouseX::ClassAttribute
# (on CPAN)
has mime_types => (
    is      => 'ro',
    isa     => 'MIME::Types',
    lazy    => 1,
    default => sub { MIME::Types->new() },
);

has mirror => (
    is      => 'rw',
    isa     => 'Bool',
    default => MIRROR,
    trigger => \&_check_keep,
);

has separator => (
    is        => 'rw',
    isa       => 'Str',
    default   => SEPARATOR,
    clearer   => 'clear_separator',
    predicate => 'has_separator',
);

# TODO make this private and read only, and rename it to something more
# descriptive e.g. tempfile_template
has template => (
    is      => 'rw',
    isa     => 'Str',
    default => method () { sprintf('%s_%s', $self->app_name, TEMPLATE) },
    lazy    => 1,
);

has timeout => (
    is      => 'rw',
    isa     => 'Int',
    default => TIMEOUT,
    trigger => method ($timeout) { $self->_lwp_user_agent->timeout($timeout) },
);

has user_agent => (
    is      => 'rw',
    isa     => 'Str',
    default => USER_AGENT,
    trigger => method ($user_agent) { $self->_lwp_user_agent->agent($user_agent) },
);

has verbose => (
    is      => 'rw',
    isa     => 'Bool',
    default => VERBOSE,
    trigger => method ($verbose) { $| = 1 }, # unbuffer output
);

# log the path. if the directory doesn't exist, create it if its parent directory
# exists; otherwise, raise an error
method _check_directory ($dir) {
    $self->debug("directory: $dir");

    unless (-d $dir) {
        unless (mkdir $dir) {
            $self->log(ERROR => "Can't create directory (%s): %s", $dir, $!);
            exit E_INVALID_DIRECTORY;
        }
    }
}

# lazy constructor for the default LWP::UserAgent instance
method _build_lwp_user_agent {
    LWP::UserAgent->new(
        env_proxy => ENV_PROXY,
        timeout   => $self->timeout,
        agent     => $self->user_agent
    )
}

# set `keep` to true if --cache or --mirror are set,
# but raise an error if both are set
method _check_keep {
    if ($self->cache && $self->mirror) {
        $self->log(ERROR => "--cache and --mirror can't be used together");
        exit E_INVALID_OPTIONS;
    } else {
        $self->_set_keep(1);
    }
}

# remove temporary files
method _unlink ($unlink) {
    for my $filename (@$unlink) {
        chmod 0600, $filename; # borrowed from File::Temp (may be needed on Windows)
        $self->debug('removing: %s', $filename);
        unlink($filename) || $self->log(WARN => "Can't unlink %s: %s", $filename, $!);
    }
}

# return the URL's content type or an empty string if the request fails
method content_type ($url) {
    my $response = $self->_lwp_user_agent->head($url);
    my $content_type = '';

    if ($response->is_success) {
        ($content_type) = scalar($response->header('Content-Type')) =~ /^([^;]+)/;
        $self->debug('content type: %s', $content_type);
    }

    return $content_type;
}

# save the URL to a local filename
method download ($url, $filename) {
    my $ua = $self->_lwp_user_agent;
    my ($downloaded, $error, $response);

    if ($self->cache && (-e $filename)) {
        $downloaded = 0;
    } elsif ($self->mirror) {
        $response = $ua->mirror($url, $filename);

        if ($response->is_success) {
            $downloaded = 1;
        } elsif ($response->code == 304) {
            $downloaded = 0;
        }
    } else {
        $response = $ua->get($url, ':content_file' => $filename);

        if ($response->is_success) {
            $downloaded = 1;
        }
    }

    if (defined $downloaded) {
        $self->debug('download (%s): %s', ($downloaded ? 'yes' : 'no'), $url);
    } else {
        my $status = $response->status_line;
        $error = "can't download URL ($url) to filename ($filename): $status";
    }

    return $error;
}

# helper for `dump_command`: escape/quote a shell argument on POSIX shells
func _escape ($arg) {
    # https://stackoverflow.com/a/1250279
    # https://github.com/boazy/any-shell-escape/issues/1#issuecomment-36226734
    $arg =~ s!('{1,})!'"$1"'!g;
    $arg = "'$arg'";
    $arg =~ s{^''|''$}{}g;
    return $arg;
}

# log a message to stderr with the app's name and message's log level
method log ($level, $template, @args) {
    my $name = $self->app_name;
    my $message = @args ? sprintf($template, @args) : $template;
    warn "$name: $level: $message", $/;
}

# return a best-effort guess at the URL's extension, e.g. ".md" or ".tar.gz",
# or an empty string if one can't be determined
method extension ($url) {
    my $extension = '';
    my $split = $self->is_url($url);

    return $extension unless ($split);

    my ($scheme, $domain, $path, $query, $fragment) = @$split;
    my $content_type = $self->content_type($url);

    return $extension unless ($content_type); # won't be defined if the URL is invalid

    if (($content_type eq 'text/plain') || ($content_type eq 'application/octet-stream')) {
        # try to get a more specific extension from the path
        if (not(defined $query) && $path && ($path =~ EXTENSION)) {
            $extension = $+;
        }
    }

    unless ($extension) {
        my $mime_type = $self->mime_types->type($content_type);
        my @extensions = $mime_type->extensions;

        if (@extensions) {
            $extension = '.' . $extensions[0];
        }
    }

    $self->debug('extension: %s', $extension);

    return $extension;
}

# return a truthy value (an arrayref containing the URL's components)
# if the supplied value can be parsed as a URL, or a falsey value otherwise
method is_url ($url) {
    if ($url =~ m{^[a-zA-Z][\w+]*://}) { # basic sanity check
        my ($scheme, $domain, $path, $query, $fragment) = uri_split($url);
        if ($scheme && ($domain || $path)) { # no domain for file:// URLs
            return [ $scheme, $domain, $path, $query, $fragment ];
        }
    }
}

# log a message to stderr if logging is enabled
method debug ($template, @args) {
    if ($self->verbose) {
        my $name = $self->app_name;
        my $message = @args ? sprintf($template, @args) : $template;
        warn "$name: $message", $/;
    }
}

# perform housekeeping after a download: replace the placeholder
# with the file path; push the path onto the delete list if
# it's a temporary file; and log any errors
method _handle ($resolved, $command, $unlink) {
    my ($index, $filename, $error) = @$resolved;

    $command->[$index] = $filename;

    unless ($self->keep) {
        push @$unlink, $filename;
    }

    if ($error) {
        $self->log(ERROR => $error);
        return E_DOWNLOAD;
    } else {
        return OK;
    }
}

# this is purely for diagnostic purposes i.e. there's no guarantee
# that the dumped command can be used as a command line. a better
# (but still imperfect/incomplete) implementation would require at
# least two extra modules: Win32::ShellQuote and String::ShellQuote:
# https://rt.cpan.org/Public/Bug/Display.html?id=37348
method dump_command ($args) {
    return join(' ', map { /[^0-9A-Za-z+,.\/:=\@_-]/ ? _escape($_) : $_ } @$args);
}

# takes a URL and returns a $filename => $error pair where
# the filename is the path to the saved file and the error
# is the first error message encountered while trying to download
# and save it
method resolve ($url) {
    my ($error, $filename, @resolved);

    if ($self->keep) {
        ($filename, $error) = $self->resolve_keep($url);
    } else {
        ($filename, $error) = $self->resolve_temp($url);
    }

    $error ||= $self->download($url, $filename);
    @resolved = ($filename, $error);

    return wantarray ? @resolved : \@resolved;
}

# takes a URL and returns a $filename => $error pair for
# cacheable files
method resolve_keep ($url) {
    my $directory = $self->has_directory ? $self->directory : File::Spec->tmpdir;
    my $id        = sprintf('%s_%s', $self->app_name, sha1_hex($url));
    my $index     = File::Spec->catfile($directory, sprintf(INDEX, $id));
    my ($error, $extension, $filename);

    if (-e $index) {
        $self->debug('index (exists): %s', $index);
        $extension = read_file($index);
    } else {
        $self->debug('index (create): %s', $index);
        $extension = $self->extension($url);

        unless (write_file($index, $extension)) {
            $error = "unable to write to $index: $!";
        }
    }

    $filename = File::Spec->catfile($directory, "$id$extension");

    return ($filename, $error);
}

# takes a URL and returns a $filename => $error pair for
# temporary files (i.e. files which will be automatically unlinked)
method resolve_temp ($url) {
    my $extension = $self->extension($url);
    my $template  = $self->template;
    my %options   = (TEMPLATE => $template, UNLINK => 0);
    my $directory = $self->directory;

    if (defined $directory) {
        $options{DIR} = $directory;
    } else {
        $options{TMPDIR} = 1;
    }

    if ($extension) {
        $options{SUFFIX} = $extension;
    }

    my ($filename, $error);

    try {
        srand($$); # see the File::Temp docs
        $filename = File::Temp->new(%options)->filename;
    } catch {
        $error = $_;
    };

    return ($filename, $error);
}

# process the options and execute the command with substituted filenames
method run ($argv) {
    my @argv = @$argv;

    unless (@argv) {
        pod2usage(
            -exitval => E_NO_ARGUMENTS,
            -input   => $0,
            -msg     => 'no arguments supplied',
            -verbose => 0,
        );
    }

    my $wax_options = 1;
    my $seen_url = 0;
    my $test = 0;
    my (@command, @resolve);

    while (@argv) {
        my $arg = shift @argv;

        my $val = sub {
            if (@argv) {
                return shift(@argv);
            } else {
                pod2usage(
                    -exitval => E_INVALID_OPTION,
                    -input   => $0,
                    -msg     => "missing value for $arg option",
                    -verbose => 1,
                );
            }
        };

        if ($wax_options) {
            if ($arg =~ /^(?:-c|--cache)$/) {
                $self->cache(1);
            } elsif ($arg =~ /^(?:-d|--dir|--directory)$/) {
                $self->directory($val->());
            } elsif ($arg eq '-D') {
                # "${XDG_CACHE_HOME:-$HOME/.cache}/wax"
                require File::BaseDir;
                $self->directory(File::BaseDir::cache_home($self->app_name));
            } elsif ($arg =~ /^(?:-v|--verbose)$/) {
                $self->verbose(1);
            } elsif ($arg =~ /^(?:-[?h]|--help)$/) {
                pod2usage(-input => $0, -verbose => 2, -exitval => 0);
            } elsif ($arg =~ /^(?:-m|--mirror)$/) {
                $self->mirror(1);
            } elsif ($arg =~ /^(?:-s|--separator)$/) {
                $self->separator($val->());
            } elsif ($arg =~ /^(?:-S|--no-separator)$/) {
                $self->clear_separator();
            } elsif ($arg eq '--test') {
                $test = 1;
            } elsif ($arg =~ /^(?:-t|--timeout)$/) {
                $self->timeout($val->());
            } elsif ($arg =~ /^(?:-u|--user-agent)$/) {
                $self->user_agent($val->());
            } elsif ($arg =~ /^(?:-V|--version)$/) {
                print $VERSION, $/;
                exit 0;
            } elsif ($arg =~ /^-/) { # unknown option
                pod2usage(
                    -exitval => E_INVALID_OPTION,
                    -input   => $0,
                    -msg     => "invalid option: $arg",
                    -verbose => 1,
                );
            } else { # non-option: exit the wax-options processing stage
                push @command, $arg;
                $wax_options = 0;
            }
        } elsif ($self->has_separator && ($arg eq $self->separator)) {
            push @command, @argv;
            last;
        } elsif ($self->is_url($arg)) {
            unless ($seen_url) {
                $self->debug('user-agent: %s', $self->user_agent);
                $self->debug('timeout: %d', $self->timeout);
                $seen_url = 1;
            }

            $self->debug('url: %s', $arg);
            push @command, $arg;
            push @resolve, [ $#command, $arg ];
        } else {
            push @command, $arg;
        }
    }

    unless (@command) {
        $self->log(ERROR => 'no command supplied');
        return $test ? \@command : E_NO_COMMAND;
    }

    my $error = 0;
    my @unlink;

    if (@resolve) {
        if (@resolve == 1) {
            my ($index, $url) = @{ $resolve[0] };
            my @resolved = $self->resolve($url);

            $error = $self->_handle([ $index, @resolved ], \@command, \@unlink);
        } else {
            $self->debug('jobs: %d', scalar(@resolve));

            my @resolved = parallel_map { [ $_->[0], $self->resolve($_->[1]) ] } @resolve;

            for my $resolved (@resolved) {
                $error ||= $self->_handle($resolved, \@command, \@unlink);
            }
        }
    }

    $self->debug('command: %s', $self->dump_command(\@command));

    if ($error) {
        $self->debug('exit code: %d', $error);
        $self->_unlink(\@unlink);
        return $error;
    } elsif ($test) {
        return \@command;
    } else {
        try {
            # XXX hack to remove the "<error> in /path/to/App/Wax.pm line <line>"
            # noise. we just want the error message
            no warnings qw(redefine);
            local *IPC::System::Simple::croak = sub { die @_, $/ };
            systemx(EXIT_ANY, @command);
        } catch {
            chomp;
            $self->log(ERROR => $_);
        };

        $self->debug('exit code: %d', $EXITVAL);
        $self->_unlink(\@unlink);

        return $EXITVAL;
    }
}

__PACKAGE__->meta->make_immutable();

1;
