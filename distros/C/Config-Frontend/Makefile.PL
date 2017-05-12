use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Config::Frontend',
    'VERSION_FROM'	=> 'lib/Config/Frontend.pm',
    'PREREQ_PM'		=> { },
    'ABSTRACT_FROM'     => 'lib/Config/Frontend.pm',
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);

