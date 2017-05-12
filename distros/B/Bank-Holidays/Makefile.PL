use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bank::Holidays',
    VERSION_FROM      => 'lib/Bank/Holidays.pm', # finds $VERSION
    PREREQ_PM         => {
			HTML::TableExtract => 2.0,
			LWP::Simple			=> 1.30,
			DateTime        => 0.22
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bank/Holidays.pm', # retrieve abstract from module
       AUTHOR         => 'Tyler Hardison <tyler@seraph-net.net>') : ()),
);
