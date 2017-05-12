use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Beam::Emitter;

{
    package MyEmitter;

    use Moo; with 'Beam::Emitter';
}

my $emitter = MyEmitter->new;

my $unsubscribe = $emitter->on( ping => sub { } );

# simulate Global Destruction with $emitter destroyed first

undef $emitter;

ok !exception { $unsubscribe->() }, 'unsubscribe survived destroyed emitter';

done_testing;
