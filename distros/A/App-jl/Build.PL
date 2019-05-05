use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'App-jl',
    module_name         => 'App::jl',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/jl.pm',
    add_to_cleanup      => [ 'App-jl-*' ],
    script_files        => [ 'script/jl' ],
    add_to_cleanup      => [ 'App-jl-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-jl',
        bugtracker  => 'http://github.com/bayashi/App-jl/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
