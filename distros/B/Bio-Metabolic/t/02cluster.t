use strict;
use warnings;

#use Test::More skip_all => 'testing only networks';
use Test::More tests => 21;

use_ok('Bio::Metabolic');

my $s1 = Bio::Metabolic::Substrate->new('s1');
my $s2 = Bio::Metabolic::Substrate->new('s2');
my $s3 = Bio::Metabolic::Substrate->new('s3');
my $s4 = Bio::Metabolic::Substrate->new('s4');

my $cl0 = Bio::Metabolic::Substrate::Cluster->_new_empty();
ok(
    ref($cl0) eq 'Bio::Metabolic::Substrate::Cluster', 'Cluster
creation, class method _new_empty()'
);

my $lref = $cl0->list;
is( ref($lref), 'ARRAY', 'method list() in scalar context' );
my @l = $cl0->list;
is( eval(@l), 0, 'method list() in array context' );

$cl0->add_substrates($s1);
@l = $cl0->list;
is( eval(@l), 1, 'method add_substrates with one arg' );

my $posref = $cl0->_position;
is( ref($posref), 'HASH', '_position() returns hashref' );
ok( defined( $posref->{s1} ), '_position()' ) or diag(
    "_position returns
keys ("
      . join( ',', keys(%$posref) )
      . ") and values ("
      . join( ',', values(%$posref) ) . ")"
);
ok( $cl0->has($s1), 'has' ) or diag( "list is " . join( ',', @l ) );

my $cl1 = Bio::Metabolic::Substrate::Cluster->new( $s1, $s2, $s3 );
ok(
    ref($cl1) eq 'Bio::Metabolic::Substrate::Cluster', 'Cluster
creation, class method'
);

my $cl2 = Bio::Metabolic::Substrate::Cluster->new( [ $s2, $s3, $s4 ] );
ok(
    ref($cl2) eq 'Bio::Metabolic::Substrate::Cluster', 'Cluster
creation, class method'
);

my $cl3 = $cl1->new();
ok(
    ref($cl3) eq 'Bio::Metabolic::Substrate::Cluster', 'Cluster
creation, object method'
);

my $cl4 = $cl2->copy();
ok( ref($cl3) eq 'Bio::Metabolic::Substrate::Cluster', 'method copy' );

my @slist = $cl1->list;
ok( @slist == 3, 'method list' );

ok( $cl1->has($s2),  'method has, positive' );
ok( $cl3->has($s2),  'method has, positive' );
ok( !$cl4->has($s1), 'method has, negative' );

$cl4->add_substrates($s1);
ok( $cl4->has($s1), 'method add_substrates' );

$cl1->remove_substrates( $s1, $s2 );
@l = $cl1->list;
is( eval(@l), 1, 'remove_substrates' );
is( $cl1->which($s3), 0, 'method which' );

my $cl5 = $cl2 + $cl3;
@l = $cl5->list;
is( eval(@l), 4, 'overloaded method add_clusters' );

my $i = $cl5->which($s3);
@slist = $cl5->list;
is( $slist[$i], $s3, 'method which' );
