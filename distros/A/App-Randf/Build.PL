use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'App-Randf',
    module_name         => 'App::Randf',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/Randf.pm',
    script_files        => [ 'script/randf' ],
    add_to_cleanup      => [ 'App-Randf-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-Randf',
        bugtracker  => 'http://github.com/bayashi/App-Randf/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    recursive_test_files => 1,
    create_license => 1,
);

$builder->create_build_script();
