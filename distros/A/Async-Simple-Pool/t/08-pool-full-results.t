#!perl -T

use Modern::Perl;
use POSIX;
use Test::Spec;
use Test::Exception;
use Time::HiRes qw/ sleep time /;

plan tests => 9;

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
    };
};

runtests unless caller;
