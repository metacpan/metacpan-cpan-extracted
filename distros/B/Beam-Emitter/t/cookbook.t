
use strict;
use warnings;
use Test::More;

# Simple emitter to use through this test
{ package My::Emitter; use Moo; with 'Beam::Emitter'; }

subtest 'Beam::Emitter SYNOPSIS' => sub {

    # A simple custom event class to perform data validation
    { package SYNOPSIS::My::Event;
        use Moo;
        extends 'Beam::Event';
        has data => ( is => 'ro' );
    }

    # A class that reads and writes data, allowing event handlers to
    # process the data
    { package SYNOPSIS::My::Emitter;
        use Moo;
        with 'Beam::Emitter';

        sub write_data {
            my ( $self, @data ) = @_;

            # Give event listeners a chance to perform further processing of
            # data
            my $event = $self->emit( "process_data",
                class => 'SYNOPSIS::My::Event',
                data => \@data,
            );

            # Give event listeners a chance to prevent the write
            return if $event->is_default_stopped;

            # Write the data
            @SYNOPSIS::data = @data;

            # Notify listeners we're done writing and send them the data
            # we wrote
            $self->emit( 'after_write', class => 'SYNOPSIS::My::Event', data => \@data );
        }
    }

    # An event handler that increments every input value in our data
    sub SYNOPSIS::increment {
        my ( $event ) = @_;
        my $data = $event->data;
        $_++ for @$data;
    }

    # An event handler that performs data validation and stops the
    # processing if invalid
    sub SYNOPSIS::prevent_negative {
        my ( $event ) = @_;
        my $data = $event->data;
        $event->stop if grep { $_ < 0 } @$data;
    }

    # An event handler that logs the data to STDERR after we've written in
    sub SYNOPSIS::log_data {
        my ( $event ) = @_;
        my $data = $event->data;
        @SYNOPSIS::log_data = @$data;
    }

    # Wire up our event handlers to a new processing object
    my $processor = SYNOPSIS::My::Emitter->new;
    $processor->on( process_data => \&SYNOPSIS::increment );
    $processor->on( process_data => \&SYNOPSIS::prevent_negative );
    $processor->on( after_write => \&SYNOPSIS::log_data );

    # Process some data
    subtest 'positive data is processed and written correctly' => sub {
        $processor->write_data( 1, 2, 3, 4, 5 );
        is_deeply \@SYNOPSIS::data, [ 2, 3, 4, 5, 6 ], 'data is written';
        is_deeply \@SYNOPSIS::log_data, [ 2, 3, 4, 5, 6 ], 'data is logged';
        @SYNOPSIS::data = @SYNOPSIS::log_data = ();
    };

    subtest 'prevent_negative stops writing of negative data' => sub {
        $processor->write_data( 1, 3, 7, -9, 11 );
        is_deeply \@SYNOPSIS::data, [ ], 'data is not written';
        is_deeply \@SYNOPSIS::log_data, [  ], 'data is not logged';
    };
};

subtest 'Allow a single listener to catch all events' => sub {

    {
        package My::Emitter::CatchAll;
        use Moo;
        with 'Beam::Emitter';
        after emit => sub {
            my ( $self, $event_name, @args ) = @_;
            return if $event_name eq '*'; # prevent recursion
            $self->emit( '*', name => $event_name, @args );
        };
    }

    my $emitter = My::Emitter::CatchAll->new;
    my @all;
    my %events = (
        foo => [],
        bar => [],
    );

    $emitter->on( '*', sub { push @all, \@_ } );
    $emitter->on( 'foo', sub { push @{ $events{foo} }, \@_ } );
    $emitter->on( 'bar', sub { push @{ $events{bar} }, \@_ } );

    $emitter->emit( 'foo' );
    is scalar @{ $events{ foo } }, 1, 'foo event caught by foo listener';
    is scalar @{ $events{ bar } }, 0, 'foo event not caught by bar listener';
    is scalar @all, 1, 'foo event caught by catch-all';
    is $all[0][0]->name, $events{ foo }[0][0]->name,
        'catch-all listener event has same name as original listener event';

    $emitter->emit( 'bar' );
    is scalar @{ $events{ foo } }, 1, 'bar event not caught by foo listener';
    is scalar @{ $events{ bar } }, 1, 'bar event caught by bar listener';
    is scalar @all, 2, 'bar event caught by catch-all';
    is $all[1][0]->name, $events{ bar }[0][0]->name,
        'catch-all listener event has same name as original listener event';

};

subtest 'Use an object method as an event handler' => sub {
    eval { require curry; 1 } or plan skip_all => 'Subtest requires "curry" module';

    { package My::Handler::Object;
        use Moo;
        our @handler_args;
        sub handler {
            @handler_args = @_;
        }
    }

    my $handler = My::Handler::Object->new;
    my $emitter = My::Emitter->new;
    $emitter->on( 'foo', $handler->curry::weak::handler );
    my $event = $emitter->emit( 'foo' );

    is_deeply \@My::Handler::Object::handler_args, [ $handler, $event ],
        'handler method with curry::weak gets correct arguments';
};

subtest 'Add custom data to an event handler' => sub {
    my $name = "Doug";
    my $emitter = My::Emitter->new;
    $emitter->on( introduce => sub { is $name, 'Doug' } );
    $emitter->emit( 'introduce' );

};

done_testing;
