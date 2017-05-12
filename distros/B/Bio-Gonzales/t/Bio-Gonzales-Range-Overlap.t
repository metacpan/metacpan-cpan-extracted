use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
  eval "use Set::IntervalTree";
  plan skip_all => "Set::IntervalTree not installed" if $@;

  use_ok('Bio::Gonzales::Range::Overlap');
}

{
  my $ro = Bio::Gonzales::Range::Overlap->new( ranges => [ [ 1, 5, "eins" ], [ 7, 9, "zwei" ] ] );

  is_deeply( $ro->overlaps_with( 4, 6 ), [ [ 1, 5, "eins" ] ] );
  is_deeply( $ro->overlaps_with( 6, 6 ), [] );
  is_deeply( $ro->overlaps_with( 5, 6 ), [ [ 1, 5, "eins" ] ] );
  is_deeply( $ro->overlaps_with( 6, 7 ), [ [ 7, 9, "zwei" ] ] );
  is_deeply( $ro->contained_in( 6, 7 ),  [] );
  is_deeply( $ro->contained_in( 7, 9 ),  [ [ 7, 9, "zwei" ] ] );
  is_deeply( $ro->contained_in( 6, 10 ), [ [ 7, 9, "zwei" ] ] );
  is_deeply( $ro->contained_in( 7, 10 ), [ [ 7, 9, "zwei" ] ] );
  is_deeply( $ro->contained_in( 8, 10 ), [] );
}
{
  my $ro = Bio::Gonzales::Range::Overlap->new(
    ranges => [ [ 1, 5, "eins" ], [ 7, 9, "zwei" ] ],
    keep_coords => 0
  );

  is_deeply( $ro->overlaps_with( 4, 6 ), ["eins"] );
  is_deeply( $ro->overlaps_with( 6, 6 ), [] );
  is_deeply( $ro->overlaps_with( 5, 6 ), ["eins"] );
  is_deeply( $ro->overlaps_with( 6, 7 ), ["zwei"] );
  is_deeply( $ro->contained_in( 6, 7 ),  [] );
  is_deeply( $ro->contained_in( 7, 9 ),  ["zwei"] );
  is_deeply( $ro->contained_in( 6, 10 ), ["zwei"] );
  is_deeply( $ro->contained_in( 7, 10 ), ["zwei"] );
  is_deeply( $ro->contained_in( 8, 10 ), [] );
}

done_testing();

