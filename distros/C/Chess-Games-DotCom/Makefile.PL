use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Chess::Games::DotCom',
    'VERSION_FROM'	=> 'DotCom.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	      {
	       URI => 1.10,
	       Bundle::LWP => 0.01,
	       HTML::Tree => 3.18,
	       File::Temp => 0.14,
	       File::Butler => 3.01
	      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DotCom.pm', # retrieve abstract from module
       AUTHOR     => 'T. M. Brannon <tbone@cpan.org>') : ()),
);
