use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Data-Dumper-AutoEncode',
    module_name         => 'Data::Dumper::AutoEncode',
    license             => 'artistic_2',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Data/Dumper/AutoEncode.pm',
    add_to_cleanup      => [ 'Data-Dumper-AutoEncode-*' ],
    script_files        => [ 'script/edumper' ],
    add_to_cleanup      => [ 'Data-Dumper-AutoEncode-*' ],
    no_index => {
        directory => [ 't', 'xt', 'share' ],
    },
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Data-Dumper-AutoEncode',
        bugtracker  => 'http://github.com/bayashi/Data-Dumper-AutoEncode/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1, # https://metacpan.org/pod/Software::License
);

$builder->create_build_script();
