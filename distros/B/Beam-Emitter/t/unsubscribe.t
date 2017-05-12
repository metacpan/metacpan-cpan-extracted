use strict;
use warnings;

use Test::More tests => 3;

use Beam::Emitter;

{
    package MyEmitter;

    use Moo; with 'Beam::Emitter';
}

my $emitter = MyEmitter->new;

my $counter = 0;

my $unsubscribe = $emitter->on( ping => sub { $counter++ } );

is $counter => 0, 'counter at 0';

$emitter->emit('ping');

is $counter => 1, 'counter hit';

$unsubscribe->();

$emitter->emit('ping');

is $counter => 1, 'no hit, unsubscribed';





