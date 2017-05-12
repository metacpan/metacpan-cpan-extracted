use strict;
use warnings;
use Module::Build;

use 5.010;

my $builder = Module::Build->new(
    module_name         => 'Data::asXML',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Data/asXML.pm',
    configure_requires  => { 'Module::Build' => 0.42 },
    requires => {
        'Carp'         => 0,
        'XML::LibXML'  => 0,
        'Scalar::Util' => 0,
        'Class::Accessor::Fast'
                       => 0,
        'URI::Escape'  => 0,
        'Test::Deep::NoTest' => 0,
        'MIME::Base64' => 0,
        'XML::Char'    => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup      => [ 'Data-asXML-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Data-asXML.git',
            bugtracker => 'http://github.com/jozef/Data-asXML/issues',
        },
        keywords => [ qw/ data xml structure / ],
    },
);

$builder->create_build_script();
