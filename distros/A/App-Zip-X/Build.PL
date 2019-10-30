use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'App::Zip::X',
    license             => 'artistic_2',
    dist_author         => q{DAMI <dami@cpan.org>},
    dist_version_from   => 'lib/App/Zip/X.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        perl         => '5.8.0', # for open my $fh, ">", \my $string
        'Test::More' => '0',
    },
    requires => {
      'Getopt::Long' => undef,
      'Archive::Zip' => undef,
      'XML::LibXML'  => undef,
    },
    add_to_cleanup     => [ 'App-Zip-X-*' ],
);

$builder->create_build_script();
