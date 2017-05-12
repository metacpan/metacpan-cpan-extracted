use Test::More;
use strict; use warnings;


BEGIN {
  use_ok( 'Bot::Cobalt::Conf::File::Plugins' );
  use_ok( 'Bot::Cobalt::Conf::File::PerPlugin' );
}

use File::Spec;

my $etcdir = File::Spec->catdir( 'share', 'etc' );
my $plug_cf_path = File::Spec->catfile( $etcdir, 'plugins.conf' );

my $plugcf = new_ok( 'Bot::Cobalt::Conf::File::Plugins' => [
    cfg_path   => $plug_cf_path,
    etcdir => $etcdir,    
    debug  => 1,
  ],
);

isa_ok( $plugcf, 'Bot::Cobalt::Conf::File' );

ok( $plugcf->validate, 'validate()' );

# Plugins.pm methods:

# ->list_plugins() : ARRAY of plugin names
ok( ref $plugcf->list_plugins eq 'ARRAY', 'list_plugins() isa ARRAY' );

# ->plugin( $alias ) : Conf::File::PerPlugin OBJECT
for my $alias (@{ $plugcf->list_plugins }) {
  ## 20 aliases

  isa_ok( 
    $plugcf->plugin( $alias ),
    'Bot::Cobalt::Conf::File::PerPlugin'
  );
  
### PerPlugin.pm attribs:

### ->module()   (required)
  ok( $plugcf->plugin($alias)->module, "module() - $alias" );
}

### ->opts()  (default empty hashref)
## Opts: specified in Plugins config should be merged in
##  and override per-plugin config_file
ok( ref $plugcf->plugin('IRC')->opts eq 'HASH', "opts() isa HASH" );

ok( 
  ## known-true opt to test plugins.conf Opts: directive
  $plugcf->plugin('Alarmclock')->opts->{LevelRequired},
  "opts() merged from plugins.conf"
);

## FIXME another like above for plugin w/ Config:

### ->priority()    (optional)
ok( $plugcf->plugin('IRC')->priority, "priority()" );
### ->config_file() (optional)
ok( $plugcf->plugin('IRC')->config_file, "config_file()" );
### ->autoload()  (default true unless NoAutoLoad)
ok( $plugcf->plugin('IRC')->autoload, "autoload()" );

ok( $plugcf->plugin('Alarmclock')->reload_conf, "reload_conf()" );
ok( 
  $plugcf->plugin('Alarmclock')->opts->{LevelRequired},
  "opts() after reload_conf()"
);

ok( $plugcf->clear_plugin('Alarmclock'), 'clear_plugin()' );
ok( ! $plugcf->plugin('Alarmclock'), 'clear_plugin() was successful' );

ok( $plugcf->load_plugin('Alarmclock'), 'load_plugin()' );
ok( 
  $plugcf->plugin('Alarmclock')->opts->{LevelRequired},
  "opts() after load_plugin"
);

my $new_plug = new_ok( 'Bot::Cobalt::Conf::File::PerPlugin' => [
   module => 'Example::Module',
 ],
);

ok( $plugcf->install_plugin('Test', $new_plug), 'install_plugin()' );

ok( $plugcf->plugin('Test'), 'install_plugin() seems successful' );

is( 
  $plugcf->plugin('Test')->module, 
  'Example::Module',
   'module() after install_plugin()' 
);

done_testing
