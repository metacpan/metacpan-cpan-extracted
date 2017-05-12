use 5.010;
use strict;
use Alien::LibXML;

my $alien = Alien::LibXML->new;
say $alien->libs;
say $alien->cflags;

