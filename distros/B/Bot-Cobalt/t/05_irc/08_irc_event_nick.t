use Test::More tests => 20;
use strict; use warnings;

use Scalar::Util 'reftype';

BEGIN{
  use_ok('Bot::Cobalt::IRC::Event::Nick');
}

my $ev = new_ok('Bot::Cobalt::IRC::Event::Nick' =>
  [ context => 'Main', src => 'yomomma!your@mother.org',
    new_nick => 'bob',
    channels => [ '#otw', '#unix' ]
  ]
);

isa_ok($ev, 'Bot::Cobalt::IRC::Event' );

ok( !$ev->equal, 'not equal()' );

ok( $ev->context eq 'Main', 'context()' );

ok( $ev->src eq 'yomomma!your@mother.org', 'src()' );

ok( $ev->src_nick eq 'yomomma', 'src_nick()' );
ok( $ev->src_user eq 'your', 'src_user()' );
ok( $ev->src_host eq 'mother.org', 'src_host()' );

ok( $ev->old_nick eq 'yomomma', 'old_nick()' );
ok( $ev->new_nick eq 'bob', 'new_nick()' );
ok( reftype $ev->channels eq 'ARRAY', 'channels() is ARRAY' );
is_deeply($ev->channels, [ '#otw', '#unix' ], 'channels() is correct' );
is_deeply($ev->channels, $ev->common, 'channels() eq common()' );
ok( $ev->channels(['#eris']), 'reset channels()' );
is_deeply( $ev->channels, ['#eris'], 'channels() matches' );
is_deeply( $ev->common, ['#eris'], 'common() matches' );

ok( $ev->src('BOB!things@example.org'), 'reset src()' );

ok( $ev->old_nick eq 'BOB', 'old_nick() after reset' );

ok( $ev->equal, 'equal()' );
