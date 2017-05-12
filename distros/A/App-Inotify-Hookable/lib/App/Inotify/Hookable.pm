#!/usr/bin/env perl
package App::Inotify::Hookable;
BEGIN {
  $App::Inotify::Hookable::AUTHORITY = 'cpan:AVAR';
}
{
  $App::Inotify::Hookable::VERSION = '0.09';
}
use Moose;
use MooseX::Types::Moose ':all';
use Linux::Inotify2;
use POSIX ':errno_h';
use Time::HiRes qw(gettimeofday tv_interval ualarm);
use Try::Tiny;
use Data::BitMask;
use Data::Dumper;
use Class::Inspector;
use List::MoreUtils qw(uniq);

with 'MooseX::Getopt::Dashes';

has debug => (
    metaclass      => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => Bool,
    default       => 0,
    cmd_aliases   => 'd',
    documentation => "Should we print debug info about what we're doing?",
);

has quiet => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => Bool,
    default       => 0,
    cmd_aliases   => 'q',
    documentation => q{Don't log noisy information},
);

has watch_directories => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => ArrayRef[Str],
    default       => sub { [] },
    cmd_aliases   => 'w',
    auto_deref    => 1,
    documentation => "What directories should we watch?",
);

has watch_files => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => ArrayRef[Str],
    default       => sub { [] },
    cmd_aliases   => 'f',
    auto_deref    => 1,
    documentation => "What files should we watch?",
);

has recursive => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => Bool,
    default       => 1,
    cmd_aliases   => 'r',
    documentation => "Should we recursively watch the directories we're watching? On by default.",
);

has on_modify_command => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => ArrayRef[Str],
    default       => sub { [] },
    auto_deref    => 1,
    cmd_aliases   => 'c',
    documentation => "What commands should we run when something happens?",
);

has on_modify_path_command => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => HashRef[Str],
    default       => sub { +{} },
    cmd_aliases   => 'C',
    documentation => "What commands should we run for a given path when something happens? The key is a regex and the value is a command.",
);

has buffer_time => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => Int,
    default       => 100,
    cmd_aliases   => 't',
    documentation => "How many milliseconds should we buffer inotify for? (default 100)",
);

has ignore_paths => (
    metaclass     => 'MooseX::Getopt::Meta::Attribute',
    is            => 'ro',
    isa           => ArrayRef[Str],
    default       => sub { [ '\..*sw.\z', '\.\#[^/]+\z' ] },
    cmd_aliases   => 'i',
    auto_deref    => 1,
    documentation => q|Regexes for which paths we should ignore (default '\..*sw.\z' and '\.\#[^/]+\z' for vim and emacs swap files.)|
);

has _watches => (
    is            => 'ro',
    isa           => HashRef,
    default       => sub { +{} },
    documentation => "What stuff are we watching?",
);

has _notifier => (
    is         => 'rw',
    isa        => 'Linux::Inotify2',
    lazy_build => 1,
);

has _bitmask => (
    is         => 'rw',
    isa        => 'Data::BitMask',
    lazy_build => 1,
);

has _previously_watched_directories => (
    is         => 'rw',
    isa        => ArrayRef[Str],
);

sub _build__notifier { Linux::Inotify2->new }

sub log {
    my ($self, $message) = @_;
    return if $self->quiet;
    print STDERR scalar(localtime()), " : ", $message, "\n";
};

my $dumper_squashed = sub {
    my $val = shift;

    my $dd = Data::Dumper->new([]);
    $dd->Terse(1)->Indent(1)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1)->Indent(0);
    return $dd->Values([ $val ])->Dump;
};

