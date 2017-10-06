#!perl -T

use Modern::Perl;
use POSIX;
use Test::Spec;
use Test::Exception;
use Time::HiRes qw/ sleep time /;

plan tests => 11;

my $dev_mode = 0;

# use lib '../lib';

use Data::Dumper;

use Async::Simple::Pool;

warn 'DEVELOPER MODE' if $dev_mode;

my $timeout = $dev_mode ? 0.03 : 0.5;

my $full_cycle_worst_time = 3 * $timeout * 10 * 1.5;
my $worker_delay = $timeout * 10;

my $is_win = $^O =~ /^(dos|os2|MSWin32|NetWare)$/;

describe 'All' => sub {

    describe 'process' => sub {

        my( $task, @data );

        before each => sub {
            $task = sub {
                my( $data ) = @_;
                $data->{ok} = 1;
                return $data;
            };

            @data = map { \%{{ i => $_ }} } 1..20;
        };

        # break_on     => busy/run/done
        # flush_data   => 0/1
        describe 'partial results' => sub {
            my $slow_task = sub {
                my( $data ) = @_;
                sleep $worker_delay;
                $data->{ok} = 1;
                return $data;
            };

            it 'check for results with break_on = "done"' => sub {

                my $time = time;
                my $pool = Async::Simple::Pool->new( $slow_task, \@data );

                my $result = $pool->process;
                is( scalar( grep $_, @$result ), 20, 'waiting for all tasks by default' );

                my $work_time = time - $time;
                ok( $work_time < $worker_delay * 3.5, sprintf 'async done work time = %.2f sec', $work_time );
            };

            it 'check for results with break_on = "busy"' => sub {

                my $time = time;
                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'busy' );

                my $result = $pool->process;
                is( scalar( grep $_, @$result ), 0, 'busy: do not wait anything, just run the jobs' );

                my $work_time = time - $time;
                ok( $work_time < $worker_delay, sprintf 'async done work time = %.2f sec', $work_time );
            };

            it 'check for results with break_on = "run"' => sub {

                my $time = time;
                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'run' );

                my $result = $pool->process;
                ok( scalar( grep $_, @$result ) < 20, 'run: do not wait anything, just run the jobs' );
                ok( scalar( grep $_, @$result ) > 9,  'run: do not wait anything, just run the jobs' );

                my $work_time = time - $time;
                ok( $work_time < $worker_delay * 3, sprintf 'async done work time = %.2f sec', $work_time );
            };

            it 'check for results' => sub {
                my $time = time;

                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'busy' );

                my $work_time = time - $time;
                ok( $work_time < $worker_delay, sprintf 'async done work time = %.2f sec', $work_time );

                my $result = $pool->process;

                is( scalar( grep $_, @$result ), 0, 'all threads are busy, no waiting for results' );

                # 10 tasks and 20 jobs, so we should expect exactly 2 passes of work for threads + 1 if worst case.
                sleep $full_cycle_worst_time;
                $result = $pool->process;
                is( scalar( grep $_, @$result ), 10, 'all threads are busy, got some results' );

                sleep $full_cycle_worst_time;
                $result = $pool->process;
                is( scalar( grep $_, @$result ), 20, 'all threads are busy, got some results' );
            };
        };
    };
};

runtests unless caller;
