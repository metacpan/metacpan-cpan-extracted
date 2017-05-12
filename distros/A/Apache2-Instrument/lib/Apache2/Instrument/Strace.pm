package Apache2::Instrument::Strace;

use strict;
use warnings;

our $VERSION = '0.03';

use base qw(Apache2::Instrument);

use Apache2::Const -compile => qw(OK);

use constant STRACE => "/usr/bin/strace";

sub before {
    my ( $class, $r, $notes ) = @_;

    my $pid = $$;

    my $cmd = STRACE;
    my @args = ( "-c", "-p", $pid );

    my $strace = open( my $out_fh, "$cmd @args 2>&1 |" );

    $notes->{out} = $out_fh;
    $notes->{pid} = $strace;

    return Apache2::Const::OK;
}

sub after {
    my ( $class, $r, $notes ) = @_;

    kill INT => $notes->{pid};
    waitpid( $notes->{strace_pid}, 0 );

    return Apache2::Const::OK;
}

sub report {
    my ( $class, $r, $notes ) = @_;

    my $out = $notes->{out};
    my %syscalls;
    while ( <$out> ) {

        #% time     seconds  usecs/call     calls    errors syscall
        if ( /([0-9\.]+)\s+([0-9.]+)\s+(\d+)\s+(\d+)\s+((\d+)\s+)?(\S+)/ ) {
            my ( $time, $seconds, $usecs_call, $calls, $errors, $syscall ) = ( $1, $2, $3, $4, $6, $7 );
            next if $syscall eq 'total';
            $syscalls{$syscall} = {

                # name => $syscall,
                time       => $time,
                seconds    => $seconds,
                usecs_call => $usecs_call,
                calls      => $calls,
                $errors ? ( errors => $errors ) : (),
            };
        }
    }

    my @info = map { { $_ => $syscalls{$_} } }
        sort { $syscalls{$b}{time} <=> $syscalls{$a}{time} ||
            $syscalls{$b}{seconds} <=> $syscalls{$a}{seconds} ||
            $syscalls{$b}{calls} <=> $syscalls{$a}{calls} }
        keys %syscalls;

    return \@info;
}
