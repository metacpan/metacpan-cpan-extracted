use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DataTables',
    VERSION_FROM      => 'lib/DataTables.pm', # finds $VERSION
    PREREQ_PM         => {
							CGI=>3.60,
							DBI=>1.611,
							JSON::XS=>2.32,
							Carp=>0.00,
						 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DataTables.pm', # retrieve abstract from module
       AUTHOR         => 'Adam Hopkins <srchulo@cpan.org>') : ()),
);
