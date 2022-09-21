use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Algorithm::LCS::XS',
    'VERSION_FROM'	=> 'XS.pm',
    'MIN_PERL_VERSION'  => '5.8.0',
    'PREREQ_PM'		=> { 'Algorithm::Diff' => 0, 'LCS::BV' => "0.10", 'LCS::XS' => 0 },
    'ABSTRACT_FROM'     => 'XS.pm', # retrieve abstract from module
    'AUTHOR'            => 'Joe Schaefer <joe+cpan@sunstarsys.com>',
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'SIGN'              => 1,
    'test'              => { TESTS => "t/*.t" },
);
