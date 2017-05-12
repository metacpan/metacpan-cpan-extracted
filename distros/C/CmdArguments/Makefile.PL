use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (NAME		=> 'CmdArguments',
   VERSION	=> '1.00',
   PREREQ_PM	=> {}, # e.g., Module::Name => 1.1
   ABSTRACT_FROM => 'CmdArguments.pm', # retrieve abstract from module
   AUTHOR     => 'Navneet Kumar <navneet_k@hotmail.com>');

# Auto-generate the README from the documentation.
sub MY::postamble {
  '
README: CmdArguments.pm
	perldoc -t $< > $@

all:: README
';
}
