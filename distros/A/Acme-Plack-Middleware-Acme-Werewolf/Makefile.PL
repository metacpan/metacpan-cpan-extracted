require 5.008001;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Acme::Plack::Middleware::Acme::Werewolf',
    'VERSION_FROM'  => 'lib/Plack/Middleware/Acme/Werewolf.pm',
    'PREREQ_PM'     => {
              'Test::More'  => '0.94',
              'Plack'       => '0.99',
              'Astro::MoonPhase' => '0.60',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM => 'lib/Acme/Plack/Middleware/Acme/Werewolf.pm', # retrieve abstract from module
       AUTHOR     => 'Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>') : ()),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl', ) : () ),

    ( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
            resources => {
                repository  =>      'http://github.com/makamaka/plack-middleware-acme-werewolf/',
            },
        } ) : ()
    ),
);



