use strict;
use warnings;
use Test::More tests => 4;

## make sure we can use everything
BEGIN { use_ok 'Acme::Blarghy::McBlarghBlargh' }
BEGIN { use_ok 'Moose' }
BEGIN { use_ok 'Net::Twitter' }

my $bbmbb = Acme::Blarghy::McBlarghBlargh->new;
ok( $bbmbb->blargh(), "blargh() works");
