use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::Session::Flex',
    AUTHOR    => 'Rusty Conover (rconover@infogears.com)',
    PREREQ_PM => {
        Catalyst                 => '2.99',
        Class::Accessor::Fast    => 0,
        Class::Data::Inheritable => 0,
        Digest::MD5              => 0,
        URI                      => 0,
        URI::Find                => 0,
	Apache::Session::Flex    => 0,
    },
    VERSION_FROM => 'Flex.pm'
);
