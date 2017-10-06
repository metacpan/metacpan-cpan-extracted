#!perl -T

use Modern::Perl;
use POSIX;
use Test::Spec;
use Test::Exception;
use Time::HiRes qw/ sleep time /;

plan tests => 37;

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
                    task_class   => $is_win ? 'Async::Simple::Task::ForkTmpFile' : 'Async::Simple::Task::Fork',
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
    };
};

runtests unless caller;
