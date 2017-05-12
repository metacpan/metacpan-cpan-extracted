use Test::More tests => 12;
use strict; use warnings;

BEGIN{
  use_ok('Bot::Cobalt::IRC::Event::Kick');
}

my $ev = new_ok('Bot::Cobalt::IRC::Event::Kick' =>
  [ context => 'Main', src => 'yomomma!your@mother.org',
    channel => '#snacks', kicked => 'someone',
    reason => 'no reason' ]
);

isa_ok($ev, 'Bot::Cobalt::IRC::Event' );
isa_ok($ev, 'Bot::Cobalt::IRC::Event::Channel' );

ok( $ev->context eq 'Main', 'context()' );

ok( $ev->src eq 'yomomma!your@mother.org', 'src()' );

ok( $ev->src_nick eq 'yomomma', 'src_nick()' );
ok( $ev->src_user eq 'your', 'src_user()' );
ok( $ev->src_host eq 'mother.org', 'src_host()' );

ok( $ev->channel eq '#snacks', 'channel()' );

ok( $ev->kicked eq 'someone', 'kicked()' );
ok( $ev->reason eq 'no reason', 'reason()' );
