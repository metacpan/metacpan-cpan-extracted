use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (NAME => 'Class::Struct::FIELDS',
   VERSION_FROM => 'FIELDS.pm',
   PREREQ_PM =>
   { Class::Struct => 0,
     base => 0,
     fields => 0 });

# Auto-generate the README from lib/Pramatic.pm:
sub MY::postamble {
  '
README: $(VERSION_FROM)
	perldoc -t $< > $@

all:: README

distclean::
	$(RM) README';
}
