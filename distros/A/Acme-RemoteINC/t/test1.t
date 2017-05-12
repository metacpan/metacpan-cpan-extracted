use strict;
use warnings;
require 5.008;

use Test::Simple tests => 2;

my $you = 'Dunna need no steenking tests';

my $we = $you;

ok($we =~ /steenk/,  'We do not use tests, ');
ok($you =~ /steenk/, 'so you do not need to ftp an outside host.');

