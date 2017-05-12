use Test::More;
BEGIN {
  eval {
    require Test::Distribution;
  };
  if($@) {
    plan skip_all => 'Test::Distribution not installed';
  }
  else {
    import Test::Distribution
      distversion => 1,
      not => 'prereq', # Not supported yet by Module::Build
    ;
  }
}
