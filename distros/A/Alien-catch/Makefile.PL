use XS::Install;

my %params = (
    NAME      => 'Alien::catch',
    BIN_SHARE => {
        CPLUS   => 11,
        INCLUDE => {'src' => '/'},
    },
);

write_makefile(%params);
