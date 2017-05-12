use Test::More tests => 7;
use strict; use warnings;


BEGIN {
  use_ok( 'Bot::Cobalt::Conf::File::Core' );
}


use File::Spec;

my $core_cf_path = File::Spec->catfile( 'share', 'etc', 'cobalt.conf' );

my $corecf = new_ok( 'Bot::Cobalt::Conf::File::Core' => [
    cfg_path => $core_cf_path,
  ],
);

isa_ok( $corecf, 'Bot::Cobalt::Conf::File' );

is( $corecf->language, 'english', 'language()' );

ok( ref $corecf->irc eq 'HASH', 'irc() isa HASH' );

ok( ref $corecf->opts eq 'HASH', 'opts() isa HASH' );

ok( ref $corecf->paths eq 'HASH', 'paths() isa HASH' );
