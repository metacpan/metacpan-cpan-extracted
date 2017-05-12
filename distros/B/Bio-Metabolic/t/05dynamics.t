use strict;
use warnings;

#use Test::More skip_all => '';
use Test::More tests => 18;

use_ok('Bio::Metabolic');
use_ok('Bio::Metabolic::Dynamics');

#Substrate

my $s1 = Bio::Metabolic::Substrate->new('s1');
my $s2 = Bio::Metabolic::Substrate->new('s2');
my $s3 = Bio::Metabolic::Substrate->new('s3');
my $s4 = Bio::Metabolic::Substrate->new('s4');

my $var = $s1->var();
ok( ref($var) eq 'Math::Symbolic::Variable', 'var()' );
ok( $var->name() eq $s1->name(), 'name of variable' );
ok( !defined $var->value(), 'value of variable initially undefined' );
$s1->fix(2.1);
ok( $var->value == 2.1, 'fix substrate concentration' );
$s1->release;
isnt( defined $var->value(), 'release substrate concentration' );

# Reaction

my $r1 = Bio::Metabolic::Reaction->new( 'r1', [$s1], [$s2] );
my $r2 = Bio::Metabolic::Reaction->new( 'r2', [ $s2, $s3, $s4 ], [ -2, 1, 1 ] );

ok( !defined $r2->rate(), 'rate not yet defined' );

my $phash = $r2->parameters();
is( ref($phash), 'HASH', 'retrieve parameters' );
$r2->kinetics('linear');
my $rate2 = $r2->rate;
is( ref($rate2), 'Math::Symbolic::Operator', 'method kinetics()' );

is(
    "$rate2", "(kplus_r2 * (s2 ^ 2)) - ((kminus_r2 * s3) * s4)", 'rate
expression for multilinear kinetics'
  )
  or diag("$rate2");

is( $r2->parameter("k+")->name, "kplus_r2", 'method parameter' );

$r1->kinetics('linear_irreversible');
my $rate1 = $r1->rate;
is(
    "$rate1", "k_r1 * s1", 'rate expression for irreversible linear
kinetics'
  )
  or diag("$rate1");

is( $r1->parameter("k")->name, "k_r1", 'method parameter' );

# Network

# manual test --- begin
my $r = Bio::Metabolic::Reaction->new( 'r', [$s1], [$s2] );
$r->kinetics('linear');
my $n = Bio::Metabolic::Network->new($r);

$r->parameter('k+')->value(2);
$r->parameter('k-')->value(0.5);
my $mfile = $n->mfile( $s1, $s2 );

# manual test --- end

my $r3 = Bio::Metabolic::Reaction->new( 'r1', [$s1], [ $s2, $s3 ] );
my $r4 = Bio::Metabolic::Reaction->new( 'r2', [$s2], [$s3] );
my $r5 = Bio::Metabolic::Reaction->new( 'r3', [$s2], [$s4] );

my $net = Bio::Metabolic::Network->new( $r3, $r4, $r5 );
$r3->kinetics('linear');
$r4->kinetics('linear');
$r5->kinetics('linear');
my $f1 = $net->time_derivative($s1);
is( ref($f1), 'Math::Symbolic::Operator', 'method time_derivative()' );
my $f2 = $net->time_derivative($s2);
is( ref($f2), 'Math::Symbolic::Operator', 'method time_derivative()' );
TODO: {
      local $TODO = "need better tests to check whether functions are correct";
      is( "$f1", "-1 * ((kplus_r1 * s1) - ((kminus_r1 * s2) * s3))" ) or diag($f1);

      is( "$f2",
"(-1 * ((kplus_r3 * s2) - (kminus_r3 * s4))) + ((-1 * ((kplus_r2 * s2) - (kminus_r2 * s3))) + ((kplus_r1 * s1) - ((kminus_r1 * s2) * s3)))"
  )
  or diag($f1);
}

my @f = $net->ODEs;
diag( join( "\n", ( '', @f, '' ) ) );
