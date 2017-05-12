# -*- perl -*-
use Test::More;
use C::DynaLib;
use C::DynaLib::Struct;

BEGIN {
  eval {
    require Test::Distribution;
  };
  if ($@) {
    plan skip_all => 'Only with Test::Distribution';
  }
  else {
    import Test::Distribution 'not' => [ qw/version podcover/ ];
  }
}
