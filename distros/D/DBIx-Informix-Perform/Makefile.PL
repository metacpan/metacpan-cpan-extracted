use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
    (
     'NAME'		=> 'DBIx::Informix::Perform',
     'VERSION_FROM'	=> 'Perform.pm',	# finds $VERSION
     'PREREQ_PM'	=> +{ DBI => 0,		# e.g., Module::Name => 1.1
			    Curses::Application => 0},
     'EXE_FILES'	=>  [ 'bin/perform', 'bin/generate' ],
     ($] >= 5.005 ?		## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Perform.pm', # retrieve abstract from module
       AUTHOR     => 'Eric C. Weaver <weav@sigma.net>') : ()),
     # 'DIR'		=> ['Perform'],
     );
