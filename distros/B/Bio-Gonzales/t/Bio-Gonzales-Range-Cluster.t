use warnings;
use Test::More;
use Data::Dumper;
use Test::Fatal;

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing" if $@;

  use_ok('Bio::Gonzales::Range::Cluster');
}

my $ranges = [

  [ 417,  '575',  7991 ],
  [ 537,  '829',  7992 ],
  [ 839,  '901',  7993 ],
  [ 1103, '1232', 8322 ],
  [ 1187, '1476', 8323 ],
  [ 1485, '1601', 8324 ],
  [ 1353, '1476', 8871 ],
  [ 1485, '1741', 8872 ],
  [ 304,  '387',  10029 ],
  [ 321,  '626',  10030 ],
  [ 639,  '801',  10031 ],
  [ 1249, '1474', 10695 ],
  [ 1485, '1698', 10696 ],
  [ 117,  '230',  10733 ],
  [ 239,  '513',  10734 ],
  [ 1485, '1730', 13110 ],
  [ 217,  '429',  13964 ],
  [ 439,  '683',  13965 ],
  [ 39,   '289',  14126 ]
];

$ranges = [ sort { $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] } @$ranges ];
{
  my $cr = Bio::Gonzales::Range::Cluster->new;
  for my $r (@$ranges) {
    $cr->add_next_range($r);
  }

  my $result = $cr->finish->clusters;

  is_deeply(
    $result,
    [
      [
        [ 39,  '289', 14126 ],
        [ 117, '230', 10733 ],
        [ 217, '429', 13964 ],
        [ 239, '513', 10734 ],
        [ 304, '387', 10029 ],
        [ 321, '626', 10030 ],
        [ 417, '575', 7991 ],
        [ 439, '683', 13965 ],
        [ 537, '829', 7992 ],
        [ 639, '801', 10031 ],
      ],

      [ [ 839, '901', 7993 ], ],
      [

        [ 1103, '1232', 8322 ],
        [ 1187, '1476', 8323 ],
        [ 1249, '1474', 10695 ],
        [ 1353, '1476', 8871 ],
      ],

      [

        [ 1485, '1601', 8324 ],
        [ 1485, '1698', 10696 ],
        [ 1485, '1730', 13110 ],
        [ 1485, '1741', 8872 ],
      ],
    ],
    "ranges"
  );
}

{
  my $cr = Bio::Gonzales::Range::Cluster->new;
  for ( my $i = 0; $i < 11; $i++ ) {
    $cr->add_next_range( $ranges->[$i] );
  }
  is_deeply(
    $cr->pick_up_clusters,
    [
      [
        [ 39,  '289', 14126 ],
        [ 117, '230', 10733 ],
        [ 217, '429', 13964 ],
        [ 239, '513', 10734 ],
        [ 304, '387', 10029 ],
        [ 321, '626', 10030 ],
        [ 417, '575', 7991 ],
        [ 439, '683', 13965 ],
        [ 537, '829', 7992 ],
        [ 639, '801', 10031 ],
      ]
    ],
    "pick up first cluster"
  );
  is_deeply( $cr->clusters, [], "pick up clears the clusters of the object" );

  $cr->add_next_range( $ranges->[11] );
  $cr->add_next_range( $ranges->[12] );

  is_deeply( $cr->pick_up_clusters, [ [ [ 839, '901', 7993 ], ], ] );
  is_deeply( $cr->clusters, [], "pick up clears the clusters of the object" );
}

{
  my $result = Bio::Gonzales::Range::Cluster->new->finish->clusters;
  is_deeply( $result, [], 'empty object finished without results' );
}

{
  isnt(
    exception { Bio::Gonzales::Range::Cluster->new->add_next_range( [ 3, 1 ] ); },
    undef, "add_next_range should not accept inverted ranges ",
  );

}
{
  isnt(
    exception { Bio::Gonzales::Range::Cluster->new->add_next_range( [] ); },
    undef, "add_next_range should not accept empty ranges ",
  );

}

{
  my $result = Bio::Gonzales::Range::Cluster->new->add_next_range( [ 1, 3 ] )->finish->clusters;
  is_deeply( $result, [ [ [ 1, 3 ] ] ] );
}

done_testing();

