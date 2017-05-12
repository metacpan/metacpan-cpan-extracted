use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Crypt::License',
    'VERSION_FROM'	=> 'License.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Crypt::CapnMidNite' => 1.00,
			    'Crypt::C_LockTite'	 => 1.00,
			    'Filter::Util::Call' => 1.04,},
    'PM'		=> {'License.pm'	=> '$(INST_LIBDIR)/License.pm'},
    'MAN3PODS'		=> {'License.pod'	=> '$(INST_MAN3DIR)/Crypt::License.3'},
    'clean'             => {FILES       => "TestModule.pm prnt_split.pm Nest1.pm"},
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
