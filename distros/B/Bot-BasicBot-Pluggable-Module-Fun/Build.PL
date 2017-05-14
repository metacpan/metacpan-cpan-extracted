use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name   => "Bot::BasicBot::Pluggable::Module::Fun",
         license       => 'perl',
         dist_version  => '0.9',
         dist_author   => 'Simon Wistow <simon@thegestalt.org>', 
         dist_abstract => 'various quirky but ultimately useless plugins for Bot::BasicBot::Pluggable', 
         requires      => {
                          'Test::More'                     => 0,
                          'Bot::BasicBot::Pluggable'       => '0.5',
                          'Games::Dice'                    => 0,
                          'Lingua::Translate'              => 0,
                          'Acme::Magic8Ball'               => '1.1',
                          'Math::Trig'                     => 0,                          
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

