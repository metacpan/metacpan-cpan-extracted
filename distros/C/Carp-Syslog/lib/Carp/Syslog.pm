package Carp::Syslog;

use v5.10;
use strict;
use Sys::Syslog;

our $VERSION = '0.01';

sub import {
    my ( $class, $args ) = @_;

    # Defaults.
    my $ident    = $0;
    my $logopt   = '';
    my $facility = 'user';

    if ( defined $args ) {
        if ( ref $args eq 'HASH' ) {
            $ident    = $args->{'ident'}    if exists $args->{'ident'};
            $logopt   = $args->{'logopt'}   if exists $args->{'logopt'};
            $facility = $args->{'facility'} if exists $args->{'facility'};
        }
        else {
            $facility = $args;
        }
    }

    openlog( $ident, $logopt, $facility );

    $SIG{'__WARN__'} = sub {
        if ( ( caller 0 )[10]->{'Carp::Syslog'} ) { # hint on?
            ( my $message = $_[0] ) =~ s/\n$//;
            syslog( 'warning', $message );
        }

        warn $_[0];
    };

    $SIG{'__DIE__'} = sub {
        if ( ( caller 0 )[10]->{'Carp::Syslog'} ) { # hint on?
            my $message;

            if ( ref $_[0] ) {
                # We only want to to log references if they can stringify.
                require overload;
                if ( "$_[0]" ne overload::StrVal( $_[0] ) ) {
                    $message = "$_[0]";
                }
            }
            else {
                $message = $_[0];
            }

            if ( defined $message ) {
                $message =~ s/\n$//;
                syslog( 'err', $message );
            }
        }

        die $_[0];
    };

    # Also export Carp's defaults to calling namespace.
    require Carp;
    {
        no strict 'refs';
        my $caller = caller 0;

        *{ $caller . '::carp' }    = \&Carp::carp;
        *{ $caller . '::croak' }   = \&Carp::croak;
        *{ $caller . '::confess' } = \&Carp::confess;
    }

    $^H{'Carp::Syslog'} = 1;
}

sub unimport {
    $^H{'Carp::Syslog'} = 0;
}

END {
    closelog();
}

1;

=head1 NAME

Carp::Syslog - Send warn and die messages to syslog

=head1 SYNOPSIS

    # Defaults shown.
    use Carp::Syslog { ident => $0, logopt => '', facility => 'user' };

    warn '...';    # logs to user:warning

    die '...';     # logs to user:err

    # Shortcut for simplicity.
    use Carp::Syslog 'user';

    {
        no Carp::Syslog;

        warn '...';    # doesn't log to syslog
        die '...';     # ditto
    }

    # Also useful on the command line.
    perl -MCarp::Syslog=user script.pl

=head1 DESCRIPTION

I got tired of writing this all the time:

    use Sys::Syslog;
    use File::Basename qw( basename );

    BEGIN {
        openlog( basename($0), 'pid', 'local1' );
        $SIG{'__WARN__'} = sub { syslog( 'warning', @_ ); warn @_ };
        $SIG{'__DIE__'}  = sub { syslog( 'err', @_ ); die @_ };
    }
    END { closelog() }

Sure, there are modules like L<Log::Log4perl> and L<Log::Dispatch>, but those
are overly complicated for quick, system administrator style scripts.  The
C<Carp::Syslog> module allows, in one line (or less if used on the command
line), to send all warn() and die() calls to the system's syslog.

=head1 CAVEATS

The C<__WARN__> and C<__DIE__> signal handlers are overridden.

Calling cluck() or confess() will really fill up your logs.

=head1 AUTHOR

Chris Grau L<mailto:cgrau@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2012, Chris Grau.

=head1 SEE ALSO

L<Sys::Syslog>

=cut
