package App::Wax;

use 5.008008;

use Digest::SHA qw(sha1_hex);
use File::Slurper qw(read_text write_text);
use File::Spec;
use File::Temp;
use Getopt::Long qw(GetOptionsFromArray :config posix_default require_order bundling no_auto_abbrev no_ignore_case);
use IPC::System::Simple qw(EXIT_ANY $EXITVAL systemx);
use LWP::UserAgent;
use Method::Signatures::Simple;
use MIME::Types;
use Mouse;
use Parallel::parallel_map qw(parallel_map);
use Pod::Usage qw(pod2usage);
use Try::Tiny qw(try catch);
use URI::Split qw(uri_split);

# NOTE this is the version of the *command* rather than the *module*, i.e.
# breaking API changes may occur here which aren't reflected in the SemVer since
# they don't break the behavior of the command
#
# XXX this declaration must be on a single line
# https://metacpan.org/pod/version#How-to-declare()-a-dotted-decimal-version
use version; our $VERSION = version->declare('v2.4.1');

# defaults
use constant {
    CACHE              => 0,
    DEFAULT_USER_AGENT => 'Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0',
    ENV_PROXY          => 1,
    ENV_USER_AGENT     => $ENV{WAX_USER_AGENT},
    EXTENSION          => qr/.(\.(?:(tar\.(?:bz|bz2|gz|lzo|Z))|(?:[ch]\+\+)|(?:\w+)))$/i,
    INDEX              => '%s.index.txt',
    MIRROR             => 0,
    NAME               => 'wax',
    SEPARATOR          => '--',
    TEMPLATE           => 'XXXXXXXX',
    TIMEOUT            => 60,
    VERBOSE            => 0,
};

use constant USER_AGENT => ENV_USER_AGENT || DEFAULT_USER_AGENT;

# RFC 2616: "If the media type remains unknown, the recipient SHOULD treat
# it as type 'application/octet-stream'."
use constant DEFAULT_CONTENT_TYPE => 'application/octet-stream';

# resources with these mime-types may have their extension inferred from the
# path part of their URI
use constant INFER_EXTENSION => {
    'text/plain'               => 1,
    'application/octet-stream' => 1,
    'binary/octet-stream'      => 1,
};

