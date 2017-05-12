use 5.006;
use ExtUtils::MakeMaker;
use Config;

my $WIN32=0;
if ($Config{'osname'} eq "MSWin32") { $WIN32=1; }

WriteMakefile(
    'NAME'		=> 'Config::Backend::INIREG',
    'VERSION_FROM'	=> 'lib/Config/Backend/INIREG.pm',
    'PREREQ_PM'		=> ($WIN32) ? { Win32::TieRegistry => 0.24, Config::Frontend => 0.10 } :
	                              { Config::Backend::INI => 0.06 , Config::Frontend => 0.10 },
    'ABSTRACT_FROM'     => 'lib/Config/Backend/INIREG.pm',
    'AUTHOR'            => 'Hans Oesterholt-Dijkema <oesterhol@cpan.org>',
);

