package Mock::Syslog;

use strict;

$INC{'Sys/Syslog.pm'} = $INC{'Mock/Syslog.pm'};

our $IDENT    = undef;
our $LOGOPT   = undef;
our $FACILITY = undef;

our @WARN = ();
our @DIE  = ();

package Sys::Syslog;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( openlog closelog syslog );

sub openlog {
    $IDENT    = $_[0];
    $LOGOPT   = $_[1];
    $FACILITY = $_[2];
}

sub closelog {
    # Do nothing.
}

sub syslog {
    my ( $level, $message ) = @_;

    if ( $level eq 'warning' ) {
        push @WARN, $message;
    }
    elsif ( $level eq 'err' ) {
        push @DIE, $message;
    }
}

1;
