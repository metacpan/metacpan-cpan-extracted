package CTK::Log;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Log - CTK Logging

=head1 VERSION

Version 2.64

=head1 SYNOPSIS

    use CTK::Log;
    use CTK::Log qw/:constants/;

    my $logger = CTK::Logger->new (
            file        => "logs/foo.log",
            level       => CTK::Log::LOG_INFO,
            ident       => "ident string",
        );

    $logger->log( CTK::Log::LOG_INFO, " ... Blah-Blah-Blah ... " );

    $logger->log_except( "..." );  # 9 exception, aborts program!
    $logger->log_fatal( "..." );   # 8 system unusable, aborts program!
    $logger->log_emerg( "..." );   # 7 system is unusable
    $logger->log_alert( "..." );   # 6 failure in primary system
    $logger->log_crit( "..." );    # 5 failure in backup system
    $logger->log_error( "..." );   # 4 non-urgent program errors, a bug
    $logger->log_warning( "..." ); # 3 possible problem, not necessarily error
    $logger->log_notice( "..." );  # 2 unusual conditions
    $logger->log_info( "..." );    # 1 normal messages, no action required
    $logger->log_debug( "..." );   # 0 debugging messages (default)

=head1 DESCRIPTION

Logger class

Log level overview:

   LVL SLL NAME      ALIAS    NOTE
    0   7  debug              debugging messages, copious tracing output
    1   6  info               normal messages, no action required
    2   5  notice    note     unusual conditions
    3   4  warning   warn     possible problem, not necessarily error
    4   3  error     err      non-urgent program errors, a bug
    5   2  critical  crit     failure in backup system
    6   1  alert              failure in primary system
    7   0  emergency emerg    system unusable
    8   0  fatal              system unusable, aborts program!
    9   0  exception except   exception, aborts program!

* SLL -- SysLog Level

=head1 METHODS

=head2 new

    my $logger = CTK::Log->new(
            file        => "logs/foo.log",
            level       => "info", # or CTK::Log::LOG_INFO
            ident       => "ident string",
        );

Returns logger object for logging to file

    my $logger = CTK::Log->new(
            level       => "info", # or CTK::Log::LOG_INFO
            ident       => "ident string",
        );

Returns logger object for logging to syslog

=over 8

=item B<facility>

The part of the system to report about, for example C<Sys::Syslog::LOG_USER>. See L<Sys::Syslog>

Default: C<Sys::Syslog::LOG_USER>

=item B<file>

Specifies log file. If not specify, then will be used syslog

Default: undef

=item B<ident>

Specifies ident string for each log-record

  ident = "test"

    [Mon Apr 29 20:02:04 2019] [info] [7936] [test] Blah Blah Blah

  ident = undef

    [Mon Apr 29 20:02:04 2019] [info] [7936] Blah Blah Blah

Default: undef

=item B<level>

This directive specifies the minimum possible priority level. You can use:

constants:

    LOG_DEBUG
    LOG_INFO
    LOG_NOTICE or LOG_NOTE
    LOG_WARNING or LOG_WARN
    LOG_ERR or LOG_ERROR
    LOG_CRIT
    LOG_ALERT
    LOG_EMERG or LOG_EMERGENCY
    LOG_FATAL
    LOG_EXCEPT or LOG_EXCEPTION

...or strings:

    'debug'
    'info'
    'notice' or 'note'
    'warning' or 'warn'
    'error' or 'err'
    'crit'
    'alert'
    'emerg' or 'emergency'
    'fatal'
    'except' or 'exception'

Default: C<LOG_DEBUG>

=item B<pure>

Specifies flag for suppressing prefixes log-data

  ident = "test"
  pure = 0

    [Mon Apr 29 19:12:55 2019] [crit] [7480] [test] Blah-Blah-Blah

  ident = "test"
  pure = 1

    [test] Blah-Blah-Blah

  ident = undef
  pure = 1

    Blah-Blah-Blah

Default: 0

=item B<separator>

Separator of log-record elements

  separator = " "

    [Mon Apr 29 20:02:04 2019] [info] [7936] [test] Blah Blah Blah

  separator = ","

    [Mon Apr 29 20:02:04 2019],[info],[7936],[test],Blah Blah Blah

Default: C<" ">

