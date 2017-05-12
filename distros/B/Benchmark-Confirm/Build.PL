use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Benchmark-Confirm',
    module_name         => 'Benchmark::Confirm',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Benchmark/Confirm.pm',
    add_to_cleanup      => [ 'Benchmark-Confirm-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Benchmark-Confirm',
        bugtracker  => 'http://github.com/bayashi/Benchmark-Confirm/issues',
      }
    },
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    recursive_test_files => 1,
    create_license => 1,
);

$builder->create_build_script();
