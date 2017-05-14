use warnings;
use Test::More;
use Data::Dumper;
use Test::Fatal;

BEGIN { use_ok('Bio::Gonzales::Feat'); }

#check recursion
my $f1 = Bio::Gonzales::Feat->new(
  seq_id => 'a',
  source => 'src1',
  type   => 'exon',
  start  => 0,
  end    => 1,
  strand => -1
);
my $f2 = Bio::Gonzales::Feat->new(
  seq_id => 'a',
  source => 'src1',
  type   => 'exon',
  start  => 2,
  end    => 3,
  strand => -1
);

push @{ $f1->subfeats }, $f2;
push @{ $f2->subfeats }, $f1;

#diag Dumper $f2->clone;

isnt( exception { $f1->recurse_subfeats }, undef, "recursion died successfully" );
{
  my $f3 = Bio::Gonzales::Feat->new(
    seq_id     => 'a',
    source     => 'src1',
    type       => 'exon',
    start      => 0,
    end        => 1,
    strand     => -1,
    attributes => { ID => [ 'a', 'b', 'c' ] }
  );
  is( $f3->attr_first("ID"), 'a' );
  is( $f3->id,               'a' );
  is_deeply( scalar $f3->ids, [ 'a', 'b', 'c' ] );
  is_deeply( [ $f3->ids ], [ 'a', 'b', 'c' ] );
  is_deeply( $f3->attr->{ID}, [qw/a b c/] );
  is_deeply( [ $f3->ids( [qw/d e f/] ) ], [ 'a', 'b', 'c' ] );
  is_deeply( scalar $f3->ids( [qw/g h i/] ), [ 'd', 'e', 'f' ] );
  is_deeply( $f3->attr->{ID}, [qw/g h i/] );
  is_deeply( scalar $f3->replace_attr( 'ID', [qw/j k l/] ), [ 'g', 'h', 'i' ] );
}

done_testing();

