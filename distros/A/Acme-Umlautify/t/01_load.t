use Test::Simple tests => 2;
use strict;

use Acme::Umlautify;
ok(1);

my $au = new Acme::Umlautify;
ok(defined $au);
