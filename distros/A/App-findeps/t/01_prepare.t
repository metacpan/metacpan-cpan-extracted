use strict;
use warnings;

use Test::More 0.98 tests => 25;
use Directory::Iterator;

my $list = Directory::Iterator->new('t/scripts');
while ( $list->next ) {
    my $file = $list->get;
    do "./$file";
    like $@, qr!^Can't locate Acme/BadExample!, "$file failed as expected";
}

done_testing;
