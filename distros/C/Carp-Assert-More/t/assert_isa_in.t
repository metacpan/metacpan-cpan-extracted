#!perl -Tw

use warnings;
use strict;

use Test::More tests => 12;
use Carp::Assert::More;

use Test::Exception;

my $rc = eval 'assert_isa_in(undef)';
is( $rc, undef, 'Fails the eval' );
like( $@, qr/Not enough arguments for Carp::Assert::More::assert_isa_in/, 'Prototype requires two arguments' );

dies_ok { assert_isa_in(undef, undef) } 'Dies with one undef argument';
dies_ok { assert_isa_in(bless({}, 'x'), [] ) } 'No types passed in';
dies_ok { assert_isa_in('z', []) } 'List of empty types does not allow you to pass non-objects';

lives_ok { assert_isa_in( bless({}, 'x'), [ 'x' ] ) } 'One out of one';
dies_ok  { assert_isa_in( bless({}, 'x'), [ 'y' ] ) } 'Zero out of one';
lives_ok { assert_isa_in( bless({}, 'x'), [ 'y', 'x' ] ) } 'One out of two';

@y::ISA = ( 'x' );
my $x = bless {}, 'y';
isa_ok( $x, 'y', 'Verifying our assumptions' );
lives_ok { assert_isa_in( bless({}, 'y'), [ 'y' ] ) } 'Matches child class';
lives_ok { assert_isa_in( bless({}, 'y'), [ 'x' ] ) } 'Matches base class';
dies_ok  { assert_isa_in( bless({}, 'x'), [ 'y' ] ) } 'Parent does not match child';

done_testing();
exit 0;
