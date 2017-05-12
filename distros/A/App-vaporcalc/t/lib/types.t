use Test::Modern;
use Test::TypeTiny;


use App::vaporcalc::Types -all;

# VaporLiquid
should_pass 'PG',  VaporLiquid;
should_pass 'VG',  VaporLiquid;
should_fail 'foo', VaporLiquid;
should_fail 1,     VaporLiquid;

# CommandAction
should_pass 'display', CommandAction;
should_pass 'print',   CommandAction;
should_pass 'prompt',  CommandAction;
should_pass 'next',    CommandAction;
should_pass 'last',    CommandAction;
should_pass 'recipe',  CommandAction;
should_fail 'foo',     CommandAction;
should_fail [],        CommandAction;

# Percentage
should_pass 100, Percentage;
should_pass 0,   Percentage;
should_pass 0.5, Percentage;
should_pass 50,  Percentage;
should_fail 101, Percentage;
should_fail -1,  Percentage;

# RoundedResult
should_pass 1,    RoundedResult;
should_pass 1.1,  RoundedResult;
should_fail 1.11, RoundedResult;
ok RoundedResult->coerce(1.11) == 1.1, 'RoundedResult coerced ok';

my $foo = [];

# AppException
bless $foo, 'App::vaporcalc::Exception';
should_pass $foo, AppException;
should_fail [],   AppException;

# FlavorObject
bless $foo, 'App::vaporcalc::Flavor';
should_pass $foo, FlavorObject;
should_fail [], FlavorObject;
my %settings = (
  percentage => 20, type => 'PG', tag => 'foo'
);
my $flav = FlavorObject->coerce(\%settings);
ok $flav->percentage == 20, 'FlavorObject coerced ok';
ok $flav->tag eq 'foo',     'FlavorObject coerced ok';

# RecipeObject
bless $foo, 'App::vaporcalc::Recipe';
should_pass $foo, RecipeObject;
should_fail [],   RecipeObject;
%settings = (
  target_quantity   => 10, base_nic_per_ml => 100,
  target_nic_per_ml => 12, target_pg => 65, target_vg => 35,
  flavor_array => [
    +{ percentage => 20, tag => 'foo' }
  ],
);
my $recipe = RecipeObject->coerce(\%settings);
ok $recipe->target_quantity == 10, 'RecipeObject coerced ok';
ok $recipe->flavor_array->count == 1, 'flavor_array coerced ok';

# ResultObject
bless $foo, 'App::vaporcalc::Result';
should_pass $foo, ResultObject;
should_fail [],   ResultObject;
%settings = (
  pg => 2, vg => 2, flavors => +{ foo => 2 }, nic => 2
);
my $result = ResultObject->coerce(\%settings);
ok $result->pg == 2, 'ResultObject coerced ok';
ok $result->vg == 2;
ok $result->flavor_total == 2;

# RecipeResultSet
bless $foo, 'App::vaporcalc::RecipeResultSet';
should_pass $foo, RecipeResultSet;
should_fail [],   RecipeResultSet;

done_testing