=item B<socketopts>

Socket optrions for L<Sys::Syslog>

Allowed formats, examples:

    socketopts => "unix"
    socketopts => ["unix"]
    socketopts => { type => "tcp", port => 2486 }

Default: C<native>

=item B<syslogopts>

Options of L<Sys::Syslog>

Default: C<ndelay,pid>

=item B<usesyslog>

Sets to 1 for send data to syslog forced

Default: 0

=item B<utf8>

Sets flag utf8 for logging data. The flag is enabled by default

Default: 1

=back

=head2 error

    my $error = $logger->error;

Returns error string if occurred any errors while creating the object

=head2 status

    print $logger->error unless $logger->status;

Returns boolean status of object creating

=head1 LOG METHODS

=head2 log

    $logger->log( <LEVEL>, <FORMAT>, <VALUE>, ... );
    $logger->log( LOG_INFO, "Message: Blah-Blah-Blah" );
    $logger->log( LOG_INFO, "Message: %s", "Blah-Blah-Blah" );
    $logger->log( "info", "Message: Blah-Blah-Blah" );

Logging with info level (1). Same as log_info( "Message: %s", "Blah-Blah-Blah" )

=head2 log_debug

    $logger->log_debug( <FORMAT>, <VALUE>, ... );
    $logger->log_debug( "the function returned 3" );
    $logger->log_debug( "going to call function abc" );

Level 0: debug-level messages (default)

=head2 log_info

    $logger->log_info( <FORMAT>, <VALUE>, ... );
    $logger->log_info( "File soandso successfully deleted." );

Level 1: informational

=head2 log_notice, log_note

    $logger->log_notice( <FORMAT>, <VALUE>, ... );
    $logger->log_notice( "Attempted to create config, but config already exists." );

Level 2: normal but significant condition

=head2 log_warning, log_warn

    $logger->log_warning( <FORMAT>, <VALUE>, ... );
    $logger->log_warning( "Couldn't delete the file." );

Level 3: warning conditions

=head2 log_error, log_err

    $logger->log_error( <FORMAT>, <VALUE>, ... );
    $logger->log_error( "Division by zero attempted." );

Level 4: error conditions

=head2 log_crit, log_critical

    $logger->log_crit( <FORMAT>, <VALUE>, ... );
    $logger->log_crit( "The battery is too hot!" );

Level 5: critical conditions

=head2 log_alert

    $logger->log_alert( <FORMAT>, <VALUE>, ... );
    $logger->log_alert( "The battery died!" );

Level 6: action must be taken immediately

=head2 log_emerg, log_emergency

    $logger->log_emerg( <FORMAT>, <VALUE>, ... );
    $logger->log_emerg( "No config found, cannot continue!" );

Level 7: system is unusable

=head2 log_fatal

    $logger->log_fatal( <FORMAT>, <VALUE>, ... );
    $logger->log_fatal( "No free memory" );

Level 8: fatal

=head2 log_except, log_exception

    $logger->log_except( <FORMAT>, <VALUE>, ... );
    $logger->log_except( "Segmentation violation" );

Level 9: exception

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Sys::Syslog>, L<IO::File>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Sys::Syslog>, L<IO::File>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut


use vars qw/$VERSION %EXPORT_TAGS @EXPORT_OK/;
$VERSION = '2.64';

use base qw/Exporter/;

use Carp;
use IO::File;
use Sys::Syslog ();
use Try::Tiny;
use Cwd qw/getcwd/;
use File::Spec ();

@EXPORT_OK = qw(
        LOG_DEBUG LOG_INFO LOG_NOTICE LOG_NOTE LOG_WARNING LOG_WARN LOG_ERR
        LOG_ERROR LOG_CRIT LOG_ALERT LOG_EMERG LOG_EMERGENCY LOG_FATAL
        LOG_EXCEPT LOG_EXCEPTION
    );

%EXPORT_TAGS = (
        constants => [@EXPORT_OK],
    );