# errors
use constant {
    OK                  =>  0,
    E_DOWNLOAD          => -1,
    E_INVALID_DIRECTORY => -2,
    E_INVALID_OPTIONS   => -3,
    E_NO_COMMAND        => -4,
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
# descriptive, e.g. tempfile_template
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

# return the URL's content-type or an empty string if the request fails
method content_type ($_url) {
    my ($url, $url_index) = @$_url;
    my $response = $self->_lwp_user_agent->head($url);
    my $content_type = '';

    if ($response->is_success) {
        # the initial (pre-semicolon) part of the mime-type, trimmed and lowercased.
        $content_type = $response->headers->content_type;

        if ($content_type) {
            $self->debug('content-type (%d): %s', $url_index, $content_type);
        } else {
            $content_type = DEFAULT_CONTENT_TYPE;
            $self->debug('content-type (%d): %s (default)', $url_index, $content_type);
        }
    }

    return $content_type;
}

# save the URL to a local filename; returns an error message if an error occurred,
# or a falsey value otherwise
method download ($_url, $filename) {
    my ($url, $url_index) = @$_url;
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
        $self->debug('download (%d): %s', $url_index,  ($downloaded ? 'yes' : 'no'));
    } else {
        my $status = $response->status_line;
        $error = "can't download URL #$url_index ($url) to filename ($filename): $status";
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

method _use_default_directory () {
    # "${XDG_CACHE_HOME:-$HOME/.cache}/wax"
    require File::BaseDir;
    $self->directory(File::BaseDir::cache_home($self->app_name));
}

# print the version and exit
method _dump_version () {
    print $VERSION, $/;
    exit 0;
}

# log a message to stderr with the app's name and message's log level
method log ($level, $template, @args) {
    my $name = $self->app_name;
    my $message = @args ? sprintf($template, @args) : $template;
    warn "$name: $level: $message", $/;
}

# return a best-effort guess at the URL's file extension based on its content
# type, e.g. ".md" or ".tar.gz", or an empty string if one can't be determined.
# XXX note: makes a network request to determine the content type
method extension ($_url) {
    my ($url, $url_index) = @$_url;
    my $extension = '';
    my $split = $self->is_url($url);

    return $extension unless ($split);

    my ($scheme, $domain, $path, $query, $fragment) = @$split;
    my $content_type = $self->content_type($_url);

    return $extension unless ($content_type); # won't be defined if the URL is invalid

    if (INFER_EXTENSION->{$content_type}) {
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

    $self->debug('extension (%d): %s', $url_index, $extension);

    return $extension;
}

# return a truthy value (an arrayref containing the URL's components)
# if the supplied value can be parsed as a URL, or a falsey value otherwise
method is_url ($url) {
    if ($url =~ m{^[a-zA-Z][\w+]*://}) { # basic sanity check
        my ($scheme, $domain, $path, $query, $fragment) = uri_split($url);

        if ($scheme && ($domain || $path)) { # no domain for file:// URLs
            return [$scheme, $domain, $path, $query, $fragment];
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

# perform housekeeping after a download: replace the placeholder with the file
# path; push the path onto the delete list if it's a temporary file; and log any
# errors
#
# XXX give this a more descriptive name, e.g. _handle_download or _after_download
method _handle ($resolved, $command, $unlink) {
    my ($command_index, $filename, $error) = @$resolved;

    $command->[$command_index] = $filename;

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

# this is purely for diagnostic purposes, i.e. there's no guarantee
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
method resolve ($_url) {
    my ($error, $filename, @resolved);

    if ($self->keep) {
        ($filename, $error) = $self->resolve_keep($_url);
    } else {
        ($filename, $error) = $self->resolve_temp($_url);
    }

    $error ||= $self->download($_url, $filename);
    @resolved = ($filename, $error);

    return wantarray ? @resolved : \@resolved;
}

# takes a URL and returns a $filename => $error pair for cacheable files.
# in order to calculate the filename, we need to determine the URL's extension,
# which requires a network request for the content type. to avoid hitting the
# network for subsequent requests, we cache the extension in an index file.
method resolve_keep ($_url) {
    my ($url, $url_index) = @$_url;
    my $directory = $self->has_directory ? $self->directory : File::Spec->tmpdir;
    my $id = sprintf('%s_%s', $self->app_name, sha1_hex($url));
    my $index_file = File::Spec->catfile($directory, sprintf(INDEX, $id));
    my ($error, $extension);

    # -s: if /tmp is full, the index file may get written as an empty file, so
    # make sure it's non-empty
    if (-s $index_file) {
        $self->debug('index (%d): %s (exists)', $url_index, $index_file);

        try {
            $extension = read_text($index_file);
        } catch {
            $error = "unable to load index #$url_index ($index_file): $_";
        };
    } else {
        $self->debug('index (%d): %s (create)', $url_index, $index_file);
        $extension = $self->extension($_url);

        try {
            write_text($index_file, $extension);
        } catch {
            $error = "unable to save index #$url_index ($index_file): $_";
        };
    }

    my $filename = File::Spec->catfile($directory, "$id$extension");

    return ($filename, $error);
}

# takes a URL and returns a $filename => $error pair for
# temporary files (i.e. files which will be automatically unlinked)
method resolve_temp ($_url) {
    my $extension = $self->extension($_url);
    my %options   = (TEMPLATE => $self->template, UNLINK => 0);

    if ($self->has_directory) {
        $options{DIR} = $self->directory;
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

# parse the supplied arrayref of options and return a pair of:
#
#   command: an arrayref containing the command to execute and its arguments
#   resolve: an arrayref of [index, URL] pairs, where index refers to the URL's
#            (0-based) index in the commmand array
method _parse ($argv) {
    my @argv = @$argv; # don't mutate the original

    my $parsed = GetOptionsFromArray(\@argv,
        'c|cache'             => sub { $self->cache(1) },
        'd|dir|directory=s'   => sub { $self->directory($_[1]) },
        'D|default-directory' => sub { $self->_use_default_directory },
        'h|?|help'            => sub { pod2usage(-input => $0, -verbose => 2, -exitval => 0) },
        'm|mirror'            => sub { $self->mirror(1) },
        's|separator=s'       => sub { $self->separator($_[1]) },
        'S|no-separator'      => sub { $self->clear_separator() },
        't|timeout=i'         => sub { $self->timeout($_[1]) },
        'u|user-agent=s'      => sub { $self->user_agent($_[1]) },
        'v|verbose'           => sub { $self->verbose(1) },
        'V|version'           => sub { $self->_dump_version },
    );

    unless ($parsed) {
        pod2usage(
            -exitval => E_INVALID_OPTIONS,
            -input   => $0,
            -verbose => 0,
        );
    }

    my (@command, @resolve);
    my $seen_url = 0;

    while (@argv) {
        my $arg = shift(@argv);

        if ($self->has_separator && ($arg eq $self->separator)) {
            push @command, @argv;
            last;
        } elsif ($self->is_url($arg)) {
            unless ($seen_url) {
                my $source = ENV_USER_AGENT ? ' (env)'  : '';
                $self->debug('user-agent%s: %s', $source, $self->user_agent);
                $self->debug('timeout: %d', $self->timeout);
                $seen_url = 1;
            }

            my $url_index = @resolve + 1; # 1-based
            my $_url = [$arg, $url_index];

            $self->debug('url (%d): %s', $url_index, $arg);

            push @command, $arg;
            push @resolve, [$#command, $_url];
        } else {
            push @command, $arg;
        }
    }

    unless (@command) {
        pod2usage(
            -exitval => E_NO_COMMAND,
            -input   => $0,
            -msg     => 'no command supplied',
            -verbose => 0,
        )
    }

    return \@command, \@resolve;
}

# process the options and execute the command with substituted filenames
method run ($argv, %options) {
    my $test = $options{test};
    my $error = 0;
    my $unlink = [];
    my ($command, $resolve) = $self->_parse($argv);

    if (@$resolve == 1) {
        my ($command_index, $_url) = @{ $resolve->[0] };
        my @resolved = $self->resolve($_url);

        $error = $self->_handle([$command_index, @resolved], $command, $unlink);
    } elsif (@$resolve) {
        $self->debug('jobs: %d', scalar(@$resolve));

        my @resolved = parallel_map {
            my ($command_index, $_url) = @$_;
            [$command_index, $self->resolve($_url)]
        } @$resolve;

        for my $resolved (@resolved) {
            $error ||= $self->_handle($resolved, $command, $unlink);
        }
    }

    if ($error) {
        $self->debug('exit code: %d', $error);
        $self->_unlink($unlink);
        return $error;
    } elsif ($test) {
        return $command;
    } else {
        $self->debug('command: %s', $self->dump_command($command));

        try {
            # XXX hack to remove the "<error> in /path/to/App/Wax.pm line <line>"
            # noise. we just want the error message
            no warnings qw(redefine);
            local *IPC::System::Simple::croak = sub { die @_, $/ };
            systemx(EXIT_ANY, @$command);
        } catch {
            chomp;
            $self->log(ERROR => $_);
        };

        $self->debug('exit code: %d', $EXITVAL);
        $self->_unlink($unlink);

        return $EXITVAL;
    }
}

__PACKAGE__->meta->make_immutable();

1;
