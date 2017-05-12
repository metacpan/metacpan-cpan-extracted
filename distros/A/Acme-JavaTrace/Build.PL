use strict;
use Module::Build;

Module::Build->new(
    module_name         => 'Acme::JavaTrace', 
    license             => 'perl', 
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>', 
    dist_version_from   => 'lib/Acme/JavaTrace.pm', 
    requires => {
        'Data::Dumper'  => 0, 
    }, 
    build_requires => {
        'Test'          => 0,
        'Test::More'    => 0,
    },
    add_to_cleanup      => [ 'Acme-JavaTrace-*' ],
)->create_build_script;
