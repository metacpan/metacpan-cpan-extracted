package Acme::MetaSyntactic::test_ams_remote;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
__PACKAGE__->init();

our %Remote = (
    source  => 'http://www.perdu.com/',
);

1;

__DATA__
# names
Vous Etes Perdu
Pas de panique on va vous aider
