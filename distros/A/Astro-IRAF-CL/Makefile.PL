use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'AUTHOR'	     => 'Stephen Quinney',
	      'NAME'	     => 'Astro::IRAF::CL',
	      'VERSION_FROM' => 'CL.pm',
	      'PREREQ_PM'    => {
                                  'IO::Tty' => 1.00,
                                  'IO::Pty' => 1.00,
				  'Expect'  => 1.15,
				},
	      'clean'        => { 'FILES' => '*.log *~' },
	      'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	      );
