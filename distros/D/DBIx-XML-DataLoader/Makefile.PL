use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'DBIx::XML::DataLoader',
    'VERSION_FROM'	=> 'DataLoader.pm', # finds $VERSION
    'PREREQ_PM'		=> {XML::XPath=>'1.0', DBI=>'0', XML::Simple=>'1.05', LWP::UserAgent=>'0'}, # e.g., Module::Name => 1.1
    'LIBS'		=> [''], # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '', # e.g., '-I/usr/include/other'
);
