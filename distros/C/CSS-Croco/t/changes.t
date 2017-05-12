use Test::More;
eval "use Test::CheckChanges;1" or plan skip_all => "Test::CheckChanges is required";
ok_changes();
