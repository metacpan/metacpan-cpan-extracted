use Test::More;

eval 'require Test::Distribution';
plan( skip_all => 'Test::Distribution is not installed' ) if $@;
Test::Distribution->import();

