use strict;
use warnings;

#use Test::More skip_all => '';
use Test::More tests => 38;

use_ok('Bio::Metabolic');

my $s1 = Bio::Metabolic::Substrate->new('s1');
my $s2 = Bio::Metabolic::Substrate->new('s2');

# manual test --- begin
#my $r=Bio::Metabolic::Reaction->new('r',[$s1],[$s2]);
#$r->kinetics('linear');
#my $n=Bio::Metabolic::Network->new($r);

#$r->parameter('k+')->value(2);
#$r->parameter('k-')->value(0.5);
#my $mfile = $n->mfile($s1,$s2);
# manual test --- end

my $s3 = Bio::Metabolic::Substrate->new('s3');
my $s4 = Bio::Metabolic::Substrate->new('s4');

my $r1 = Bio::Metabolic::Reaction->new( 'r1', [$s1], [ $s2, $s3 ] );
my $r2 = Bio::Metabolic::Reaction->new( 'r2', [$s2], [$s3] );
my $r3 = Bio::Metabolic::Reaction->new( 'r3', [$s2], [$s4] );

my $net1 = Bio::Metabolic::Network->new();
isa_ok( $net1, 'Bio::Metabolic::Network', 'constructor new - empty' );

my $rlist1 = $net1->reactions();
ok( !@$rlist1, 'method reaction() on empty network' );

my @slist1 = $net1->substrates->list;
ok( !@slist1, 'method substrates() on empty network' );

my $net2 = Bio::Metabolic::Network->new( $r1, $r2, $r3 );
isa_ok( $net2, 'Bio::Metabolic::Network', 'constructor new - empty' );

#$r1->kinetics('linear');
#$r2->kinetics('linear');
#$r3->kinetics('linear');
#my $f = $net2->time_derivative($s1);

#my @f = $net2->ODEs;

my $rlist2 = $net2->reactions();
is( eval(@$rlist2), 3, 'method reaction()' );

my @slist2 = $net2->substrates->list;
is( eval(@slist2), 4, 'method substrates()' );

ok( $net2->has_reaction($r1),  'method has_reaction' );
ok( $net2->has_reaction($r2),  'method has_reaction' );
ok( $net2->has_reaction($r3),  'method has_reaction' );
ok( !$net1->has_reaction($r1), 'method has_reaction' );
ok( !$net1->has_reaction($r2), 'method has_reaction' );
ok( !$net1->has_reaction($r3), 'method has_reaction' );

$net1->add_reaction($r1);
ok( $net1->has_reaction($r1),  'method add_reaction' );
ok( !$net1->has_reaction($r2), 'method add_reaction' );
ok( !$net1->has_reaction($r3), 'method add_reaction' );
@slist1 = $net1->substrates->list;
is( eval(@slist1), 3, 'method add_reaction' );

ok( $net1 <= $net2, 'comparison <=' );
ok( !( $net2 <= $net1 ), 'comparison <=' );

my $d = $net1->dist($net2);
is( $d, 2, 'method dist' );

my $m   = $net2->matrix;
my $cl2 = $net2->substrates;
my $x1  = $cl2->which($s1);
my $x2  = $cl2->which($s2);
my $x3  = $cl2->which($s3);
my $x4  = $cl2->which($s4);
is( $m->at( $x1, 0 ), -1, 'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x1, 1 ), 0,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x1, 2 ), 0,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x2, 0 ), 1,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x2, 1 ), -1, 'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x2, 2 ), -1, 'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x3, 0 ), 1,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x3, 1 ), 1,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x3, 2 ), 0,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x4, 0 ), 0,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x4, 1 ), 0,  'method matrix' ) || diag( $net2->print_matrix );
is( $m->at( $x4, 2 ), 1,  'method matrix' ) || diag( $net2->print_matrix );

$net2->remove_reaction($r2);
$rlist2 = $net2->reactions;
is( eval(@$rlist2), 2, 'method remove_reaction' );

$net2->remove_reaction($r3);
ok( $net1 == $net2, 'comparison ==' );

my $r4     = Bio::Metabolic::Reaction->new( 'r4', [$s2], [ $s4, $s4 ] );
my $net3   = Bio::Metabolic::Network->new($r4);
my $m3     = $net3->matrix;
my @m3dims = $m3->mdims;
$x1 = $net3->substrates->which($s2);
$x2 = $net3->substrates->which($s4);
is( $m3dims[0], 2, 'method matrix' );
is( $m3dims[1], 1, 'method matrix' );
is( $m3->at( $x1, 0 ), -1, 'method matrix' ) || diag( $net3->print_matrix );
is( $m3->at( $x2, 0 ), 2,  'method matrix' ) || diag( $net3->print_matrix );
