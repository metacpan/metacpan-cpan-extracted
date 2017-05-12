use Test::More;
use strict; use warnings;

my @core;
BEGIN {
  my $prefix = 'Bot::Cobalt::Plugin::';
  @core = map { $prefix.$_ } qw/
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

  use_ok($_) for @core;
}

new_ok($_) for @core;
can_ok($_, 'Cobalt_register', 'Cobalt_unregister') for @core;

done_testing
## FIXME
## instance a Bot::Cobalt::Core w/ tempdir path for var/
## issue a plugin_add for each
## pocoirc t/ has some helpful hints
