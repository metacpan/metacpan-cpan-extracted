use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::Authentication::LDAP',
    AUTHOR    => 'Andy Grundman (andy@hybridized.org)',
    PREREQ_PM => {
        Catalyst                            => '2.99',
        Catalyst::Plugin::Session::FastMmap => 0,
	Net::LDAP                           => 0,
    },
    VERSION_FROM => 'LDAP.pm'
);
