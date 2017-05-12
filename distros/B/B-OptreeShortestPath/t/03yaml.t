use Test::More;
eval "use YAML qw( LoadFile )";
if ($@) {
    plan( skip_all => "YAML required to test META.yml's syntax" );
}
else {
    plan( tests => 1 );
    ok( LoadFile("META.yml") );
}
