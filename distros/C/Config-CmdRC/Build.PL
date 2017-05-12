use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    module_name         => 'Config::CmdRC',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Config/CmdRC.pm',
    add_to_cleanup      => [ 'Config-CmdRC-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Config-CmdRC',
        bugtracker  => 'http://github.com/bayashi/Config-CmdRC/issues',
      }
    },
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    recursive_test_files => 1,
    create_license => 1,
);

$builder->create_build_script();
