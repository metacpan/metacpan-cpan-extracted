package Acrux::Log;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

Acrux::Log - Acrux logger

=head1 SYNOPSIS

    use Acrux::Log;

    # Using syslog
    my $log = Acrux::Log->new();
       $log->error("My test error message to syslog")

    # Using file
    my $log = Acrux::Log->new(file => '/tmp/test.log');
       $log->error("My test error message to /tmp/test.log")

    # Using STDOUT (handle)
    my $log = Acrux::Log->new(
            handle => IO::Handle->new_from_fd(fileno(STDOUT), "w")
        );
    $log->error("My test error message to STDOUT")

    # Customize minimum log level
    my $log = Acrux::Log->new(level => 'warn');

    # Log messages
    $log->trace('Doing stuff');
    $log->debug('Not sure what is happening here');
    $log->info('FYI: it happened again');
    $log->notice('Normal, but significant, condition...');
    $log->warn('This might be a problem');
    $log->error('Garden variety error');
    $log->fatal('Boom');
    $log->crit('Its over...');
    $log->alert('Action must be taken immediately');
    $log->emerg('System is unusable');

=head1 DESCRIPTION

Acrux::Log is a simple logger for Acrux logging

=head2 new

    my $log = Acrux::Log->new(
        logopt      => 'ndelay,pid',
        facility    => 'user',
        level       => 'debug',
        ident       => 'test.pl',
        autoclean   => 1,
        logopt      => 'ndelay,pid',
    );

With default attributes

    use Mojo::Log;
    my $log = Acrux::Log->new( logger => Mojo::Log->new );
    $log->error("Test error message");

This is example with external loggers

=head1 ATTRIBUTES

This class implements the following attributes

=head2 autoclean

    autoclean => 1

This attribute enables cleaning (closing handler or syslog) on DESTROY

=head2 color

    color => 1

Colorize log messages with the available levels using L<Term::ANSIColor>, defaults to C<0>

=head2 facility

    facility => 'user'

This attribute sets facility for logging

Available standard facilities: C<auth>, C<authpriv>, C<cron>, C<daemon>, C<ftp>,
C<kern>, C<local0>, C<local1>, C<local2>, C<local3>, C<local4>, C<local5>, C<local6>,
C<local7>, C<lpr>, C<mail>, C<news>, C<syslog>, C<user> and C<uucp>

Default: C<user> (Sys::Syslog::LOG_USER)

See also L<Sys::Syslog/Facilities>

=head2 file

    file => '/var/log/myapp.log'

Log file path used by "handle"

=head2 format

    format => sub {...}

A callback function for formatting log messages

    format => sub {
        my ($time, $level, @lines) = @_;
        return "[$time] [$level] " . join (' ', @lines) . "\n";
    }

This callback routine must return formatted string for the log line

=head2 handle

    handle => IO::Handle->new_from_fd(fileno(STDOUT), "w")

Log filehandle, defaults to opening "file" or uses syslog if file not specified

=head2 ident

    ident => 'myapp'

The B<ident> is prepended to every B<syslog> message

Default: script name C<basename($0)>

=head2 level

    level => 'debug'

There are six predefined log levels: C<fatal>, C<error>, C<warn>, C<info>, C<debug>, and C<trace> (in descending priority).
The syslog supports followed additional log levels: C<emerg>, C<alert>, C<crit'> and C<notice> (in descending priority).
But we recommend not using them to maintain compatibility.
Your configured logging level has to at least match the priority of the logging message.

If your configured logging level is C<warn>, then messages logged with info(), debug(), and trace()
will be suppressed; fatal(), error() and warn() will make their way through, because their
priority is higher or equal than the configured setting.

Default: C<debug>

See also L<Sys::Syslog/Levels>

=head2 logger

    logger => Mojo::Log->new()

This attribute perfoms to set predefined logger, eg. Mojo::Log

Default: C<undef>

=head2 logopt

    logopt => 'ndelay,pid'

This attribute contains zero or more of the options detailed in L<Sys::Syslog/openlog>

Default: C<'ndelay,pid'>

=head2 prefix

    prefix => '>>>'

The B<prefix> is prepended to every C<handled> log message

Default: null

=head2 short

    short => 1

Generate short log messages without a timestamp but with log level prefix, defaults to C<0>

=head1 METHODS

This class implements the following methods

=head2 alert

    $log->alert('Action must be taken immediately');
    $log->alert('Real', 'problem');

Log C<alert> message