sub run {
    my ($self) = @_;

    # Catch sigint so DEMOLISH can run
    local $SIG{INT} = sub { exit 1 };

    my @watch_dirs  = $self->watch_directories;
    my @watch_files = $self->watch_files;
    die "You need to give me something to watch" unless @watch_dirs || @watch_files;
    $self->log(
        "Starting up, " .
        (@watch_dirs ?
            ($self->recursive ? "recursively" : "non-recursively") .
            " " .
            "watching directories <@watch_dirs>" .
            (@watch_files ? " and " : "")
        : "") .
        (@watch_files ?
            "watching files <@watch_files>"
        : "")
    );

    my $notifier = $self->_notifier;
    $self->setup_watch;
    my $buffer_time = $self->buffer_time;
    while (my @events = $notifier->read()) {
        # At this point we have an event, but Linux sends these *really
        # fast* so if someone does "touch foo bar zar" we might only get
        # an event for the first file, then later the rest.
        #
        # So buffer up events for $sleep_ms and see if we stop getting
        # them, then restart.
        my $sleep_ms = $buffer_time;
        my $sleep_us = $sleep_ms * 10**3;

        my %modified_paths;

        my $log_modified_paths = sub {
            my $events = shift;
            for my $event (@$events) {
                my $fullname = $event->fullname;
                $fullname =~ s[//][/]g; # We have double slashes for some reason

                my $ignore_path = 0;

                IGNORE_PATHS: foreach my $re ($self->ignore_paths) {
                    if ($fullname =~ m{(?:/|^)$re}) {
                        $ignore_path = 1;
                        last IGNORE_PATHS;
                    }
                }

                $modified_paths{$fullname} = undef if not $ignore_path;
            }
            return;
        };

      WAIT: while (1) {
            for my $event (@events) {
                $self->log("EVENT: " . $dumper_squashed->({
                    cookie => $event->cookie,
                    fullname => $event->fullname,
                    mask => $self->_bitmask->explain_mask($event->mask),
                })) if $self->debug;
            }
            $log_modified_paths->(\@events);
            @events = ();
            try {
                local $SIG{ALRM} = sub {
                    die "Timeout waiting for ->read";
                };
                ualarm($sleep_us);
                @events = $notifier->read;
                ualarm(0);
            } catch {
                $self->log("We have no more events with a timeout of $sleep_ms ms") if $self->debug;
            };

            if (@events) {
                $self->log("We have events, waiting another $sleep_ms ms and checking again") if $self->debug;

                $log_modified_paths->(\@events);
            } else {
                # No more events
                last WAIT;
            }
        }

        if (keys %modified_paths) {
            $self->log("Had changes in your paths");

            if (keys %{ $self->on_modify_path_command }) {
                $self->log("Checking for path-specific hooks") if $self->debug;
                my %hooks_to_run;
                my $on_modify_path_command = $self->on_modify_path_command;
                for my $path (keys %modified_paths) {
                    for my $path_hook (keys %$on_modify_path_command) {
                        $hooks_to_run{$path_hook} = 1
                            if $path =~ /$path_hook/;
                    }
                }
                if (keys %hooks_to_run) {
                    $self->log("Running path-specific hooks");
                    my $t0 = [gettimeofday];
                    for my $hook_to_run (keys %hooks_to_run) {
                        my $command = $on_modify_path_command->{$hook_to_run};
                        $self->log("Running path hook <$hook_to_run>: <$command>");
                        system $command;
                    }
                    my $elapsed = tv_interval ( $t0 );
                    $self->log(sprintf "FINISHED running path-specific hooks. Took %.2fs", $elapsed);
                }
            }

            if (my @commands = $self->on_modify_command) {
                $self->log("Running global hooks");
                my $t0 = [gettimeofday];
                for my $command (@commands) {
                    $self->log("Running <$command>");
                    system $command;
                }
                my $elapsed = tv_interval ( $t0 );
                $self->log(sprintf "FINISHED on-modify command. Took %.2fs", $elapsed);
            }
        }

        # Re-setup the watching if needed, we may have new directories.
        $self->setup_watch;
    }

    return 1;
}

sub all_paths_to_watch {
    my ($self) = @_;
    my @watch_directories = $self->watch_directories;
    my @watch_files       = $self->watch_files;
    my @directories;
    if (@watch_directories) {
        if ($self->recursive) {
            chomp(@directories = qx[find @watch_directories -type d]);
        } else {
            @directories = @watch_directories;
        }
    }

    return (
        @watch_files,
        grep {
            # Don't notify on "git status" (creates a lock) and other similar
            # operations.
            not m[
                    (?:
                       # The .git directory
                       /\.git\z
                      |
                       # Something in the .git directory
                       /\.git/
                     )
            ]x
        } @directories
    );
}

sub setup_watch {
    my ($self) = @_;

    my $t0 = [gettimeofday];

    my $notifier = $self->_notifier;
    my $watches  = $self->_watches;
    my $debug    = $self->debug;

    my $watches_added    = 0;
    my $watches_removed  = 0;
    my $watches_replaced = 0;

    my $previously_watched_directories = $self->_previously_watched_directories;
    my @previously_watched_directories = $previously_watched_directories ? @$previously_watched_directories : ();
    my @current_paths_to_watch         = $self->all_paths_to_watch;

    my @all_paths_to_watch = uniq(
        # The stuff we're watching now
        @current_paths_to_watch,
        # what we were watching earlier, so we know to remove watches
        # for that if they've been removed.
        @previously_watched_directories,
    );

    # Add or re-setup watches
    WATCH: for my $path (@all_paths_to_watch) {
        my $have_watch   = exists $watches->{$path};
        my $type         = -d $path ? 'directory' : 'file';
        my $path_exists  = -e $path;
        my $inode_number; $inode_number = (stat $path)[1] if $path_exists;

        # path has gone away
        if ($have_watch && (not $path_exists)) {
            $watches->{$path}{watch}->cancel;
            my $type = $watches->{$path}{type}; # In this case we care what it *was*
            delete $watches->{$path};
            $self->log("$type '$path' has gone away, removing watch") if $debug;
            $watches_removed++;
            next WATCH;
        }

        if ($have_watch) {
            if ($watches->{$path}{inode} eq $inode_number) {
                # We have this watch already, and it hasn't changed the
                # inode number, so no need to go and add it again.
                next WATCH;
            } else {
                # object got replaced, remove the watch (we'll add a
                # new watch for the new object).
                $watches->{$path}{watch}->cancel;
                my $type = $watches->{$path}{type}; # In this case we care what it *was*
                $watches_replaced++;
                $self->log("$type '$path' was replaced, replacing watch") if $debug;
            }
        }

        my $watch = $notifier->watch(
            $path,
            (
                # Is this is a directory?
                ($type eq 'directory' ?
                    # Modifications I care about
                    IN_MODIFY
                    |
                    IN_ATTRIB
                    |
                    IN_CREATE
                    |
                    IN_DELETE
                    |
                    IN_DELETE_SELF
                    |
                    IN_MOVED_FROM
                    |
                    IN_MOVED_TO
                    |
                    IN_MOVE_SELF
                :
                    # modifications for files
                    IN_MODIFY
                    |
                    IN_ATTRIB
                    |
                    IN_CLOSE_WRITE
                    |
                    IN_DELETE_SELF
                    |
                    IN_MOVE_SELF
                )
            )
        );

        if (not $watch) {
            my $error = $!;

            if ($error == ENOSPC) {
                die <<"DIE"
We probably exceeded the maximum number of user watches since we had a
"No space left on device" error. Try something like this command and
try again:

    echo 65536 | sudo tee /proc/sys/fs/inotify/max_user_watches

The original error was:

$error
DIE
            } elsif ($error == ENOENT) {
                # Don't hard die on the common race condition where a
                # file/directory we found with our "find" call has
                # since gone away (e.g. due to a different "git
                # checkout" removing it).
                $self->log("Couldn't watch $type '$path': $error");
                next WATCH;
            } else {
                die $error;
            }
        }

        $watches_added++;
        $self->log("Now watching $type: $path") if !$have_watch && $debug;

        $watches->{$path}{watch} = $watch;
        $watches->{$path}{type}  = $type;
        $watches->{$path}{inode} = $inode_number;
    }

    # Set this to the stuff we were just going over so we'll know to
    # delete stuff from there in the future.
    $self->_previously_watched_directories(\@current_paths_to_watch);

    my $elapsed = tv_interval ( $t0 );
    my $total_num_watches = scalar keys %{ $notifier->{w} };
    $self->log(sprintf "FINISHED setting up watches. Took %.2fs with $watches_added watches added, $watches_removed removed, $watches_replaced replaced. Have $total_num_watches total watches", $elapsed);
    return;
}

sub _build__bitmask {
    my %masks;
    @masks{grep /^IN_/, @{ Class::Inspector->methods("Linux::Inotify2") }} = ();
    foreach my $const (keys %masks) {
        $masks{$const} = Linux::Inotify2->$const;
    }

    return Data::BitMask->new(%masks);
}

sub DEMOLISH {
    my ($self) = @_;
    my $notifier = $self->_notifier;

    $self->log("Demolishing $notifier");
}

1;

__END__

=encoding utf8

=head1 NAME

App::Inotify::Hookable - blocking command-line interface to inotify

=head1 SYNOPSIS

Watch a directory, tell us when things change in it:

    inotify-hookable --watch-directories /tmp/watch-this

Watch a git tree, some configs, and a repository of static assets,
restart the webserver or compress those assets if anything changes:

    inotify-hookable \
        --watch-directories /etc/uwsgi \
        --watch-directories /git_tree/central \
        --watch-directories /etc/app-config \
        --watch-directories /git_tree/static_assets \
        --on-modify-path-command "^(/etc/uwsgi|/git_tree/central|/etc/app-config)=sudo /etc/init.d/uwsgi restart" \
        --on-modify-path-command "^/git_tree/static_assets=(cd /git_tree/static_assets && compress_static_assets)"

Or watch specific files:

    inotify-hookable \
        --watch-files /var/www/cgi-bin/mod_perl_handler \
        --on-modify-command "apachectl restart"

=head1 DESCRIPTION

This simple command-line program is my replacement for the
functionality offered by L<Plack>'s L<Filesys::Notify::Simple>. I
found that on very large git trees Plack would spend an inordinate
amount watching the filesystem for changes.

This program uses L<Linux::Inotify2>, so the kernel will notify it
B<instantly> when something changes (actually it's so fast that we
have to work around how fast it sends us events).

The result is that you can run this e.g. in a screen session and have
it watch your development environment, and your webserver will have
begun restarting before your finger leaves the I<save> button.

vim and emacs temporary files are ignored by default (see C<--ignore-paths>.)
so you can edit your files without your server restarting unnecessarily.

Currently the command-line interface for this is the only one that
really makes sense, this module is entirely blocking (although it
could probably run in another process via L<POE> or
something). Patches welcome.

=head1 OPTIONS

Note that boolean options can be negated with C<--no-OPTION>,
e.g. C<--no-r> or C<--no-recursive> to turn off the C<--recursive>
option which is on by default.

=head2 C<-w> or C<--watch-directories>

Specify this to watch a directory, you can give this however many
times you like to watch lots of directories.

=head2 C<-f> or C<--watch-files>

Watch a file, specify multiple times for multiple files.
You can watch files and directories in the same command.

=head2 C<-r> or C<--recursive>

If you supply this any directory you give will be recursively
watched. This is on by default.

=head2 C<-c> or C<--on-modify-command>

A command that will be run when something is modified.

=head2 C<-C> or C<--on-modify-path-command>

A key-value pair where the key is a regex that'll be matched against a
modified path, and the value is a command that'll be run. See the
L</SYNOPSIS> for an example.

Useful for e.g. restarting a webserver if you modify directory F<A>
but compressing some static assets if you modify directory F<B>.

=head2 C<-t> or C<--buffer-time>

Linux will send you inotify events B<really> fast, so fast that if you
run something like:

    touch foo bar

You might get an event for F<foo> in one batch, followed by an event
for F<bar> later on.

To deal with this we enter a loop when we start getting events and sleep for a
default of 100 microseconds, as long as we keep getting events we keep sleeping
for 100 microseconds, but as soon as we haven't received anything new we fire
off our event handlers.

=head2 C<-i> or C<--ignore-paths>

Regexes for files/directories to ignore events for. By default this is set to
regexes for vim and emacs temporary files, C<qr{\..*sw.\z}> and
C<qr{\.\#[^/]+\z}> respectively.

The regexes match after any C</> in the path or the beginning of the string.

=head2 C<-d> or C<--debug>

Spew out some verbose debug output while running.

=head1 ACKNOWLEDGMENT

This module was originally developed at and for Booking.com. With
approval from Booking.com, this module was generalized and put on
CPAN, for which the authors would like to express their gratitude.

=head1 AUTHOR

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=cut
