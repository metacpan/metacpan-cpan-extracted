use Test::More;
use strict;
use warnings;
use Articulate::Service::Error;

my $class = 'Articulate::Service::Error';

my $provider = $class->new();

isa_ok( $provider, $class );
can_ok( $provider, 'verbs' );
is( 'error',        join ',', keys %{ $provider->verbs } );
is( 'handle_error', join ',', values %{ $provider->verbs } );

done_testing();
