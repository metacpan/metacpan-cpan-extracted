# -*- mode: Perl -*-

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(NAME         => 'Chart-ThreeD',
              VERSION_FROM => 'lib/Chart/ThreeD/Pie.pm',
              dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
	      PREREQ_PM    => { 'GD' => 0 },
	      clean        => { FILES => '*.bak *.old lib/*/*/*~' },
              );
