use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Amon2-CLI',
    module_name         => 'Amon2::CLI',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Amon2/CLI.pm',
    add_to_cleanup      => [ 'Amon2-CLI-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Amon2-CLI',
        bugtracker  => 'http://github.com/bayashi/Amon2-CLI/issues',
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