use constant {
    LOGOPT          => 'ndelay,pid', # For Sys::Syslog
    MSWIN           => $^O =~ /mswin/i ? 1 : 0,
    SEPARATOR       => ' ',
    LOGLEVELSA      => [qw/debug info notice warning error crit alert emerg fatal except/],
    LOGLEVELS       => {
        'debug'     => 0,
        'info'      => 1,
        'notice'    => 2, 'note' => -2,
        'warning'   => 3, 'warn' => -3,
        'error'     => 4, 'err' => -4,
        'crit'      => 5, 'critical' => -5,
        'alert'     => 6,
        'emerg'     => 7, 'emergency' => -7,
        'fatal'     => 8,
        'except'    => 9, 'exception' => -9,
    },
    LOG_DEBUG       => 0,
    LOG_INFO        => 1,
    LOG_NOTICE      => 2, LOG_NOTE => 2,
    LOG_WARNING     => 3, LOG_WARN => 3,
    LOG_ERR         => 4, LOG_ERROR => 4,
    LOG_CRIT        => 5,
    LOG_ALERT       => 6,
    LOG_EMERG       => 7, LOG_EMERGENCY => 7,
    LOG_FATAL       => 8,
    LOG_EXCEPT      => 9, LOG_EXCEPTION => 9,
};

my %SYSLOG_LEVEL_MAP = (
  # My LEVEL        , SysLog LEVEL
    LOG_DEBUG       , LOG_EMERG,
    LOG_INFO        , LOG_ALERT,
    LOG_NOTICE      , LOG_CRIT,
    LOG_WARNING     , LOG_ERR,
    LOG_ERR         , LOG_WARNING,
    LOG_CRIT        , LOG_NOTICE,
    LOG_ALERT       , LOG_INFO,
    LOG_EMERG       , LOG_DEBUG,
    LOG_FATAL       , LOG_DEBUG,
    LOG_EXCEPT      , LOG_DEBUG,
);

