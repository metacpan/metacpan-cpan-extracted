use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Acme-BayaC',
    module_name         => 'Acme::BayaC',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Acme/BayaC.pm',
    add_to_cleanup      => [ 'Acme-BayaC-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Acme-BayaC',
        bugtracker  => 'http://github.com/bayashi/Acme-BayaC/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
