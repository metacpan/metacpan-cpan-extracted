use strict;
use warnings;

#use Test::More skip_all => 'testing only networks';
use Test::More tests => 53;

use_ok('Bio::Metabolic');

my $s1 = Bio::Metabolic::Substrate->new('s1');
my $s2 = Bio::Metabolic::Substrate->new('s2');
my $s3 = Bio::Metabolic::Substrate->new('s3');
my $s4 = Bio::Metabolic::Substrate->new('s4');

my $r1 = Bio::Metabolic::Reaction->new( 'r1', [$s1], [$s2] );
is( ref($r1), 'Bio::Metabolic::Reaction', 'constructor new()' );

is( $r1->name, 'r1', 'name set ok?' );
my $cl = $r1->substrates();
my @l  = $cl->list;
is( eval(@l), 2, '2 substrates?' );
ok( $cl->has($s1),  'member s1' );
ok( $cl->has($s2),  'member s2' );
ok( !$cl->has($s3), 'not member s3' );
ok( !$cl->has($s4), 'not member s4' );

my $s = $r1->stoichiometry();
is( ref($s),                  'HASH', 'stoichiometry set?' );
is( $r1->st_coefficient($s1), -1,     'coefficient for s1 ok?' );
is( $r1->st_coefficient($s2), 1,      'coefficient for s2 ok?' );

my $cin = $r1->in;
@l = $cin->list;
is( eval(@l), 1, '1 in substrate?' );
ok( $cin->has($s1),  'in-member s1' );
ok( !$cin->has($s2), 'not in-member s2' );
ok( !$cin->has($s3), 'not in-member s3' );
ok( !$cin->has($s4), 'not in-member s4' );

my $cout = $r1->out;
@l = $cout->list;
is( eval(@l), 1, '1 out substrate?' );
ok( !$cout->has($s1), 'not out-member s1' );
ok( $cout->has($s2),  'out-member s2' );
ok( !$cout->has($s3), 'not out-member s3' );
ok( !$cout->has($s4), 'not out-member s4' );

my $r2 = Bio::Metabolic::Reaction->new( 'r2', [ $s2, $s3, $s4 ], [ -2, 1, 1 ] );
is( ref($r2), 'Bio::Metabolic::Reaction', 'constructor new()' );

$cin = $r2->in;
@l   = $cin->list;
is( eval(@l), 1, '1 in substrate?' );
ok( !$cin->has($s1), 'not in-member s1' );
ok( $cin->has($s2),  'in-member s2' );
ok( !$cin->has($s3), 'not in-member s3' );
ok( !$cin->has($s4), 'not in-member s4' );

$cout = $r2->out;
@l    = $cout->list;
is( eval(@l), 2, '2 out substrates?' );
ok( !$cout->has($s1), 'not out-member s1' );
ok( !$cout->has($s2), 'not out-member s2' );
ok( $cout->has($s3),  'out-member s3' );
ok( $cout->has($s4),  'out-member s4' );

ok( !defined $r2->st_coefficient($s1), 'coeff s1 not defined' );
is( $r2->st_coefficient($s2), -2, 'coeff s2 is -2' );
is( $r2->st_coefficient($s3), 1,  'coeff s2 is 1' );
is( $r2->st_coefficient($s4), 1,  'coeff s2 is 1' );

my $r3 = $r2->new();

$cin = $r3->in;
@l   = $cin->list;
is( eval(@l), 1, '1 in substrate?' );
ok( !$cin->has($s1), 'not in-member s1' );
ok( $cin->has($s2),  'in-member s2' );
ok( !$cin->has($s3), 'not in-member s3' );
ok( !$cin->has($s4), 'not in-member s4' );

$cout = $r3->out;
@l    = $cout->list;
is( eval(@l), 2, '2 out substrates?' );
ok( !$cout->has($s1), 'not out-member s1' );
ok( !$cout->has($s2), 'not out-member s2' );
ok( $cout->has($s3),  'out-member s3' );
ok( $cout->has($s4),  'out-member s4' );

ok( !defined $r3->st_coefficient($s1), 'coeff s1 not defined' );
is( $r3->st_coefficient($s2), -2, 'coeff s2 is -2' );
is( $r3->st_coefficient($s3), 1,  'coeff s2 is 1' );
is( $r3->st_coefficient($s4), 1,  'coeff s2 is 1' );

ok( $r2 == $r3, 'method equals' );

like( "$r1", qr/^\[s1\]->\[s2\]/, 'stringification' );
like( "$r2", qr/^\[s2\]\+\[s2\]->\[s3\]\+\[s4\]/, 'stringification' );
