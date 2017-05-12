# Makefile.PL

use ExtUtils::MakeMaker;

print "No modules required...\n";

die "No dpkg command available!"
    unless qx{dpkg --version};

die "No debuild command available!"
    unless qx{debuild --version};

WriteMakefile(
    'NAME'          => 'DPKG-Tools',
    'VERSION_FROM'  => 'DPKG/Make.pm',
    'PMLIBDIRS' => ['DPKG'],
    'DISTNAME'      => 'DPKG-Tools',
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    ($] >= 5.005 ? (
      'AUTHOR'        => 'Scott Harrison <sharrison@users.sourceforge.net>',
    ) : () ),
    'clean'		=> {
	'FILES'	=> 'TempBuildLoc/ test_0.1*',
    },
);
