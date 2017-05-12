use 5.0050000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::I18N',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/I18N.pm', # finds $VERSION
    PREREQ_PM         => {
    	CGI::Application         => 1,
    	Locale::Maketext::Simple => 0.14,
    	I18N::LangTags           => 0.30,
    	Test::More               => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/I18N.pm', # retrieve abstract from module
       AUTHOR         => 'Lyle Hopkins <webmaster@cosmicperl.com>') : ()),
);
