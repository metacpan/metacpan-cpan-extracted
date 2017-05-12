#!perl

use Moose;
use Catalyst::Engine;
use Catalyst::Request;
use Catalyst::Controller;
use CatalystX::RequestRole::StrictParams;
use Test::Most;

# Methods we're checking
my @methods = qw/params parameters param/;

# Create a fake request with the methods we want to test
my $treq = Class::MOP::Class->create( 'TestRequest' => (
    methods => {
        (map { $_ => sub {1} } @methods),
        canary => sub { 1 },
    },
    superclasses => ['Catalyst::Request'],
));

# Apply the role we're testing to it
CatalystX::RequestRole::StrictParams->meta->apply( $treq );

my $request = bless {}, "TestRequest";

# These are the request callers we'll be using, and what
# we expect
my @tests = (
    {
        from => 'Catalyst::Engine',
        expected => 'lives'
    },
    {
        from => 'Catalyst::Controller',
        expected => 'dies'
    }
);

for my $test ( @tests ) {

    # Instantiate a new caller
    my $caller_name = 'Test::' . $test->{'from'};
    my $caller = $caller_name->new();

    # Sanity check the canary
    ok( $caller->run( $request, 'canary' ),
        "Canary method lives for " . $test->{'from'} );

    # Check we live or throw for the appropriate methods
    for my $method ( @methods ) {
        if ( $test->{'expected'} eq 'lives' ) {
            lives_ok { $caller->run( $request, $method ) }
                "$method lives for " . $test->{'from'};
        } else {
            throws_ok { $caller->run( $request, $method ) }
                qr/encourages insecure code/,
                "$method throws for " . $test->{'from'};
        }
    }
}

package Test::Catalyst::Engine;
use base 'Catalyst::Engine';
sub Test::Catalyst::Engine::run {
    my ( $self, $request, $method ) = @_;
    $request->$method;
}

package Test::Catalyst::Controller;
use base 'Catalyst::Controller';
sub Test::Catalyst::Controller::run {
    my ( $self, $request, $method ) = @_;
    $request->$method;
}

package main;

done_testing();