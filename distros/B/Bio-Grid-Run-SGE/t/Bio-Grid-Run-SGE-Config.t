use warnings;
use Test::More;
use Data::Dumper;

BEGIN { use_ok('Bio::Grid::Run::SGE::Config'); }

{
  my $c = { test => 3, unknown_attr1 => 1, unknown_attr2 => 2, mode => 'Dummy' };
  Bio::Grid::Run::SGE::Config->_unknown_attrs_to_extra($c);
  my $e = $c->{extra};
  is_deeply(
    $c,
    {
      'test' => 3,
      'mode' => 'Dummy',
      extra => {
        unknown_attr1 => 1,
        unknown_attr2 => 2,
      },
    },
    "configuration without unknown attributes"
  );
  is_deeply(
    $e,
    {
      'unknown_attr1' => 1,
      'unknown_attr2' => 2
    },
    "extra with unknown attributes"
  );
}

done_testing();