sub new {
    my $class = shift;
    my %args = @_;
    my $level = _getLevel($args{level} // LOG_DEBUG);
    carp(sprintf("Incorrect level %s", $args{level})) unless defined $level;
    my $usesyslog = $args{usesyslog} || 0;
    my $syslogopts = $args{syslogopts} // LOGOPT;
    my $socketopts = $args{socketopts};
    my $facility = $args{facility} || Sys::Syslog::LOG_USER;
    my $file = $args{file};
    $usesyslog = 1 unless defined($file) && length($file);
    $file = File::Spec->catfile(getcwd(), $file)
        if $file && !File::Spec->file_name_is_absolute($file);

    # Create object
    my $self = bless {
        status      => 0,
        error       => "",
        usesyslog   => $usesyslog,
        file        => $file,
        level       => $level || LOG_DEBUG,
        ident       => $args{ident},
        syslogopts  => $syslogopts,
        socketopts  => $socketopts,
        facility    => $facility,
        separator   => $args{separator} // SEPARATOR,
        "utf8"      => $args{"utf8"} // 1,
        pure        => $args{pure} // 0,
        fh          => undef,
    }, $class;

    if ($usesyslog) {
        # never log to console - thats too slow, and
        # it corrupts the DBD database connection!
        if ($socketopts && ref($socketopts) eq 'ARRAY') {
            Sys::Syslog::setlogsock(@$socketopts);
        } elsif ($socketopts && (!ref($socketopts) || ref($socketopts) eq 'HASH')) {
            Sys::Syslog::setlogsock($socketopts);
        }
        #elsif (!MSWIN) {
        #    Sys::Syslog::setlogsock('unix');
        #}
        my $ident = $args{ident} || scalar(caller(0));
        try { # ignore errors
            Sys::Syslog::openlog($ident, $syslogopts, $facility);
        } catch {
            $self->{error} = $_ // '';
        };
        return $self if length($self->{error});
        $self->{status} = 1;
    } else {
        my $fh;
        try {
            $fh = IO::File->new($file, "a");
        } catch {
            $self->{error} = sprintf("Can't open log file %s: %s", $file, $_);
        };
        return $self if length($self->{error});
        unless (defined($fh)) {
            $self->{error} = sprintf("Can't open log file %s", $file);
            return $self;
        }
        $fh->binmode(":raw:utf8") if $self->{"utf8"};
        $fh->autoflush(1);
        $self->{fh} = $fh;
        $self->{status} = 1;
    }

    return $self;
}
sub error {
    my $self = shift;
    return $self->{error} // '';
}
sub status {
    my $self = shift;
    return $self->{status} ? 1 : 0;
}

sub log {
    my $self = shift;
    my $ll = shift // LOG_DEBUG;
    my @msg = @_;
    return 0 unless $self->status;
    my $ident = $self->{ident};
    my $level = _getLevel($ll);
    unless (defined($level)) {
        unshift(@msg, $ll);
        $level = LOG_DEBUG;
    }
    return 0 if $level < $self->{level};

    # Flush!
    if ($self->{usesyslog}) {
        return $self->_flush_to_syslog($level, @msg);
    } else {
        return $self->_flush_to_file($level, @msg);
    }

    return 0;
}
sub log_debug { shift->log(LOG_DEBUG, @_) };
sub log_info { shift->log(LOG_INFO, @_) };
sub log_notice { shift->log(LOG_NOTICE, @_) };
sub log_note { goto &log_notice };
sub log_warning { shift->log(LOG_WARNING, @_) };
sub log_warn { goto &log_warning };
sub log_error { shift->log(LOG_ERROR, @_) };
sub log_err { goto &log_error };
sub log_critical { shift->log(LOG_CRIT, @_) };
sub log_crit { goto &log_critical };
sub log_alert { shift->log(LOG_ALERT, @_) };
sub log_emerg { shift->log(LOG_EMERG, @_) };
sub log_emergency { goto &log_emerg };
sub log_fatal { shift->log(LOG_FATAL, @_) };
sub log_except { shift->log(LOG_EXCEPT, @_) };
sub log_exception { goto &log_except };

# Internal methods
sub _flush_to_file {
    my $self = shift;
    my $level = shift;
    my $format = shift // "";
    my @message = @_;
    return unless defined $level;

    # Adding
    my @buffer = ();
    unless ($self->{pure}) {
        push @buffer, sprintf("[%s]", scalar(localtime(time())));
        push @buffer, sprintf("[%s]", LOGLEVELSA()->[$level]);
        push @buffer, sprintf("[%s]", $$);
    }

    # Ident?
    my $ident = $self->{ident};
    push @buffer, sprintf("[%s]", $ident) if defined($ident) && length($ident);

    # Print
    my $fh = $self->{fh};
    if (defined($fh)) {
        try {
            $fh->print(join($self->{separator}, @buffer, "")) if @buffer;
            $fh->printf($format, @message);
            $fh->print("\n");
        } catch {
            $self->{error} = $_ // '';
        };
        return 0 if length($self->{error});
    } else {
        $self->{status} = 0;
        return 0;
    }

    return 1;
}
sub _flush_to_syslog {
    my $self = shift;
    my $level = shift;
    my $format = shift // "";
    my @message = @_;
    return unless defined $level;
    my $sl = _to_syslog($level);
    try { # ignore errors
        Sys::Syslog::syslog($sl, $format, @message);
    } catch {
        $self->{error} = $_ // '';
    };
    return 0 if length($self->{error});
    return 1;
}

# Internal functions
sub _getLevel { # Returns integer val: 0-9 -- ok, undef - incorrect :(
    my $ll = shift;
    return LOG_DEBUG unless defined $ll;
    my $loglevels = LOGLEVELS;
    my %levels  = %$loglevels; # name => val
    my %rlevels = reverse %$loglevels; # val => name
    if (($ll =~ /^[0-9]+$/) && exists($rlevels{$ll})) { # integer val
        return $ll if $ll >= LOG_DEBUG and $ll <= LOG_EXCEPT;
        return LOG_DEBUG;
    } elsif (($ll =~ /^[a-z]+$/i) && exists($levels{lc($ll)})) { # string
        return $levels{lc($ll)};
    }
    return undef;
}
sub _to_syslog { # for syslog
    my $level = shift // LOG_DEBUG;
    return $SYSLOG_LEVEL_MAP{$level} // $SYSLOG_LEVEL_MAP{(LOG_DEBUG)};
}

sub DESTROY {
    my $self = shift;
    return 1 unless $self && $self->status;
    if ($self->{usesyslog}) {
        Sys::Syslog::closelog();
    } else {
        $self->{fh}->close if defined($self->{fh}) && ref($self->{fh});
    }
    undef($self);
    return 1;
}

1;

__END__
