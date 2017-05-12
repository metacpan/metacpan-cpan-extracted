#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 1;
my $trustme = { trustme => [qr/^(?:handle|components|has_param)$/] };
pod_coverage_ok( "Class::CGI::DateTime", $trustme );
