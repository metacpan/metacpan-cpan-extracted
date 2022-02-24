# -*- perl -*-

use warnings;
use strict;
use Test::More tests => 7;

use B::Keywords ":all";

for my $name (qw(Scalars Arrays Hashes Filehandles Symbols Functions Barewords)) {
    no strict 'refs';
    ok @{$name}, ":all exports \@$name";
}
