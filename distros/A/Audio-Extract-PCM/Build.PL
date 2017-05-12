use strict;
use warnings;
use Module::Build;

my $vers_output = `sox --version`;

if (defined $vers_output) {
    my ($soxver) = $vers_output =~ /v([\d.]+)/
        or die "Strange sox --version output: $vers_output\n";
    warn "SoX version $soxver found.\n";
} else {
    die "Could not run the sox program; please make sure it is installed.\n";
}

my $builder = Module::Build->new(
    create_readme               => 1,
    create_makefile_pl          => 'small',
    module_name         => 'Audio::Extract::PCM',
    license             => 'perl',
    dist_author         => 'Christoph Bussenius <pepe@cpan.org>',
    dist_version_from   => 'lib/Audio/Extract/PCM.pm',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Compress::Zlib' => 0,
        'Test::More' => 0,
        'Module::Build' => 0,
    },
    requires => {
        'IO::CaptureOutput' => '1.10', # need 1.10 for success flag and error code
        'version' => 0,
    },
    no_index => {
        directory => 'example',
    },
#    requires_external_bin => {
#        sox => 0,
#    },
    add_to_cleanup      => [ 'Audio-Extract-PCM-*' ],
);

$builder->create_build_script();
