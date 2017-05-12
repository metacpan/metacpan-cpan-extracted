use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok( "Bio::Gonzales::Util", "undef_slice", "slice" ); }

my %hash = (
  a => 1,
  b => 2,
  c => 3,
);

{
  my $new_hash = slice( \%hash, qw/a b D/ );
  is_deeply( $new_hash, { a => 1, b => 2 } );
}
{
  my $new_hash = undef_slice( \%hash, qw/a b D/ );
  is_deeply( $new_hash, { a => 1, b => 2, D => undef } );
}

done_testing();

