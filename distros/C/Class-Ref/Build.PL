use 5.006001;
use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
    module_name        => 'Class::Ref',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.4' },
    requires           => { perl => '5.6.1', 'Scalar::Util' => 0, Carp => 0, },
    meta_merge         => {
        no_index => {
            package => [
                'Class::Ref::HASH',    'Class::Ref::HASH::Tie',
                'Class::Ref::ARRAY',   'Class::Ref::ARRAY::Tie',
                'Class::Ref::CODE',    'Class::Ref::REF',
                'Class::Ref::SCALAR',  'Class::Ref::LVALUE',
                'Class::Ref::VSTRING', 'Class::Ref::GLOB',
                'Class::Ref::FORMAT',  'Class::Ref::IO',
            ],
        },
        resources => {
            repository => 'https://github.com/mydimension/Class-Ref.git',
            bugtracker => 'https://github.com/mydimension/Class-Ref/issues',
        },
    },
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script;
