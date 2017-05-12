use strict;
use Test::More;
use Test::Requires
    'Test::Valgrind',
    'XML::Parser',
;

while ( my $f = <t/*.t> ) {
    subtest $f => sub { do $f };
}

done_testing;