use Test::Simple tests => 2;
use strict;

use Acme::KeyboardMarathon;
ok(1); 

my $km = new Acme::KeyboardMarathon;
ok( defined $km );
