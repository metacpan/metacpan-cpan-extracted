# Optional tests if Types::Standard installed
use Test::More;
use lib ".";

eval ("use Types::Standard -all");
if (! $@){
    require t::TestTypesStandard;
}
else {
    plan skip_all => "Types::Standard tests skipped. Module not installed";
}

done_testing;
