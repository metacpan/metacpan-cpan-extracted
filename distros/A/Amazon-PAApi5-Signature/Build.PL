use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Amazon-PAApi5-Signature',
    module_name         => 'Amazon::PAApi5::Signature',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Amazon/PAApi5/Signature.pm',
    add_to_cleanup      => [ 'Amazon-PAApi5-Signature-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Amazon-PAApi5-Signature',
        bugtracker  => 'http://github.com/bayashi/Amazon-PAApi5-Signature/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