=head2 crit

    $log->crit('Its over...');
    $log->crit('Bye', 'bye');

Log C<crit> message (See L</fatal> method)

=head2 debug

    $log->debug('You screwed up, but that is ok');
    $log->debug('All', 'cool');

Log C<debug> message

=head2 emerg

    $log->emerg('System is unusable');
    $log->emerg('To', 'die');

Log C<emerg> message

=head2 error

    $log->error('You really screwed up this time');
    $log->error('Wow', 'seriously');

Log C<error> message

=head2 fatal

    $log->fatal('Its over...');
    $log->fatal('Bye', 'bye');

Log C<fatal> message

=head2 info

    $log->info('You are bad, but you prolly know already');
    $log->info('Ok', 'then');

Log C<info> message

=head2 level

    my $level = $log->level;
    $log      = $log->level('debug');

Active log level, defaults to debug.
Available log levels are C<trace>, C<debug>, C<info>, C<notice>, C<warn>, C<error>,
C<fatal> (C<crit>), C<alert> and C<emerg>, in that order

=head2 logger

    my $logger = $log->logger;

This method returns the logger object or undef if not exists

=head2 notice

    $log->notice('Normal, but significant, condition...');
    $log->notice('Ok', 'then');

Log C<notice> message

=head2 provider

    print $log->provider;

Returns provider name (C<external>, C<handle>, C<file> or C<syslog>)

=head2 trace

    $log->trace('Whatever');
    $log->trace('Who', 'cares');

Log C<trace> message

=head2 warn

    $log->warn('Dont do that Dave...');
    $log->warn('No', 'really');

Log C<warn> message

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Sys::Syslog>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use Carp qw/carp croak/;
use Scalar::Util qw/blessed/;
use Sys::Syslog qw//;
use File::Basename qw/basename/;
use IO::File qw//;
use Fcntl qw/:flock/;
use Encode qw/find_encoding/;
use Time::HiRes qw/time/;
use Acrux::Util qw/color/;

use constant {
    LOGOPTS         => 'ndelay,pid', # For Sys::Syslog
    SEPARATOR       => ' ',
    LOGFORMAT       => '%s',
};
my %LOGLEVELS = (
    'trace'     => Sys::Syslog::LOG_DEBUG,    # 7 debug-level message
    'debug'     => Sys::Syslog::LOG_DEBUG,    # 7 debug-level message
    'info'      => Sys::Syslog::LOG_INFO,     # 6 informational message
    'notice'    => Sys::Syslog::LOG_NOTICE,   # 5 normal, but significant, condition
    'warn'      => Sys::Syslog::LOG_WARNING,  # 4 warning conditions
    'error'     => Sys::Syslog::LOG_ERR,      # 3 error conditions
    'fatal'     => Sys::Syslog::LOG_CRIT,     # 2 critical conditions
    'crit'      => Sys::Syslog::LOG_CRIT,     # 2 critical conditions
    'alert'     => Sys::Syslog::LOG_ALERT,    # 1 action must be taken immediately
    'emerg'     => Sys::Syslog::LOG_EMERG,    # 0 system is unusable
);
my %MAGIC = (
    'trace'     => 8,
    'debug'     => 7,
    'info'      => 6,
    'notice'    => 5,
    'warn'      => 4,
    'error'     => 3,
    'fatal'     => 2, 'crit' => 2,
    'alert'     => 1,
    'emerg'     => 0,
);
my %COLORS = (
    'trace'     => 'white',
    'debug'     => 'bright_white',
    'info'      => 'cyan',
    'notice'    => 'green',
    'warn'      => 'yellow',
    'error'     => 'red',
    'fatal'     => 'bright_red', 'crit' => 'bright_magenta',
    'alert'     => 'white on_red',
    'emerg'     => 'bright_white on_red',
);
my %SHORT = ( # Log::Log4perl::Level notation
    0 => 'fatal', 1 => 'fatal', 2 => 'fatal',
    3 => 'error',
    4 => 'warn',
    5 => 'info', 6 => 'info',
    7 => 'debug',
    8 => 'trace',
);

