use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name    => "Bot::BasicBot::Pluggable::Module::Network",
         license        => 'perl',
         dist_version   => '0.9',
         dist_author   => 'Simon Wistow <simon@thegestalt.org>',
         dist_abstract => 'various network plugins for Bot::BasicBot::Pluggable',
         requires       => {
                          'Test::More'                     => 0,
                          'Bot::BasicBot::Pluggable'       => '0.5',
                          'Net::Whois'                     => 0,
                          'Net::Traceroute'                => 0,
                         },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

