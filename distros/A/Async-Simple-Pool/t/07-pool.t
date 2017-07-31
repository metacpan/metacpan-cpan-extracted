#!perl -T

use Modern::Perl;
use POSIX;
use Test::Spec;
use Test::Exception;
use Time::HiRes qw/ sleep time /;

plan tests => 74;

my $dev_mode = 0;
use lib '../lib';
use Data::Dumper;


use Async::Simple::Pool;

warn 'DEVELOPER MODE' if $dev_mode;

my $timeout = $dev_mode ? 0.03 : 0.5;

my $full_cycle_worst_time = 3 * $timeout * 10 * 1.5;
my $worker_delay = $timeout * 10;

describe 'All' => sub {

    describe 'init' => sub {
        # Create a fork process, which will wait for data and execute &$sub if data will be passed
        my $pool;

        ok $pool = Async::Simple::Pool->new( ), 'all params are optional';

        isa_ok( $pool, 'Async::Simple::Pool', 'successful init' );
    };

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

        it 'default params check at simple start' => sub {
            my $pool;

            ok( $pool = Async::Simple::Pool->new( $task ), 'simplest pool has been created' );
            isa_ok( $pool, 'Async::Simple::Pool' );
            isa_ok( $pool->tasks,   'ARRAY',    'task list is list'        );

            # Defaults
            is( $pool->tasks_count, 10,         'default task count'       );
            is( $pool->flush_data,  0,          'we flush_data by default' );
            is( $pool->result_type, 'fulllist', 'default result type'      );
            is( $pool->break_on,    'done',     'default break on done'    );

            ok( $pool->task_class =~ /^Async::Simple::Task::\w+$/, 'default task class is ' . $pool->task_class );

            is_deeply( $pool->data,        {},                'default data is undef' );
            is_deeply( $pool->task_params, { task => $task }, 'default task params'   );
        };

        it 'default params with task and data at simple start' => sub {
            my $pool;

            ok( $pool = Async::Simple::Pool->new( $task, \@data, timeout => $timeout ), 'simplest pool has been created with task and data' );
            isa_ok( $pool, 'Async::Simple::Pool' );
            isa_ok( $pool->tasks,   'ARRAY',    'task list is list' );

            is_deeply( $pool->data, { map { $_ => { source => $data[$_], result => { %{ $data[$_] }, ok => 1 } } } 0..@data-1 }, 'passed data is parsed' );

            is_deeply( $pool->task_params, { task => $task, timeout => $timeout }, 'default task params changed from passed' );

            is_deeply( $pool->process, [ map { { %{ $data[$_] }, ok => 1 } } 0..@data-1 ], 'resuts calculated' );
        };

        it 'default params with data at simple start' => sub {
            my $pool;

            ok( $pool = Async::Simple::Pool->new( \@data, task => $task, timeout => $timeout ), 'simplest pool has been created with data' );
            isa_ok( $pool, 'Async::Simple::Pool' );
            isa_ok( $pool->tasks,   'ARRAY',    'task list is list' );

            is_deeply( $pool->data, { map { $_ => { source => $data[$_], result => { %{ $data[$_] }, ok => 1 } } } 0..@data-1 }, 'passed data is parsed' );

            is_deeply( $pool->task_params, { task => $task, timeout => $timeout }, 'default task params changed from passed' );

            is_deeply( $pool->process, [ map { { %{ $data[$_] }, ok => 1 } } 0..@data-1 ], 'resuts calculated' );
        };

        it 'default params within hash init' => sub {
            my $pool;

            ok( $pool = Async::Simple::Pool->new( task => $task ), 'simplest pool has been created' );
            isa_ok( $pool, 'Async::Simple::Pool' );
            isa_ok( $pool->tasks,   'ARRAY',    'task list is list'        );

            ok( $pool->task_class =~ /^Async::Simple::Task::\w+$/, 'default task class is ' . $pool->task_class );

            is_deeply( $pool->data,        {},                'default data is undef' );
            is_deeply( $pool->task_params, { task => $task }, 'default task params'   );

        };

        it 'default params with data within hash init' => sub {
            my $pool = Async::Simple::Pool->new( task => $task, data => \@data, timeout => $timeout );
            is_deeply( $pool->task_params, { task => $task, timeout => $timeout }, 'default task params changed from passed' );
            is_deeply( $pool->process, [ map { { %{ $data[$_] }, ok => 1 } } 0..@data-1 ] );
        };

        describe 'full params init' => sub {

            my $pool;
            my $results;

            it 'full passed params init' => sub {
                $pool = Async::Simple::Pool->new(
                    tasks_count  => 5,
                    break_on     => 'done', # [ 'busy', 'run', 'done' ]
                    data         => \@data, # [ any type you wish ]
                    result_type  => 'hash',
                    task_class   => 'Async::Simple::Task::Fork',
                    task_params  => { # Can be placed into pool params directly
                        task          => $task,
                        timeout       => $timeout,
                    },
                );
            };

            it 'check params' => sub {
                isa_ok( $pool, 'Async::Simple::Pool' );
                isa_ok( $pool->tasks,   'ARRAY',  'task list is list'        );

                # Defaults
                is( $pool->tasks_count, 5,        'default task count'       );
                is( $pool->result_type, 'hash',   'default result type'      );

                is_deeply( $pool->task_params, { task => $task, timeout => $timeout }, 'default task params'   );
            };

        };


        describe 'results from arrayref data' => sub {
            it 'arrayref data from init executed' => sub {
                my $pool = Async::Simple::Pool->new( $task, \@data );
                is_deeply( $pool->process, [ map { { %{ $data[$_] }, ok => 1 } } 0..@data-1 ] );
            };

            it 'arrayref data from process executed' => sub {
                my $pool = Async::Simple::Pool->new( $task );

                is_deeply( $pool->process, [], 'no data = no results' );

                my $results = $pool->process( \@data );
                is_deeply( $results, [ map { { %{ $data[$_] }, ok => 1 } } 0..@data-1 ], 'data processed' );
            };

            it 'arrayref data from new and from process executed' => sub {
                my $pool = Async::Simple::Pool->new( $task, \@data );
                $pool->process( \@data );

                my @chk_data = ( @data, @data );

                is_deeply( $pool->process, [ map { { %{ $chk_data[$_] }, ok => 1 } } 0..@chk_data-1 ], 'new data added to process and executed' );
            };
        };

        describe 'results from hashref data' => sub {

            my %data = ( 'one' => { i => 1 }, 'two' => { i => 2 }, 3 => { i => 33 }, 4 => { i => 44 } );
            my @keys = keys %data;

            it 'arrayref data from init executed' => sub {
                my $pool = Async::Simple::Pool->new( $task, \%data );
                is_deeply( $pool->process, [ map { { %{$data{$_}}, ok => 1 } } @keys ] );
            };

            it 'arrayref data from process executed' => sub {
                my $pool = Async::Simple::Pool->new( $task );

                is_deeply( $pool->process, [], 'no data = no results' );

                my $results = $pool->process( \%data );
                is_deeply( $results, [ map { { %{$data{$_}}, ok => 1 } } @keys ] );
            };

            it 'arrayref data from new and from process executed' => sub {
                my $pool = Async::Simple::Pool->new( $task, \%data );

                $pool->process( { zzz => { i => 99 } } );

                is_deeply( $pool->process, [ ( map { { %{$data{$_}}, ok => 1 } } @keys ), { i => 99, ok => 1 } ], 'arrayref result' );

                $pool->result_type('hash');

                is_deeply( $pool->process, { ( map { $_ => { %{$data{$_}}, ok => 1 } } @keys ), zzz => { i => 99, ok => 1 } }, 'hashref result' );
            };
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

            it 'check for results with a flush data fulllist result' => sub {
                my $time = time;

                my $pool = Async::Simple::Pool->new( $slow_task, \@data, break_on => 'busy', flush_data => 1, result_type => 'list' );

                # Most likely we haven't results yet
                my $result = $pool->process;

                # But a very overloaded systems can calculate results up here
                my $first_results_count = scalar( grep $_, @$result );
                ok( $first_results_count <= 10, 'all threads are busy, no waiting for results' );
                warn 'Too lazy system for something goes wrong! Results count = ' . $first_results_count . ' immediately after tasks start!' if $first_results_count;

                # Wait, untill first pack (1..10) of results will be ready
                sleep $full_cycle_worst_time;
                $result = $pool->process;

                # Total amount of first pack is 10 ( 20 tasks divided by 10 streams )
                is( scalar( grep $_, @$result ) + $first_results_count, 10, 'all threads are busy, got some results' );

                sleep $full_cycle_worst_time;
                $result = $pool->process;

                # Another pack of results: previous 10 was flushed and new 10 gathered.
                is( scalar( grep $_, @$result ), 10, 'all threads are busy, got some results' );

                $result = $pool->process;
                # All results were flushed. Pool completely clear.
                is( scalar( grep $_, @$result ), 0, 'all results are read, nothing left' );

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
