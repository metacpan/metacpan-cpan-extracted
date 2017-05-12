use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Autodia',
    'VERSION_FROM'	=> 'lib/Autodia.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				Getopt::Std  => 0,
				Data::Dumper => 0,
				File::Find   => 0,
				Template     => 1,
				# GraphViz     => 0, # optional
				# SpringGraph  => 0.02, # optional
				# VCG	     => 0.4, # optional
				XML::Simple  => 0,
			    }, 
    'EXE_FILES' => [ 'autodia.pl' ],
    
);
