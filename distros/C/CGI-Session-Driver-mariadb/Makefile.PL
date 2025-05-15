use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CGI::Session::Driver::mariadb',
    VERSION_FROM => 'lib/CGI/Session/Driver/mariadb.pm',
    ABSTRACT     => 'CGI::Session driver for MariaDB',
    AUTHOR       => 'vrpprasad <vrpprasad@gmail.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'DBI'        => 1.600,
        'CGI::Session' => '4.30',
    },
);
