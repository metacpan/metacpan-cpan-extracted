use strict;
use warnings;
use XS::Install;

my %params = (
    NAME   => 'Alien::libgeos',
);

write_makefile(%params);
