use Test::More;
eval "use Test::Pod::Coverage 0.06";
plan skip_all => "Test::Pod::Coverage 0.06 required for testing POD coverage" if $@;

plan tests=>1;

pod_coverage_ok( "CGI::Untaint::zipcode" );
