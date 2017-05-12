
use strict;
use warnings;

use Test::More;

use Beam::Emitter;

my $SUBBED = 0;
my $UNSUBBED = 0;

{
    package MyEmitter;

    use Moo; with 'Beam::Emitter';
    before subscribe => sub { $SUBBED++ };
    before unsubscribe => sub { $UNSUBBED++ };
}

my $fooed = 0;
my $obj = MyEmitter->new;
my $cb = sub { $fooed++ };
$obj->on( foo => $cb );
is $SUBBED, 1, 'correct, modified subscribe() was called';
$obj->emit( 'foo' );
is $fooed, 1, 'event listener was called';
$obj->un( foo => $cb );
is $UNSUBBED, 1, 'correct, modified unsubscribe() was called';

done_testing;
