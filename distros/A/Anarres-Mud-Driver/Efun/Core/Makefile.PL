require 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Anarres::Mud::Driver::Efun::Core',
    VERSION_FROM	=> 'Core.pm', # finds $VERSION
    AUTHOR			=> 'Shevek (cpan@anarres.org)',
	INC				=> '-I../../include',
);
