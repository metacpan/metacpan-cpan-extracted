use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DLM::Client',
    VERSION_FROM      => 'lib/DLM/Client.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DLM/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Viktor Turskyi <koorchik@>') : ()),
    LIBS              => ['-ldlm'], # e.g., '-lm'
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
  my @names = (qw(DLM_LOCKSPACE_LEN DLM_LSFL_FS DLM_LSFL_NEWEXCL DLM_LSFL_NODIR
		 DLM_LSFL_TIMEWARN DLM_LVB_LEN DLM_RESNAME_MAXLEN
		 DLM_SBF_ALTMODE DLM_SBF_DEMOTED DLM_SBF_VALNOTVALID ECANCEL
		 EINPROG EUNLOCK LKF_ALTCW LKF_ALTPR LKF_CANCEL LKF_CONVDEADLK
		 LKF_CONVERT LKF_EXPEDITE LKF_FORCEUNLOCK LKF_HEADQUE
		 LKF_IVVALBLK LKF_NODLCKBLK LKF_NODLCKWT LKF_NOORDER
		 LKF_NOQUEUE LKF_NOQUEUEBAST LKF_ORPHAN LKF_PERSISTENT
		 LKF_QUECVT LKF_TIMEOUT LKF_VALBLK LKF_WAIT LKM_CRMODE
		 LKM_CWMODE LKM_EXMODE LKM_NLMODE LKM_PRMODE LKM_PWMODE));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'DLM::Client',
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
