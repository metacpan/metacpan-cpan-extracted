use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::GSM',
    VERSION_FROM      => 'lib/Audio/GSM.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    BUILD_REQUIRES     => {
        Test::Simple        => 0.96,
        ExtUtils::MakeMaker => 6.63,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Audio/GSM.pm', # retrieve abstract from module
       AUTHOR         => 'Alexander Frolov <froller@froller.net>') : ()),
    LIBS              => ['-lgsm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(GSM_MAGIC GSM_MAJOR GSM_MINOR GSM_OPT_FAST
		 GSM_OPT_FRAME_CHAIN GSM_OPT_FRAME_INDEX GSM_OPT_LTP_CUT
		 GSM_OPT_VERBOSE GSM_OPT_WAV49 GSM_PATCHLEVEL
		 NeedFunctionPrototypes));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Audio::GSM',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
