use strict;
use Test::More tests => 3;

use Acme::Scurvy::Whoreson::BilgeRat;

use_ok("Acme::Scurvy::Whoreson::BilgeRat::Backend::insultserver");

my $i;

ok( $i = Acme::Scurvy::Whoreson::BilgeRat->new( language => 'insultserver' ), "Got a new Insult Generator");
ok( "$i", "got an insult" );

