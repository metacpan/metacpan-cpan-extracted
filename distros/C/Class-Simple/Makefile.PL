use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# $Id: Makefile.PL,v 1.4 2007/08/27 22:24:06 sullivan Exp $
WriteMakefile(
    NAME              => 'Class::Simple',
    VERSION_FROM      => 'lib/Class/Simple.pm', # finds $VERSION
    PREREQ_PM         =>
	{
		Class::ISA   => 0.32,
		Scalar::Util => 0,
		List::Util   => 0,
	}, # e.g., Module::Name => 1.1
    TEST_REQUIRES     =>
        {
	        Test::Perl::Critic => 0,
	        Test::Exception    => 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Sullivan <sullivan@apple.com>') : ()),
);
