use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'App-contenttype',
    module_name         => 'App::contenttype',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/App/contenttype.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'strict' => 0,
        'warnings' => 0,
    },
    add_to_cleanup      => [ 'App-contenttype-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/App-contenttype',
        bugtracker  => 'http://github.com/bayashi/App-contenttype/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    script_files         => [ 'script/contenttype' ],
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
