#!perl -T

use Modern::Perl;
use POSIX;
use Test::Spec;
use Test::Exception;
use Time::HiRes qw/ sleep time /;

plan tests => 18;

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

            it 'check for results with a flush data fulllist result' => sub {
                my $time = time;

                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'busy', flush_data => 1, result_type => 'list' );

                # Most likely we haven't results yet
                my $result = $pool->process;

                # But a very overloaded systems can calculate results up here
                my $results_count = scalar( grep $_, @$result );
                ok( $results_count <= 10, 'all threads are busy, no waiting for results' );

                # Wait, untill first pack (1..10) of results will be ready
                sleep $full_cycle_worst_time;
                $result = $pool->process;
                $results_count += scalar( grep $_, @$result );

                # Total amount of first pack is 10 ( 20 tasks divided by 10 streams )
                ok( $results_count < 20 , 'all threads are busy, got some results' );

                sleep $full_cycle_worst_time;
                $result = $pool->process;
                $results_count += scalar( grep $_, @$result );

                # Another pack of results: previous 10 was flushed and new 10 gathered.
                is( $results_count, 20, 'all threads are busy, got some results' );

                $result = $pool->process;
                $results_count += scalar( grep $_, @$result );

                # All results were flushed. Pool completely clear.
                is( scalar( grep $_, @$result ), 0, 'all results are read, nothing left' );
                is( $results_count, 20, 'all results are read. We have exactly @data results' );

                is( scalar @{ $pool->all_keys   }, 0, 'all_keys list is empty' );
                is( scalar @{ $pool->queue_keys }, 0, 'queue_keys list is empty' );
                is( scalar keys %{ $pool->data  }, 0, 'data is empty' );
            };

            it 'check for results with a flush data, hash result' => sub {
                my $time = time;

                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'busy', flush_data => 1, result_type => 'hash' );

                my $result = $pool->process;
                my $first_results_count = scalar( grep $_, keys %$result );
                ok( $first_results_count < 10, 'all threads are busy, no waiting for results' );
                warn 'Too lazy system for something goes wrong! Results count = ' . $first_results_count . ' immediately after tasks start!'  if $first_results_count;

                sleep $full_cycle_worst_time;
                $result = $pool->process;
                is( scalar( grep $result->{$_}, keys %$result ) + $first_results_count, 10, 'all threads are busy, got some results' );

                sleep $full_cycle_worst_time;
                $result = $pool->process;
                is( scalar( grep  $result->{$_}, keys %$result ), 10, 'all threads are busy, got some results' );

                $result = $pool->process;
                is( scalar( grep  $result->{$_}, keys %$result ), 0, 'all threads are busy, got some results' );

                is( scalar @{ $pool->all_keys   }, 0, 'all_keys list is empty' );
                is( scalar @{ $pool->queue_keys }, 0, 'queue_keys list is empty' );
                is( scalar keys %{ $pool->data  }, 0, 'data is empty' );
            };

            it 'check for results with a flush data, list result' => sub {
                my $time = time;

                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'busy', flush_data => 1, result_type => 'list' );

                my $result = $pool->process;
                is( scalar( grep $_, @$result ), 0, 'all threads are busy, no waiting for results' );

                sleep $full_cycle_worst_time;
                $result = $pool->process;
                is( scalar( grep $_, @$result ), 10, 'all threads are busy, got some results' );

                sleep $full_cycle_worst_time;
                $result = $pool->process;
                is( scalar( grep $_, @$result ), 10, 'all threads are busy, got some results' );
            };

        };
    };
};

runtests unless caller;
