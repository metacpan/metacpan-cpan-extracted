use Test::More tests => 11;
use strict; use warnings;

BEGIN{
  use_ok('Bot::Cobalt::IRC::Event');
}

my $ev = new_ok('Bot::Cobalt::IRC::Event' => 
  [ context => 'Main', src => 'snacks!things@stuff.org' ]
);

ok( $ev->context eq 'Main', 'context()' );

ok( $ev->src eq 'snacks!things@stuff.org', 'src()' );

ok( $ev->src_nick eq 'snacks', 'src_nick()' );
ok( $ev->src_user eq 'things', 'src_user()' );
ok( $ev->src_host eq 'stuff.org', 'src_host()' );

ok( $ev->src('cake!pies@bakedgoods.org'), 'Reset src()' );

ok( $ev->src_nick eq 'cake', 'src_nick after reset' );
ok( $ev->src_user eq 'pies', 'src_user after reset' );
ok( $ev->src_host eq 'bakedgoods.org', 'src_host after reset' );
