use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	    => "Catalyst::Plugin::Authentication::Credential::PAM",
    VERSION_FROM    => "lib/Catalyst/Plugin/Authentication/Credential/PAM.pm",
    PREREQ_PM	    => {
	'Authen::PAM'	=> 0,
	'Catalyst'	=> 0,
    },
);
