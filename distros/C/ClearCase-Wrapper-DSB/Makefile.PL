use ExtUtils::MakeMaker;

### Sample installation: "perl Makefile.PL PREFIX=/opt/local/perl5"

WriteMakefile(
    'NAME'		=> 'ClearCase::Wrapper::DSB',
    'VERSION_FROM'	=> 'DSB.pm', # finds $VERSION
    'PREREQ_PM' => {
	  ClearCase::Wrapper		=> 1.00,
    },
    'dist' => {
	  DIST_DEFAULT	=> 'all tardist',
	  COMPRESS	=> 'gzip --force --best',
	  TAR		=> 'gtar',
	  TARFLAGS	=> '--mode=u+w -cvf',
    },
);
