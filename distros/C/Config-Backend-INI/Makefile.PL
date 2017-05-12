use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Config::Backend::INI',
    'VERSION_FROM'	=> 'lib/Config/Backend/INI.pm',
    'PREREQ_PM'		=> { Config::IniFiles => 2.38 , Config::Frontend => 0.10 },
    'ABSTRACT_FROM'     => 'lib/Config/Backend/INI.pm',
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);

