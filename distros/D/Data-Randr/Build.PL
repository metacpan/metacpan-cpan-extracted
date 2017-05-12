use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Data-Randr',
    module_name         => 'Data::Randr',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Data/Randr.pm',
    add_to_cleanup      => [ 'Data-Randr-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Data-Randr',
        bugtracker  => 'http://github.com/bayashi/Data-Randr/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
