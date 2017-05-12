require 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Anarres::Mud::Driver::Interpreter',
    VERSION_FROM	=> 'Interpreter.pm', # finds $VERSION
    AUTHOR			=> 'Shevek (cpan@anarres.org)',
);
