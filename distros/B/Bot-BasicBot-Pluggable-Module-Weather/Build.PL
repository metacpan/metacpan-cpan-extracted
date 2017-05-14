use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name   => "Bot::BasicBot::Pluggable::Module::Weather",
         license       => 'perl',
         dist_version  => '0.9',
         dist_author   => 'Simon Wistow <simon@thegestalt.org>',
         dist_abstract => 'various Weather and Aviation plugins for Bot::BasicBot::Pluggable',
         requires      => {
                          'Test::More'                     => 0,
                          'Bot::BasicBot::Pluggable'       => '0.5',
                          'Geo::WeatherNWS'                => 0,
                          'LWP::Simple'                    => 0,
                          'HTML::Entities'                 => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

