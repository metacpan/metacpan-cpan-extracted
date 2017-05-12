use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Config::Frontend::Tie',
    'VERSION_FROM'	=> 'lib/Config/Frontend/Tie.pm',
    'PREREQ_PM'		=> { 'Config::Frontend' => 0.10 },
    'ABSTRACT_FROM'     => 'lib/Config/Frontend/Tie.pm',
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);

