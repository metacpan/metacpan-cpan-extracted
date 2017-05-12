use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Config::Backend::SQL',
    'VERSION_FROM'	=> 'lib/Config/Backend/SQL.pm',
    'PREREQ_PM'		=> { DBI => 1.3, Config::Frontend => 0.11 },
    'ABSTRACT_FROM'     => 'lib/Config/Backend/SQL.pm',
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);

