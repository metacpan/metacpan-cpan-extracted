use ExtUtils::MakeMaker;

my $modules = {
  'CGI/SHTML.pm' => '$(INST_LIBDIR)/SHTML.pm',
};

WriteMakefile(
    'NAME'	=> 'CGI::SHTML',
    'VERSION_FROM' => 'CGI/SHTML.pm', # finds $VERSION
    'MAN3PODS'  => { 'CGI/SHTML.pm' => '$(INST_MAN3DIR)/CGI::SHTML.3' },
    'PM'   => $modules,
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
