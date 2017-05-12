use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::MultiLanguage',
    VERSION_FROM      => 'lib/App/MultiLanguage.pm', # finds $VERSION
    PREREQ_PM         => {
    					  'Net::LDAP'      => '0.33',
    					  },
    ($] >= 5.006 ?   
      (ABSTRACT  => 'Multi-language support for applications', # retrieve abstract from module
       LICENSE		=> 'Perl',
       AUTHOR         => 'Pan Yu <xiaocong[at]vip.163.com>') : ()),
);
