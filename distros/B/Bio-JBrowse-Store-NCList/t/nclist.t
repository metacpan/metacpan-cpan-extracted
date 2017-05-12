use strict;
use warnings;

use Test::More;

my $class = 'Bio::JBrowse::Store::NCList::NCList';
use_ok( $class );

my @test_subs = (
      sub { $_[0][0] },
      sub { $_[0][1] },
      sub { $_[0][2] = $_[1] },
   );

{
  my @features = (
      [ 123, 123 ],
      [ 123, 340 ],
      [ 48, 49 ],
  );
  my $list = $class->new(
      @test_subs,
      \@features
  );
  is_deeply(
      $list->nestedList,
      [
       [ 48, 49 ],
       [
          123,
          340,
          [
              [
                  123,
                  123
              ]
          ]
       ],
      ],
      'got the right nested list'
    ) or diag explain $list->nestedList;
}
{
  my $list = $class->new(
      @test_subs,
      [],
  );
  my $out = $list->nestedList;
  is_deeply( $out, [], 'empty gives empty' ) or diag explain $out;
}

done_testing;
