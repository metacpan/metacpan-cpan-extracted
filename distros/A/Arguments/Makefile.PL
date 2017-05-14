use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (NAME		=> 'Arguments',
   #VERSION_FROM	=> 'Arguments.pm', # finds $VERSION
   # I wish the previous would find the VERSION!
   VERSION	=> '0.2',
   PREREQ_PM	=> {}, # e.g., Module::Name => 1.1
   ABSTRACT_FROM => 'Arguments.pm', # retrieve abstract from module
   AUTHOR     => 'B. K. Oxley (binkley) <binkley@bigfoot.com>');

# Auto-generate the README from the documentation.
sub MY::postamble {
  '
README: Arguments.pm
	perldoc -t $< > $@

all:: README
';
}
