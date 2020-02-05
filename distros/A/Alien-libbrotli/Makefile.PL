use strict;
use warnings;
use XS::Install;

my $libdir = "brotli";

my %params = (
    NAME   => 'Alien::libbrotli',
);

write_makefile(%params);
