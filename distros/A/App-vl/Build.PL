use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'App-vl',
    module_name         => 'App::vl',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/vl.pm',
    script_files        => [ 'script/vl' ],
    add_to_cleanup      => [ 'App-vl-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-vl',
        bugtracker  => 'http://github.com/bayashi/App-vl/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
