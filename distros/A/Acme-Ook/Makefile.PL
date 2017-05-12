use ExtUtils::MakeMaker;
use File::Spec;

WriteMakefile(
              NAME              => "Acme::Ook",
              EXE_FILES         => [File::Spec->catfile("bin", "ook")],
              VERSION_FROM      => 'lib/Acme/Ook.pm',
	      PMLIBDIRS         => ['lib'],
              'dist'            => {
                  COMPRESS      => 'gzip -9f',
                  SUFFIX        => 'gz',
                  DIST_DEFAULT => 'all tardist',
              },
              MAN1PODS  => {},
              );
