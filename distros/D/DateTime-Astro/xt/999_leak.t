use strict;
use Test::More;
BEGIN {
    if (! $ENV{TEST_LEAK}) {
        plan skip_all => "TEST_LEAK not set";
    }
}
use Test::Requires
    'Test::Valgrind',
    'XML::Parser',
;

while ( my $f = <t/*.t> ) {
    subtest $f => sub { do $f };
}

done_testing;