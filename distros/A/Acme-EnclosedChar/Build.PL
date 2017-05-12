use strict;
use warnings;
use Module::Build;

my $abstract = 'Ⓔⓝⓒⓛⓞⓢⓔⓓ Ⓐⓛⓟⓗⓐⓝⓤⓜⓔⓡⓘⓒⓢ Ⓔⓝⓒⓞⓓⓔⓡ';
if ( $] > 5.008001 ) {
  utf8::decode($abstract);
} else {
  $abstract ='Enclosed Alphanumerics Encoder';
}

my $builder = Module::Build->new(
    name                => 'Acme-EnclosedChar',
    module_name         => 'Acme::EnclosedChar',
    dist_abstract       => $abstract,
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Acme/EnclosedChar.pm',
    configure_requires  => {
        'Module::Build' => 0.38,
    },
    build_requires      => {
        'Test::More' => 0.88,
    },
    requires => {
        'perl' => '5.008001',
        'utf8' => 0,
        'parent' => 0,
        'Exporter' => 0,
    },
    add_to_cleanup      => [ 'Acme-EnclosedChar-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Acme-EnclosedChar',
        bugtracker  => 'http://github.com/bayashi/Acme-EnclosedChar/issues',
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
