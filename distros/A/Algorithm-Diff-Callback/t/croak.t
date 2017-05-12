#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Algorithm::Diff::Callback 'diff_arrays';

{
    no warnings qw/redefine once/;
    *Algorithm::Diff::Callback::diff = sub { return ( [ [ '*', 0, 'ack' ] ] ) };
    use warnings;
}

my @old = qw( one two  );
my @new = qw( one four );
$|++;

eval { diff_arrays( \@old, \@new, added => sub {}, deleted => sub {} ) };
ok( $@, 'Caught error' );

like( $@, qr/Can't recognize change in changeset\: '\*'/, 'Unknown change' );
