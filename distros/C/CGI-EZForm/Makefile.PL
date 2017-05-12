use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'EZForm',
    'VERSION_FROM' => 'EZForm.pm',
    'PM'           => { 'EZForm.pm' => '$(INST_LIBDIR)/CGI/EZForm.pm' },
    'MAN3PODS'     => { 'EZForm.pm' => '$(INST_MAN3DIR)/CGI::EZForm.$(MAN3EXT)' }
  );
