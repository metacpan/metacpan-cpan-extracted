use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'CLDR::Number',
    license       => 'Perl_5',
    create_readme => 1,
    configure_requires => {
        'Module::Build'     => '0.3622',
        'Software::License' => 0,
    },
    build_requires => {
        'open'              => 0,
        'English'           => 0,
        'Pod::Man'          => '2.04',
        'Test::Differences' => 0,
        'Test::Exception'   => '0.22',
        'Test::More'        => '0.82',
        'Test::Warn'        => '0.01',
    },
    requires => {
        'perl'                     => '5.8.1',
        'charnames'                => 0,
        'namespace::clean'         => 0,
        'parent'                   => 0,
        'strict'                   => 0,
        'utf8'                     => 0,
        'warnings'                 => 0,
        'Carp'                     => 0,
        'Class::Method::Modifiers' => '1.05',
        'Exporter'                 => 0,
        'Math::BigFloat'           => 0,
        'Math::Round'              => 0,
        'Moo'                      => '>= 1.001000, != 2.001000',
        'Moo::Role'                => 0,
        'Scalar::Util'             => 0,
    },
    meta_merge => {
        resources => {
            repository => 'git://github.com/patch/cldr-number-pm5.git',
            homepage   => 'https://github.com/patch/cldr-number-pm5',
            bugtracker => 'https://github.com/patch/cldr-number-pm5/issues',
        },
    },
);

$builder->create_build_script;
