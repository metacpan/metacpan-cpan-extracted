
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Lib;
use FindBin qw( $Bin );
use Path::Tiny qw( path );
my $SHARE_DIR = path( $Bin, 'share' );

use Beam::Wire;

subtest 'configure_service event' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                # Classic configuration
                class => 'My::ArgsTest',
                args => { foo => 'foo' },
            },
            bar => {
                # Modern configuration
                '$extends' => 'foo',
                foo => 'bar',
            },
        },
    );

    my $called = 0;
    my $unsub = $wire->on( configure_service => sub {
        my ( $event ) = @_;
        $called++;
        is $called, 1, 'event is triggered only once';
        isa_ok $event, 'Beam::Wire::Event::ConfigService',
            'configure_service gets Beam::Wire::Event::ConfigService as first argument';
        is $event->service_name, 'foo', 'event service_name is correct';
        is_deeply $event->config, {
            class => 'My::ArgsTest',
            args => { foo => 'foo' },
        }, 'event config is complete and correct';
        $event->config->{args}{foo} = 'altered';
    } );
    my $foo = $wire->get( 'foo' );
    is $foo->got_args->[1], 'altered', 'altered configuration is correct';
    $wire->get( 'foo' );
    isnt $called, 2, 'event handler is not called for already-created service';
    $unsub->();

    $called = 0;
    $unsub = $wire->on( configure_service => sub {
        my ( $event ) = @_;
        $called++;
        is $called, 1, 'event is triggered only once';
        isa_ok $event, 'Beam::Wire::Event::ConfigService',
            'configure_service gets Beam::Wire::Event::ConfigService as first argument';
        is $event->service_name, 'bar', 'event service_name is correct';
        is_deeply $event->config, {
            class => 'My::ArgsTest',
            extends => 'foo',
            args => { foo => 'bar' },
        }, 'event config is complete and correct';
        $event->config->{args}{foo} = 'altered';
    } );
    my $bar = $wire->get( 'bar' );
    is $bar->got_args->[1], 'altered', 'altered configuration is correct';
    $wire->get( 'bar' );
    isnt $called, 2, 'event handler is not called for already-created service';
    $unsub->();
};

subtest 'build_service event' => sub {
    my $wire = Beam::Wire->new(
        config => {
            foo => {
                # Classic configuration
                class => 'My::ArgsTest',
                args => { foo => 'foo' },
            },
            bar => {
                # Modern configuration
                '$extends' => 'foo',
                foo => 'bar',
            },
        },
    );

    my $called = 0;
    my $unsub = $wire->on( build_service => sub {
        my ( $event ) = @_;
        $called++;
        is $called, 1, 'event is triggered only once';
        isa_ok $event, 'Beam::Wire::Event::BuildService',
            'build_service gets Beam::Wire::Event::BuildService as first argument';
        is $event->service_name, 'foo', 'event service_name is correct';
        isa_ok $event->service, 'My::ArgsTest', 'service has correct class';
        is_deeply $event->service->got_args, [ foo => 'foo' ], 'service args is correct';
    } );
    my $foo = $wire->get( 'foo' );
    $wire->get( 'foo' );
    isnt $called, 2, 'event handler is not called for already-created service';
    $unsub->();

    $called = 0;
    $unsub = $wire->on( build_service => sub {
        my ( $event ) = @_;
        $called++;
        is $called, 1, 'event is triggered only once';
        isa_ok $event, 'Beam::Wire::Event::BuildService',
            'build_service gets Beam::Wire::Event::BuildService as first argument';
        is $event->service_name, 'bar', 'event service_name is correct';
        isa_ok $event->service, 'My::ArgsTest', 'service has correct class';
        is_deeply $event->service->got_args, [ foo => 'bar' ], 'service args is correct';
    } );
    my $bar = $wire->get( 'bar' );
    $wire->get( 'bar' );
    isnt $called, 2, 'event handler is not called for already-created service';
    $unsub->();
};

subtest 'events from refs and inner containers' => sub {
    my $wire = Beam::Wire->new(
        config => {
            inner => {
                class => 'Beam::Wire',
                args => {
                    config => {
                        foo => {
                            class => 'My::ArgsTest',
                            args => { foo => 'foo' },
                        },
                    },
                },
            },
            foo => {
                class => 'My::RefTest',
                args => {
                    got_ref => { '$ref' => 'inner/foo' },
                },
            },
        },
    );

    my @events;
    $wire->on( configure_service => sub { push @events, shift } );
    $wire->on( build_service => sub { push @events, shift } );
    my $obj = $wire->get( 'foo' );

    is scalar @events, 6, '6 events are emitted: 3 services configured and built';
    isa_ok $events[0], 'Beam::Wire::Event::ConfigService',
        'first event is config event for requested service';
    is $events[0]->service_name, 'foo', 'name of requested service is correct';
    is $events[0]->emitter, $wire, 'event emitter is correct';
    isa_ok $events[1], 'Beam::Wire::Event::ConfigService',
        'second event is config event for inner container';
    is $events[1]->service_name, 'inner', 'name of container is correct';
    is $events[1]->emitter, $wire, 'event emitter is correct';
    isa_ok $events[2], 'Beam::Wire::Event::BuildService',
        'third event is build event for inner container';
    is $events[2]->service_name, 'inner', 'name is correct for inner container';
    is $events[2]->emitter, $wire, 'event emitter is correct';
    isa_ok $events[3], 'Beam::Wire::Event::ConfigService',
        'fourth event is config event for inner service';
    is $events[3]->service_name, 'inner/foo', 'name is correct for inner service';
    is $events[3]->emitter, $wire, 'event emitter is correct';
    isa_ok $events[4], 'Beam::Wire::Event::BuildService',
        'fifth event is build event for inner service';
    is $events[4]->service_name, 'inner/foo', 'name is correct';
    is $events[4]->emitter, $wire, 'event emitter is correct';
    isa_ok $events[5], 'Beam::Wire::Event::BuildService',
        'sixth event is build event for requested service';
    is $events[5]->service_name, 'foo', 'name is correct';
    is $events[5]->emitter, $wire, 'event emitter is correct';
};

done_testing;
