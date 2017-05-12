use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Chess::Mbox',
    'VERSION_FROM'	=> 'Mbox.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	      {

		  'Chess::PGN::Parse' => 0,
		  'Mail::MboxParser'  => 0

	      }, # e.g., Module::Name => 1.1
);
