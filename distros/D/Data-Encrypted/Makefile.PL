use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Data::Encrypted',
	      'VERSION_FROM' => 'Encrypted.pm',
	      'AUTHOR' => 'Aaron J Mackey <amackey@virginia.edu>',
	      'PREREQ_PM' => { Storable => 0,
			       Term::ReadPassword => 0,
			       Crypt::RSA => 0,
			       File::HomeDir => 0,
			     }
	     );
