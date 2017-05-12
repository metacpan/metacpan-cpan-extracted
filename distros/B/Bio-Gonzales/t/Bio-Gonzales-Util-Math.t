use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok( 'Bio::Gonzales::Util::Math', 'shuffle' ); }

my %h = ( a => 1, b => 2, d => 3, e => 4, f => 5, g => 6, h => 7, i => 8, j => 9, k => 10 );

my %sum;
my $samples = 100000;
for ( my $i = 0; $i < $samples; $i++ ) {
  my $s = shuffle( \%h );
  while ( my ( $k, $v ) = each %$s ) {
    $sum{$k} += $v;
  }
}

# with uniform sampling we should arrive at 5.5 for every key
while ( my ( $k, $v ) = each %sum ) {
  ok( abs( $sum{$k} / $samples - 5.5 ) < 0.1 );
}

done_testing();