my $ENCODING = find_encoding('UTF-8') or croak qq/Encoding "UTF-8" not found/;

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
    $args->{facility}   ||= Sys::Syslog::LOG_USER;
    $args->{ident}      ||= basename($0);
    $args->{logopt}     ||= LOGOPTS;
    $args->{logger}     ||= undef;
    $args->{level}      ||= 'debug';
    $args->{file}       ||= undef;
    $args->{handle}     ||= undef;
    $args->{provider}   = 'unknown';
    $args->{autoclean}  ||= 0;
    $args->{prefix}     ||= '';
    $args->{format}     ||= undef;
    $args->{color}      ||= 0;

    # Check level
    $args->{level} = lc($args->{level});
    unless (exists $MAGIC{$args->{level}}) {
        carp "Incorrect log level specified. Well be used debug log level by default";
        $args->{level} = 'debug';
    }

    # Instance
    my $self = bless {%$args}, $class;

    # Set formatter
    $self->{format} ||= $self->{short} ? \&_short : $self->{color} ? \&_color : \&_default;

    # Open sys log socket
    if ($args->{logger}) {
        croak "Blessed reference expected in logger attribute" unless blessed($args->{logger});
        $self->{provider} = "external";
    } elsif ($args->{handle}) {
        $self->{provider} = "handle";
        return $self;
    } elsif ($args->{file}) {
        my $file = $args->{file};
        $self->{handle} = IO::File->new($file, ">>");
        croak qq/Can't open log file "$file": $!/ unless defined $self->{handle};
        $self->{provider} = "file";
    } else {
        Sys::Syslog::openlog($args->{ident}, $args->{logopt}, $args->{facility});
        $self->{provider} = "syslog";
    }

    return $self;
}
sub level {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{level} = shift;
        return $self;
    }
    return $self->{level};
}
sub logger { shift->{logger} }
sub handle { shift->{handle} }
sub provider { shift->{provider} }

sub trace { shift->_log('trace', @_) }
sub debug { shift->_log('debug', @_) }
sub info { shift->_log('info', @_) }
sub notice { shift->_log('notice', @_) }
sub warn { shift->_log('warn', @_) }
sub error { shift->_log('error', @_) }
sub fatal { shift->_log('fatal', @_) }
sub crit { shift->_log('crit', @_) }
sub alert { shift->_log('alert', @_) }
sub emerg { shift->_log('emerg', @_) }

sub _log {
    my ($self, $level, @msg) = @_;
    my $req = $MAGIC{$self->level};
    my $mag = $MAGIC{$level} // 7;
    return 0 unless $mag <= $req;

    # External logger
    if (my $logger = $self->logger) {
        my $name = $SHORT{$mag};
        if (my $code = $logger->can($name)) {
            return $logger->$code(@msg);
        } else {
            carp(sprintf("Can't found '%s' method in '%s' package", $name, ref($logger)));
        }
        return 0;
    }

    # Handle
    if (my $handle = $self->handle) {
        # Set message
        my $pfx = (defined($self->{prefix}) && length($self->{prefix})) ? $self->{prefix} : '';
        my $_msg = $ENCODING->encode($pfx . $self->{format}->(time, $level, @msg), 0);

        # Flush
        if ($self->{provider} eq "file") { # Flush to file
            flock $handle, LOCK_EX;
            $handle->print($_msg) or croak "Can't write to log file: $!";
            flock $handle, LOCK_UN;
        } elsif ($self->{provider} eq "handle") { # Flush to handle
            print $handle $_msg;
        } else {
            return 0;
        }
        return 1;
    }

    # Syslog
    return 0 if $self->provider ne "syslog";
    my $lvl = $LOGLEVELS{$level} // Sys::Syslog::LOG_DEBUG;
    Sys::Syslog::syslog($lvl, LOGFORMAT, join(SEPARATOR, @msg));
}

sub _default {
    my ($tm, $l, @msg) = @_;
    my ($s, $m, $h, $day, $month, $year) = localtime $tm;
    my $time = sprintf '%04d-%02d-%02d %02d:%02d:%08.5f', $year + 1900, $month + 1, $day, $h, $m,
       "$s." . ((split /\./, $tm)[1] // 0);
    return "[$time] [$$] [$l] " . join(SEPARATOR, @msg) . "\n";
}
sub _short {
    my ($tm, $l, @msg) = @_;
    my $short = substr($l, 0, 1);
    return "[$$] [$short] " . join(SEPARATOR, @msg) . "\n";
}
sub _color {
    my $msg = _default(shift, my $level = shift, @_);
    return $msg unless $COLORS{$level};
    chomp $msg;
    return color($COLORS{$level}, $msg) . "\n";
}

DESTROY {
    my $self = shift;
    if ($self->{autoclean}) {
        undef $self->{handle} if $self->{file};
        Sys::Syslog::closelog() if $self->{provider} eq "syslog";
    }
}

1;

__END__
