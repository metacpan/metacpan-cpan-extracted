use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    name                => 'Amon2-Plugin-Web-ChromeLogger',
    module_name         => 'Amon2::Plugin::Web::ChromeLogger',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Amon2/Plugin/Web/ChromeLogger.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
        'Test::WWW::Mechanize::PSGI' => 0,
        'MIME::Base64' => 0,
        'JSON' => 0,
        'JSON::XS' => 0,
    },
    requires => {
        'perl' => '5.008001',
        'Amon2' => 0,
        'Web::ChromeLogger' => 0.04,
    },
    add_to_cleanup      => [ 'Amon2-Plugin-Web-ChromeLogger-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Amon2-Plugin-Web-ChromeLogger',
        bugtracker  => 'http://github.com/bayashi/Amon2-Plugin-Web-ChromeLogger/issues',
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
);

$builder->create_build_script();
