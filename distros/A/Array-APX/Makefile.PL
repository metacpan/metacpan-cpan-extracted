#use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Array::APX',
    VERSION_FROM      => 'lib/Array/APX.pm', # finds $VERSION
    PREREQ_PM    => {
	'Array::DeepUtils'	=> '0', # or a minimum working version
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Array/APX.pm', # retrieve abstract from module
       AUTHOR         => 'VAXMAN <vaxman@cpan.org>') : ()),
);
