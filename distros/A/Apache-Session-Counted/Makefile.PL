use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Apache::Session::Counted',
	      'VERSION_FROM' => 'lib/Apache/Session/Counted.pm',
              'PREREQ_PM' => {"Apache::Session"=>1.50, File::CounterFile=>0},
);

