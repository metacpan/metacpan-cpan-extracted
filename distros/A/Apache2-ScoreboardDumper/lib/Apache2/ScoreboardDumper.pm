package Apache2::ScoreboardDumper;

use strict;
use warnings;

our $VERSION = 0.01;

use Apache::Scoreboard;
use Apache2::RequestRec;
use Apache2::Log;
use Apache2::Const -compile => qw( DECLINED );

our %Key = (
    '_' => 'Waiting for Connection',
    'S' => 'Starting up',
    'R' => 'Reading Request',
    'W' => 'Sending Reply',
    'K' => 'Keepalive (read)',
    'D' => 'DNS Lookup',
    'C' => 'Closing connection',
    'L' => 'Logging',
    'G' => 'Gracefully finishing',
    'I' => 'Idle cleanup of worker',
    '.' => 'Open slot with no current process'
);

sub handler {
    my ( $class, $r ) = @_;

    # see if all the server slots are full
    my $image        = Apache::Scoreboard->image( $r->pool );
    my $servers_left = $image->server_limit - scalar( @{ $image->pids } );
    if ( $servers_left == 0 ) {

        my $dump_method = $r->dir_config( 'ScoreboardDumpMethod' ) || die 'ScoreboardDumpMethod not set';
        if ( $dump_method eq 'LockFreq' ) {

            # we are using locking
            my $lock_class = $r->dir_config( 'ScoreboardDumpLock' ) || die 'ScoreboardDumpLock not set';
            my $score_freq = $r->dir_config( 'ScoreboardDumpFreq' ) || die 'ScoreboardDumpLock not set';

            no strict 'refs';
            $lock_class->lock();
            my ( $count, $fulltime ) = $lock_class->getvars();
            my $now = time();
            if ( $now - $fulltime > $score_freq ) {
                $r->log->debug( "All Servers used enabling instrumentation at $now" );
                $fulltime = $now;
            }
            $lock_class->setvars( $count, $fulltime );
            $lock_class->unlock();

            # dump the scoreboard to the log
            $class->dump_scoreboard( $r, $image ) if $now == $fulltime;

        } elsif ( $dump_method eq 'Stochastic' ) {

            my $stoc_freq = $r->dir_config( 'ScoreboardDumpStochastic' ) || die 'ScoreboardDumpStochastic not set';
            if ( sprintf( '%.1f', rand( 1 ) ) <= $stoc_freq ) {

                # dump the scoreboard if less than specified value
                $class->dump_scoreboard( $r, $image );
            }

        } elsif ( $dump_method eq 'All' ) {
            $class->dump_scoreboard( $r, $image );
        }
    }

    return Apache2::Const::DECLINED;
}


sub dump_scoreboard {
    my ( $class, $r, $image ) = @_;

    my %worker_stats = map { $_ => 0 } keys %Key;
    my @worker_scores;

    my $waiting_for_connections_count = 0;
    my $writing_response              = 0;

    for ( my $parent_score = $image->parent_score;
        $parent_score;
        $parent_score = $parent_score->next
        ) {

        my $pid = $parent_score->pid;

        my $worker_score = $parent_score->worker_score;
        push @worker_scores, {
            access_count => $worker_score->access_count,
            bytes_served => $worker_score->bytes_served,
            client       => $worker_score->client,
            conn_bytes   => $worker_score->conn_bytes,
            conn_count   => $worker_score->conn_count,
            request      => $worker_score->request,
            req_time     => $worker_score->req_time,
            status       => $worker_score->status,
            vhost        => $worker_score->vhost,
        };

        $worker_stats{ $worker_score->status }++;
    }
    $Data::Dumper::Terse  = 1;
    $Data::Dumper::Indent = 0;

    my $scores = Dumper( @worker_scores );

    $r->log->info( "Scores: $scores" );
    my $stats = Dumper( %worker_stats );
    $r->log->info( "Stats: $stats" );

}


1;

__END__

=head1 NAME

Apache2::ScoreboardDumper - Dumps the scoreboard to the error log when server slots are full

=head1 SYNOPSIS

In your httpd.conf:

 PerlInitHandler Apache2::ScoreboardDumper
 PerlSetVar ScoreboardDumpMethod All | LockFreq | Stochastic
 PerlSetVar ScoreboardDumpFreq 5 # dump every 5th request
 PerlSetVar ScoreboardDumpLock My::LockPackage # optional class to provide lock and unlock
 PerlSetVar ScoreboardDumpStochastic 0.5 # 0-1, percentage of time to dump scoreboard


=head1 DESCRIPTION

This module will dump the scoreboard to the error log at info level if the number
of httpd server slots becomes full. There are 3 different ways this module can be configured.

All - dump the scoreboard each request.

LockFreq - dump the scoreboard every Nth request. You must supply a locking package.

Stochastic - dump the scoreboard every time rand(1) is less than your supplied threshold.

=head1 SEE ALSO

Apache::Scoreboard, mod_perl2

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
