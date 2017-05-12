use Test::More tests => 8;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Conf' );
}

use File::Spec;

my $basedir;

my $etcdir = File::Spec->catdir( 'share', 'etc' );

my $conf = new_ok( 'Bot::Cobalt::Conf' => [
    etc => $etcdir,
  ],
);

### Path attribs:
## path_to_core_cf
## path_to_channels_cf
## path_to_plugins_cf
for my $type (qw/ core_cf channels_cf plugins_cf /) {
  my $meth = 'path_to_'.$type;
  ok( $conf->$meth, "attrib $type" )
}



### Config objects:
## ->core
## ->channels
## ->plugins

isa_ok( $conf->core, 'Bot::Cobalt::Conf::File::Core' );

isa_ok( $conf->channels, 'Bot::Cobalt::Conf::File::Channels' );

isa_ok( $conf->plugins, 'Bot::Cobalt::Conf::File::Plugins' );
