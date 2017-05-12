use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::Authorization::Driver::ActiveDirectory',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/Authorization/Driver/ActiveDirectory.pm', # finds $VERSION
    PREREQ_PM         => {
			'CGI::Application::Plugin::Authorization::Driver' => '0',
			'Net::LDAP' => '0'
	},
	'INSTALLDIRS' => 'site',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/Authorization/Driver/ActiveDirectory.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry Sukhanov <hawkmoon@cpan.org>') : ()),
);
