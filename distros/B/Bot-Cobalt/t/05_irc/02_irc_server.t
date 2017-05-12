use Test::More tests => 17;
use strict; use warnings;

BEGIN{
  use_ok('Bot::Cobalt::IRC::Server');
}

my $server = new_ok('Bot::Cobalt::IRC::Server' => 
  [ name => 'irc.example.org', prefer_nick => 'abc' ]
);

is( $server->name, 'irc.example.org', 'name()' );
is( $server->prefer_nick, 'abc', 'prefer_nick()' );
ok( $server->irc(bless({}, 'MockIRC')), 'irc()' );
ok( $server->connectedat(time), 'connectedat()' );
ok( $server->connected(1), 'connected()' );

ok( $server->casemap('ascii'), 'casemap(ascii)' );
is( $server->casemap, 'ascii', 'casemap eq ascii' );
is( $server->uppercase( 'things{}'), 'THINGS{}', 'ascii uppercase()' );
is( $server->lowercase( 'THINGS{}'), 'things{}', 'ascii lowercase()' );

ok( $server->casemap('rfc1459'), 'casemap(rfc1459)' );
is( $server->casemap, 'rfc1459', 'casemap eq rfc1459' );
is( $server->uppercase( 'things{}'), 'THINGS[]', 'rfc1459 uppercase()' );
is( $server->lowercase( 'THINGS[]'), 'things{}', 'rfc1459 lowercase()' );

is( $server->maxmodes(4), 4, 'maxmodes(4)' );
is( $server->maxtargets(2), 2, 'maxtarges(2)' );

