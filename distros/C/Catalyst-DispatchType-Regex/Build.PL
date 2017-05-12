use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Catalyst::DispatchType::Regex',
    license       => 'perl',
    create_readme => 1,

    requires => {
        'Catalyst::Runtime' => '5.90060',    # ::Regex was removed as a prereq
        'Moose'             => '0',
        'Text::Balanced'    => '0',
        'Text::SimpleTable' => '0'
    },
    configure_requires => { 'Module::Build' => '0.4004' },
    test_requires      => {
        'Test::More'           => '0',
        'Data::Dumper'         => '0',
        'MRO::Compat'          => '0',
        'Scalar::Util'         => '0',
        'Test::More'           => '0',
        'namespace::autoclean' => '0'
    },

    recursive_test_files => 1,

    meta_merge => {
        resources => {
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-DispatchType-Regex',
            repository => 'http://github.com/mvgrimes/catalyst-dispatch-regex'
        }
    },

    add_to_cleanup => ['Catalyst-DispatchType-Regex-*'],
);

$builder->create_build_script();
