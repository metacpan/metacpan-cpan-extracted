
BEGIN{ require "t/lib/t.pl"; &init; }
use Test::More tests => 4;
use Scalar::Util qw( isweak weaken );

{
  my $b = Data::Rebuilder->new;
  my $array = [ "hoge" ];
  $array->[1] = $array;
  weaken( $array->[1] );
  my $rebuilt =  $b->_t( $array );
  ok( isweak( $rebuilt->[1] ) );
}

{
  my $b = Data::Rebuilder->new;
  my $array = [ "hoge" ];
  $array->[1] = \$array;
  $array->[2] = \$array;
  weaken( $array->[1] );
  my $rebuilt =  $b->_t( $array );
  ok( isweak( $rebuilt->[1] ) );
}

{
  my $b = Data::Rebuilder->new;
  my $hash = { foo => "hoge" };
  $hash->{bar} = $hash;
  weaken( $hash->{bar} );
  my $rebuilt =  $b->_t( $hash );
  ok( isweak( $rebuilt->{bar} ) );
}

{
  my $b = Data::Rebuilder->new;
  my $hash = { foo => "hoge" };
  $hash->{bar} = \ $hash;
  $hash->{bazz} = \ $hash;
  weaken( $hash->{bar} );
  my $rebuilt =  $b->_t( $hash );
  ok( isweak( $rebuilt->{bar} ) );
}
