use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'    => 'Chart::Plot',
              'VERSION_FROM' => 'Plot.pm', # finds $VERSION
              'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	      'PREREQ_PM' => { 'GD' => 0 } # requires any version of GD
             );
