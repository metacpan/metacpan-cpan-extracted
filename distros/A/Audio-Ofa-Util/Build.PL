use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Audio::Ofa::Util',
    license             => 'gpl',
    dist_author         => 'Christoph Bussenius <pepe@cpan.org>',
    dist_version_from   => 'lib/Audio/Ofa/Util.pm',
    dist_abstract       => 'Audio metadata lookup by fingerprint',
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0, # important if we are run through the generated
                              # Makefile.PL
    },
    requires => {
        'Audio::Ofa' => 0,
        'Audio::Extract::PCM' => '0.02',
        'Class::Accessor' => 0,
        'XML::Simple' => 0,
        'WebService::MusicBrainz' => 0,

        # Don't know which version I need exactly, but WebService::MusicBrainz
        # spits errors with etch's 1.59
        'XML::LibXML' => '1.69',

        perl => '5.006_00',   # utf8
    },
    add_to_cleanup      => [ 'Audio-Ofa-Util-*' ],
    create_makefile_pl  => 'small',
    create_readme       => 1,
);

$builder->create_build_script();
