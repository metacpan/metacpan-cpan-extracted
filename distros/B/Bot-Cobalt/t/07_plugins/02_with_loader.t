use Test::More;
use strict; use warnings;

BEGIN { use_ok('Bot::Cobalt::Core::Loader') }

my $prefix = 'Bot::Cobalt::Plugin::';
my @core = map { $prefix.$_ } qw/
    Alarmclock
    Auth
    Games
    Info3
    Master
    PluginMgr
    RDB
    Rehash
    Seen
    Version
    WWW
    
    Extras::CPAN
    Extras::DNS
    Extras::Karma
    Extras::Relay
    Extras::TempConv
    
    OutputFilters::StripColor
    OutputFilters::StripFormat
/;

for my $module (@core) {
  {
    local $@;
    
    my $plugin_obj = eval {
      Bot::Cobalt::Core::Loader->load($module)
    };
    
    if ($@ || !$plugin_obj) {
      fail("Could not Core::Loader->load() for $module: $@");
    } else {
      pass("load() appears successful for $module");

      is(ref $plugin_obj, $module, "Instanced: $module")
    }
    
    my $is_reload = 
      Bot::Cobalt::Core::Loader->is_reloadable($plugin_obj);

    ok( Bot::Cobalt::Core::Loader->unload($module), "unload() for $module" );
  }

}

done_testing
