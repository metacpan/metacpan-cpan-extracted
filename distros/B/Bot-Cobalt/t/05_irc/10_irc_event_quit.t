use Test::More tests => 10;
use strict; use warnings;

BEGIN{
  use_ok('Bot::Cobalt::IRC::Event::Quit');
}

my $ev = new_ok('Bot::Cobalt::IRC::Event::Quit' =>
  [ context => 'Main', src => 'yomomma!your@mother.org',
    common => [ '#otw', '#unix' ],
    reason => 'no reason' ]
);

isa_ok($ev, 'Bot::Cobalt::IRC::Event' );

ok( $ev->context eq 'Main', 'context()' );

ok( $ev->src eq 'yomomma!your@mother.org', 'src()' );

ok( $ev->src_nick eq 'yomomma', 'src_nick()' );
ok( $ev->src_user eq 'your', 'src_user()' );
ok( $ev->src_host eq 'mother.org', 'src_host()' );

ok( $ev->reason eq 'no reason', 'reason()' );

is_deeply( $ev->common, [ '#otw', '#unix' ], 'common()' );
