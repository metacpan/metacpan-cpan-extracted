package Apache2::Instrument::Procview;

use strict;
use warnings;

our $VERSION = '0.03';

use base qw(Apache2::Instrument);

use Apache2::Const qw(OK);
use Apache2::Log;
use Time::HiRes qw(gettimeofday);
use Sys::Hostname;

use constant STRACE => "/usr/bin/strace";
use constant LSOF   => "/usr/sbin/lsof";

sub before {
    my ( $class, $r, $notes ) = @_;

    my $pid = $$;

    my $strace_file = "/tmp/$pid.strace";
    my @strace_args = ( "-Tq", "-e", "desc,network,file", "-p", $pid, "-o", $strace_file );

    $notes->{strace_file} = $strace_file;
    $notes->{strace_pid}  = fork();
    if ( $notes->{strace_pid} == 0 ) {
        exec( STRACE, @strace_args );
    }

    my $lsof_cmd = LSOF . " -p $pid 2>&1";
    $notes->{lsof} = `$lsof_cmd`;

    $notes->{pid} = $pid;
    my ( $sec, $usec ) = gettimeofday();
    $notes->{sec}  = $sec;
    $notes->{usec} = $usec;

    return Apache2::Const::OK;
}

sub after {
    my ( $class, $r, $notes ) = @_;

    kill INT => $notes->{strace_pid};
    waitpid( $notes->{strace_pid}, 0 );

    return Apache2::Const::OK;
}

sub report {
    my ( $class, $r, $notes ) = @_;

    my $pid  = $notes->{pid};
    my $sec  = $notes->{sec};
    my $usec = $notes->{usec};

    my $reportname = "/tmp/procview.$pid.$sec.$usec.trace";
    my $report;
    open( $report, '>', $reportname ) or die "Could not open file $reportname: $!";

    my @time = localtime $sec;
    printf $report "TIME %04d-%02d-%02d at %02d:%02d:%02d.%06d on %s\n",
        $time[5] + 1900, $time[4] + 1, $time[3], $time[2], $time[1], $time[0], $usec, hostname;
    print $report "REQUEST ", $r->the_request, "\n";
    my $nhandles = 0;
    foreach ( split( /\n/, $notes->{lsof} ) ) {
        my @fields = split( /\s+/ );
        if ( $fields[3] =~ /\d+\w/ ) {
            print $report "LSOF ", $_, "\n";
            $nhandles++;
        }
    }
    if ( $nhandles == 0 ) {
        $r->log->error( "$class: lsof detected no handles - is it setuid?" );
    }
    my $fh;
    open( $fh, '<' . $notes->{strace_file} ) or die "Cannot open strace file: $!";
    my $ntrace = 0;
    while ( my $line = <$fh> ) {
        print $report $line;
        $ntrace++;
    }
    if ( $ntrace == 0 ) {
        $r->log->error( "$class: strace produced no output - is it setuid?" );
    }
    close( $fh );
    unlink( $notes->{strace_file} );
    close( $report );

    return { 'reportname' => $reportname };
}

1;
