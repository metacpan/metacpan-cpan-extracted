#!perl -T

use Test::More;

eval "use Test::UseAllModules";
if ($@)
{
    plan skip_all => 'Install Test::UseAllModules to ensure all of the modules load.';
}
all_uses_ok();