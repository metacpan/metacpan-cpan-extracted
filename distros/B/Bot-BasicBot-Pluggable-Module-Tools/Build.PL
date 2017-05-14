use strict;
use Module::Build;

my $build = Module::Build
  ->new( module_name   => "Bot::BasicBot::Pluggable::Module::Tools",
         license       => 'perl',
         dist_version  => '0.96',
         dist_author   => 'Simon Wistow <simon@thegestalt.org>',
         dist_abstract => 'a miscellany of useful plugins for Bot::BasicBot::Pluggable',
         requires      => {
                          'Test::More'                     => 0,
                          'Bot::BasicBot::Pluggable'       => '0.5',
                          'Finance::Currency::Convert::XE' => 0,
                          'Finance::Quote'                 => 0,
                          'WWW::Shorten'                   => 0,
                          'Math::Units'                    => 0,
                          'Math::Expression'               => 0,
                          'Locale::Language'               => 0,
                          'Lingua::Ispell'                 => 0,
                          'Lingua::Translate'              => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

