use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Amazon-CreatorsAPI',
    module_name         => 'Amazon::CreatorsAPI',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi',
    dist_version_from   => 'lib/Amazon/CreatorsAPI.pm',
    add_to_cleanup      => [ 'Amazon-CreatorsAPI-*' ],
    no_index => {
        directory => [ 't', 'xt', 'inc' ],
    },
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/bayashi/Amazon-CreatorsAPI',
            bugtracker  => 'http://github.com/bayashi/Amazon-CreatorsAPI/issues',
        }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
