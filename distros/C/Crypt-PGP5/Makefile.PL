use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
	       'NAME'	      =>  'Crypt::PGP5',
	       'VERSION_FROM'  =>  'PGP5.pm',
	       'PREREQ_PM'     =>  {
				    'Fcntl'        =>  0,
				    'Expect'       =>  0,
				    'POSIX'        =>  0,
				    'Time::HiRes'  =>  0,
				   },
	      );

