use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'  => 'Class::SelfMethods',
  'VERSION_FROM' => 'Class/SelfMethods.pm', # finds $VERSION
  'PM' => {
    'Class/SelfMethods.pm' => '$(INST_LIBDIR)/SelfMethods.pm',
  },
);
