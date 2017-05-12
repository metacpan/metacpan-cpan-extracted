use Test::More;
eval "use Test::Dependencies exclude => ['Data::OpenStruct::Deep']";
plan skip_all => "Test::Dependencies required for testing dependencies" if $@;
ok_dependencies();
