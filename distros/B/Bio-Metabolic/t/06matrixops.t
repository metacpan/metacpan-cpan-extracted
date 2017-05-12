use strict;
use warnings;

use Test::More tests => 73;

use_ok('Bio::Metabolic::MatrixOps');

my $m = msequence( 3, 3 );

$m->xrow( 0, 1 );
is( $m->at( 0, 0 ), 3, 'method xrow' );
is( $m->at( 0, 1 ), 4, 'method xrow' );
is( $m->at( 0, 2 ), 5, 'method xrow' );
is( $m->at( 1, 0 ), 0, 'method xrow' );
is( $m->at( 1, 1 ), 1, 'method xrow' );
is( $m->at( 1, 2 ), 2, 'method xrow' );
is( $m->at( 2, 0 ), 6, 'method xrow' );
is( $m->at( 2, 1 ), 7, 'method xrow' );
is( $m->at( 2, 2 ), 8, 'method xrow' );

$m->xcol( 0, 2 );
is( $m->at( 0, 0 ), 5, 'method xcol' );
is( $m->at( 0, 1 ), 4, 'method xcol' );
is( $m->at( 0, 2 ), 3, 'method xcol' );
is( $m->at( 1, 0 ), 2, 'method xcol' );
is( $m->at( 1, 1 ), 1, 'method xcol' );
is( $m->at( 1, 2 ), 0, 'method xcol' );
is( $m->at( 2, 0 ), 8, 'method xcol' );
is( $m->at( 2, 1 ), 7, 'method xcol' );
is( $m->at( 2, 2 ), 6, 'method xcol' );

$m->addcols( 2, 1, 3 );
is( $m->at( 0, 0 ), 5,  'method addcols' );
is( $m->at( 0, 1 ), 4,  'method addcols' );
is( $m->at( 0, 2 ), 15, 'method addcols' );
is( $m->at( 1, 0 ), 2,  'method addcols' );
is( $m->at( 1, 1 ), 1,  'method addcols' );
is( $m->at( 1, 2 ), 3,  'method addcols' );
is( $m->at( 2, 0 ), 8,  'method addcols' );
is( $m->at( 2, 1 ), 7,  'method addcols' );
is( $m->at( 2, 2 ), 27, 'method addcols' );

$m->addrows( 2, 0, -2 );
is( $m->at( 0, 0 ), 5,  'method addrows' );
is( $m->at( 0, 1 ), 4,  'method addrows' );
is( $m->at( 0, 2 ), 15, 'method addrows' );
is( $m->at( 1, 0 ), 2,  'method addrows' );
is( $m->at( 1, 1 ), 1,  'method addrows' );
is( $m->at( 1, 2 ), 3,  'method addrows' );
is( $m->at( 2, 0 ), -2, 'method addrows' );
is( $m->at( 2, 1 ), -1, 'method addrows' );
is( $m->at( 2, 2 ), -3, 'method addrows' );

#diag($m);
my $m0 = $m->permrows( vpdl( [ 2, 0, 1 ] ) );

#diag($m0);
is( $m0->at( 2, 0 ), 5,  'method permrows' );
is( $m0->at( 2, 1 ), 4,  'method permrows' );
is( $m0->at( 2, 2 ), 15, 'method permrows' );
is( $m0->at( 0, 0 ), 2,  'method permrows' );
is( $m0->at( 0, 1 ), 1,  'method permrows' );
is( $m0->at( 0, 2 ), 3,  'method permrows' );
is( $m0->at( 1, 0 ), -2, 'method permrows' );
is( $m0->at( 1, 1 ), -1, 'method permrows' );
is( $m0->at( 1, 2 ), -3, 'method permrows' );

my $m2 = msequence( 10, 12 );
$m2->delrows( 3, 5, 8 );
is( which( $m2->slice("(3),:") == 0 )->nelem, 12, 'method delrows' );
is( which( $m2->slice("(5),:") == 0 )->nelem, 12, 'method delrows' );
is( which( $m2->slice("(8),:") == 0 )->nelem, 12, 'method delrows' );

$m2->delcols( 2, 11 );
is( which( $m2->slice(":,(2)") == 0 )->nelem, 10, 'method delcols' )
  or diag($m2);
is( which( $m2->slice(":,(11)") == 0 )->nelem, 10, 'method delcols' )
  or diag($m2);

my $m3 = $m2->cutrows( 1, 2, 6 );
my @dims = $m3->mdims;
is( $dims[0], 7,  'method cutrows' ) or diag($m3);
is( $dims[1], 12, 'method cutrows' ) or diag($m3);
is( $m3->at( 6, 10 ), 118, 'method cutrows' ) or diag($m3);

#my $w = <>;

my $a = mpdl( [ [ 1, 0.5, 1 ], [ 0.5, 2, 0 ], [ 1, 0, 3 ] ] );
ok( $a->is_pos_def, 'method is_pos_def' );
ok( !$m->is_pos_def, 'method is_pos_def' );

#diag($m);
my ( $re, $p, $rank ) = $m->row_echelon_int();

#diag ($re."\n".$p."\n".$rank);
is( $re->at( 0, 0 ), 5,   'method row_echelon_int' );
is( $re->at( 0, 1 ), 4,   'method row_echelon_int' );
is( $re->at( 0, 2 ), 15,  'method row_echelon_int' );
is( $re->at( 1, 0 ), 0,   'method row_echelon_int' );
is( $re->at( 1, 1 ), -3,  'method row_echelon_int' );
is( $re->at( 1, 2 ), -15, 'method row_echelon_int' );
is( $re->at( 2, 0 ), 0,   'method row_echelon_int' );
is( $re->at( 2, 1 ), 0,   'method row_echelon_int' );
is( $re->at( 2, 2 ), 0,   'method row_echelon_int' );

my $mr = mpdl( [ 1, 0, 1 ], [ 0, 1, 1 ] );

#diag($mr);
my $k     = $mr->kernel;
my @kdims = $k->mdims;
is( $kdims[0], 3 );
is( $kdims[1], 1 );

#diag("dimensions OK!\n");
is( $k->at( 0, 0 ), -$k->at( 2, 0 ), 'method kernel' )
  or diag("kernel of $mr is $k");
is( $k->at( 1, 0 ), -$k->at( 2, 0 ), 'method kernel' )
  or diag("kernel of $mr is $k");

my $mc = mpdl( [ [ 1, 2, 1 ], [ 2, 0, 3 ], [ 1, 1, 1 ] ] );
my $cp = $mc->char_pol;
is( $cp->at(0), 1,  'method char_pol' );
is( $cp->at(1), 7,  'method char_pol' );
is( $cp->at(2), 2,  'method char_pol' );
is( $cp->at(3), -1, 'method char_pol' );
