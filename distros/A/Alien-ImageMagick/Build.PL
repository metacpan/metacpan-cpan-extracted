use 5.006;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

use Config;

my $perlbin = $Config{perlpath};
my $perlversion = $Config{version};
my $siteprefix = $Config{siteprefix};
my $dataprefix = $Config{siteprefix} . '/etc/';

my $core_lib =  $Config{archlib}.'/CORE/';
my $use_threads = $Config{usethreads} ? '' : '--without-threads';
my $enable_shared = ( ( $Config{useshrplib} || '' ) eq 'false' ) ? '' : '--enable-shared';
my $LDFLAGS= '-L'.$core_lib;

my ($ldconfig) = grep { -x } map { "$_/ldconfig" } split(/:/, $ENV{PATH});
$ldconfig = "$ldconfig || true" if $ldconfig;

my $builder = Alien::Base::ModuleBuild->new(
    module_name         => 'Alien::ImageMagick',
    license             => 'perl',
    dist_author         => q{Jerome Eteve <jerome.eteve@gmail.com>},
    dist_version_from   => 'lib/Alien/ImageMagick.pm',
    configure_requires => {
        'Alien::Base::ModuleBuild' => 1.15,
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More' => 1.001014,
        'Alien::Base' => 0.009,
        'IO::Socket::SSL' => 2.070,
    },
    requires => {
        'perl' => 5.006,
        'Alien::Base' => 0.009,
    },
    add_to_cleanup      => [ 'Alien-ImageMagick-*' ],

    alien_name => 'MagickWand',
    alien_repository => {
        protocol => 'https',
        host => 'imagemagick.org',
        location => '/archive/',
        exact_filename => 'ImageMagick.tar.gz'
    },

    alien_install_type => 'share',

    ## For development, to save the download time,
    ## download the package once and put it in an 'inc' directory.
    # alien_repository => {
    #                     protocol => 'local',
    #                     location => 'inc',
    #                     exact_filename => 'ImageMagick.tar.gz',
    #                    },
    alien_build_commands => [
                             ## This siteprefix will install the execs in perl's /bin and the libs in perl's lib/
                             'LDFLAGS='.$LDFLAGS.' %c --prefix=%s --sysconfdir='.$dataprefix.' --exec-prefix='.$siteprefix.' --with-perl='.$perlbin.' '.$enable_shared.' '.$use_threads . ' --with-modules',

                             # Patch the PerlMagick makefiles to reflect lib installation places.
                             # This is because ImageMagic's PerlMagick package comes with Makefile.PL files
                             # containing a relative reference to the build directory ../magick/.libs
                             #
                             # This causes https://rt.cpan.org/Public/Bug/Display.html?id=98979
                             #
                             # This (fairly) dirty patch will hopefully solve the issue,
                             # only until Image magick decides to change their Perl distribution structure.

                             # See original source in  http://trac.imagemagick.org/browser/ImageMagick/trunk/PerlMagick/Makefile.PL
                             # if this breaks.
                             q|echo "Patching Makefile.PL files in `pwd`. See |.__FILE__.q| for more"|,
                             q|perl -pi -e 's:-L\.\./magick(.*?)/\.libs:-L|.$siteprefix.q|/lib:gi' PerlMagick/Makefile.PL|,
                             q|perl -pi -e 's:-L\.\./\.\./magick(.*?)/\.libs:-L|.$siteprefix.q|/lib:gi' PerlMagick/quantum/Makefile.PL|,
                             q|perl -pi -e 's:-L\.\./\.\./magick(.*?)/\.libs:-L|.$siteprefix.q|/lib:gi' PerlMagick/default/Makefile.PL|,
                             ,
                             'make',
    ],
    alien_install_commands => [
        'LDFLAGS='.$LDFLAGS.' make install', # This will build the included PerlMagick package.
        $ldconfig // "",
        $perlbin.' -e "use Image::Magick; print Image::Magick->QuantumDepth"', # This checks Image magick is there fine.

    ],
    meta_merge => {
        resources  => {
            repository => "https://github.com/jeteve/Alien-ImageMagick",
        },
    }
);

$builder->create_build_script();

