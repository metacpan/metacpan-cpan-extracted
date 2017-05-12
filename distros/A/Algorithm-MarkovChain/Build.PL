use strict;
use Module::Build;
Module::Build->new(
    module_name => 'Algorithm::MarkovChain',
    license     => 'perl',
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
   )->create_build_script;
