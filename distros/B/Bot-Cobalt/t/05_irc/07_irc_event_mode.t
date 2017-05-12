use Test::More tests => 11;
use strict; use warnings;

use Scalar::Util 'reftype';

BEGIN{
  use_ok('Bot::Cobalt::IRC::Event::Mode');
}

my $ev = new_ok('Bot::Cobalt::IRC::Event::Mode' =>
  [ context => 'Main', src => 'yomomma!your@mother.org',
    target => '#snacks', 
    mode   => '+tk', args => ['key'] ]
);

isa_ok($ev, 'Bot::Cobalt::IRC::Event' );

is( $ev->mode, '+tk', 'mode()' );

ok( $ev->context eq 'Main', 'context()' );

ok( $ev->src eq 'yomomma!your@mother.org', 'src()' );

ok( $ev->src_nick eq 'yomomma', 'src_nick()' );
ok( $ev->src_user eq 'your', 'src_user()' );
ok( $ev->src_host eq 'mother.org', 'src_host()' );

ok( reftype $ev->hash eq 'HASH', 'hash()' );

is_deeply( $ev->args, ['key'], 'args()' );
