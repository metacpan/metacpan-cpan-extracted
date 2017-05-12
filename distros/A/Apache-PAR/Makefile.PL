use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

Apache::TestMM::filter_args();
Apache::TestRunPerl->generate_script();

WriteMakefile(
    'NAME'          => 'Apache::PAR',
    'VERSION_FROM'	=> 'PAR.pm', # finds $VERSION
    'clean'         => {FILES => 't/httpd.conf t/error_log t/httpd'},
    'PREREQ_PM'		=> {
    	PAR          => .74,
    	MIME::Types  => 1.004,
    	Archive::Zip => 1.05,
    	mod_perl     => 1.26,
    	Apache::Test => 1.01,
    	Digest::MD5  => 2.20,
    	File::Spec   => .83,
    	File::Path   => 1.05
    }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PAR.pm', # retrieve abstract from module
       AUTHOR        => 'Nathan Byrd <nathan@byrd.net>') : ()),
);

