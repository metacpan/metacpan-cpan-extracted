use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CGI::AppToolkit::Template::TemplateC',
    'VERSION_FROM'  => '../lib/CGI/AppToolkit/Template/TemplateC.pm', # finds $VERSION
    'LIBS'          => [qw'-lstdc++'],   # e.g., '-lm'
    'DEFINE'        => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'           => '',     # e.g., '-I/usr/include/other'
    'MYEXTLIB'      => 'Template/libtemplatelib$(LIB_EXT)',
    'CC'            => 'c++',
#    'DIR'           => ['Template']
);
#
#sub MY::postamble {
#'
#$(MYEXTLIB): Template/Makefile
#	cd Template && $(MAKE) $(PASSTHRU)
#';
#}

sub MY::postamble {
'
$(MYEXTLIB): Template/Makefile
	cd Template && $(MAKE) all
';
}
