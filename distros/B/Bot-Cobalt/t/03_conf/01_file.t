use Test::More tests => 6;
use strict; use warnings;


BEGIN {
  use_ok( 'Bot::Cobalt::Conf::File' );
}

use File::Spec;

my $cfg_obj = new_ok( 'Bot::Cobalt::Conf::File' => [
    cfg_path => File::Spec->catfile( 'share', 'etc', 'cobalt.conf' )
  ],
);

my $this_hash;
ok( $this_hash = $cfg_obj->cfg_as_hash, 'cfg_as_hash()' );

ok( $this_hash->does('List::Objects::WithUtils::Role::Hash'), 'cfg_as_hash isa HASH' );

ok( $cfg_obj->rehash, 'rehash()' );

is_deeply( $cfg_obj->cfg_as_hash, $this_hash );
