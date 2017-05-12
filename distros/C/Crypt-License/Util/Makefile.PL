use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Crypt::License::Util',
    'VERSION_FROM'	=> 'Util.pm', # finds $VERSION
    'PM'		=> {'Util.pm' => '$(INST_LIBDIR)/Util.pm'},
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
