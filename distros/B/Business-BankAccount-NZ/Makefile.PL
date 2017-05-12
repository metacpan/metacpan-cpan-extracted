use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::BankAccount::NZ',
    'ABSTRACT'		=> 'Validates New Zealand Bank Account numbers',
    'AUTHOR'		=> 'John Bolland, Becky Alcorn, Simon Taylor',
    'VERSION_FROM'	=> 'NZ.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
);
