use Config;
use XS::Install;

my %params = (
    NAME          => 'CPP::catch',
    VERSION_FROM  => 'lib/CPP/catch.pm',
    ABSTRACT_FROM => 'lib/CPP/catch.pod',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {'src' => '/'},
    },
);

write_makefile(%params);
