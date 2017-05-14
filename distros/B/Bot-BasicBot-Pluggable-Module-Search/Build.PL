use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name   => "Bot::BasicBot::Pluggable::Module::Search",
         license       => 'perl',
         dist_version  => '1.0',
         dist_author   => 'Simon Wistow <simon@thegestalt.org>',
         requires      => {
                          'Test::More'                     => 0,
                          'Bot::BasicBot::Pluggable'       => '0.5',
                          'WWW::Search'                    => 0,
                          'XML::RSS'                       => 0,
                          'HTML::Entities'                 => 0,
                          'LWP::Simple'                    => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

