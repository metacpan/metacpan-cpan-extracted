use Test::More tests => 4;
use strict; use warnings;


BEGIN {
  use_ok( 'Bot::Cobalt::Conf::File::Channels' );
}

use File::Spec;

my $chan_cf_path = File::Spec->catfile( 'share', 'etc', 'channels.conf' );

my $chancf = new_ok( 'Bot::Cobalt::Conf::File::Channels' => [
    cfg_path => $chan_cf_path,
  ],
);

isa_ok( $chancf, 'Bot::Cobalt::Conf::File' );

ok( ref $chancf->context('Main') eq 'HASH', 'context(Main) isa HASH' );

