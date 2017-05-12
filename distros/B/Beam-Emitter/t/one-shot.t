#! perl

use strict;
use warnings;
use Test::More;

{
    package Foo;
    use Moo;
    with 'Beam::Emitter';
}

subtest "emit" => sub {
    my $foo = Foo->new;

    my @detached = ();

    my ( $us1, $us2 );
    $us1 = $foo->subscribe(
        detach => sub {
            push @detached, 1;
            $us1->();
        } );

    $us2 = $foo->subscribe(
        detach => sub {
            push @detached, 2;
            $us2->();
        } );

    $foo->emit( 'detach' );

    is_deeply( [ sort @detached ], [ 1, 2 ], "detached both objects" );

  };

subtest "emit_args" => sub {
    my $foo = Foo->new;

    my @detached = ();

    my ( $us1, $us2 );
    $us1 = $foo->subscribe(
        detach => sub {
            push @detached, 1;
            $us1->();
        } );

    $us2 = $foo->subscribe(
        detach => sub {
            push @detached, 2;
            $us2->();
        } );

    $foo->emit_args( 'detach' );

    is_deeply( [ sort @detached ], [ 1, 2 ], "detached both objects" );

  };


done_testing;
