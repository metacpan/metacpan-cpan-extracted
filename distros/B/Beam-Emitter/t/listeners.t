#! perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Lib;

use Scalar::Util qw[ refaddr ];

{
    package Foo;
    use Moo;
    with 'Beam::Emitter';
}

{
    package Goo;
    use Moo;
    extends 'Beam::Listener';

    has attr => ( is => 'ro', required => 1 );

}

sub byref { refaddr $a <= refaddr $b }

my $foo = Foo->new;

my $s11 = sub { 'evt11' };
my $s12 = sub { 'evt12' };
my $s21 = sub { 'evt21' };
my $s22 = sub { 'evt22' };

my ( $us11, $us12, $us21, $us22 );

subtest "Create initial listeners" => sub {

    subtest "default listener class" => sub {
        ok !exception {
            $us11 = $foo->subscribe( evt1 => $s11 );
            $us12 = $foo->subscribe( evt1 => $s12 );
        }, 'construction';

    };

    subtest "custom listener class" => sub {

        # test constructor is being called with args
        like exception { $foo->subscribe( evt2 => $s21, class => 'Goo' ) },
        qr/missing required arguments/i, "required attribute missing";

        ok !exception {
            $us21
              = $foo->subscribe( evt2 => $s21, class => 'Goo', attr => 's22' )
        },
        "required attribute specified";

    };

    subtest "custom listener class in separate file" => sub {

        # test constructor is being called with args
        like exception { $foo->subscribe( evt2 => $s22, class => 'CustomListener' ) },
        qr/missing required arguments/i, "required attribute missing";

        ok !exception {
            $us22
              = $foo->subscribe( evt2 => $s22, class => 'CustomListener', attr => 's22' )
        },
        "required attribute specified";

    };



};


subtest "Ensure initial listener lists are complete" => sub {

    subtest 'event1 listeners' => sub {
        my @s = sort byref $s11, $s12;
        my @cb = sort byref map { $_->callback } $foo->listeners( 'evt1' );
        is_deeply( \@cb, \@s, 'callbacks are consistent' );


    };

    subtest 'event2 listeners' => sub {
        my @s = sort byref $s21, $s22;
        my @cb = sort byref map { $_->callback } $foo->listeners( 'evt2' );
        is_deeply( \@cb, \@s, 'callbacks are consistent' );
    };

};

subtest "Ensure lists are consistent after unsubscription" => sub {

    subtest 'event1 listeners' => sub {
        &$us12;
        my @l = sort byref $foo->listeners( 'evt1' );
        my @cb = map { $_->callback } @l;
        is_deeply( \@cb, [$s11], 'remaining listeners consistent' );
        ok( $l[0]->isa( 'Beam::Listener' ) && !$l[0]->isa( 'Goo' ),
            'listener is only in default Listener class' );
    };

    subtest 'event2 listeners' => sub {
        &$us21;
        my @l = sort byref $foo->listeners( 'evt2' );
        my @cb = map { $_->callback } @l;
        is_deeply( \@cb, [$s22], 'remaining listeners consistent' );
        ok( $l[0]->isa( 'CustomListener' ), 'listener is in custom Listener class' );
      }
};

done_testing;
