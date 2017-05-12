use 5.008003;
use ExtUtils::MakeMaker;

# in a Makefile.PL or Build.PL
#use lib 'inc';
#use Devel::CheckLib;
#check_lib_or_exit( lib => 'jpeg' );

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bundle::CommonModules',
    VERSION_FROM      => 'lib/Bundle/CommonModules.pm', # finds $VERSION
    PREREQ_PM         => {
        'File::Spec'                => '1.0',
        #'Some::Module'  => '1.23',
        #'Other::Module' => '>= 1.2, != 1.5, < 2.0',
        }, # e.g., Module::Name => 1.1
    ($] >= 5.003 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bundle/CommonModules.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin Rice <krice2@localdomain>') : ()),
);
