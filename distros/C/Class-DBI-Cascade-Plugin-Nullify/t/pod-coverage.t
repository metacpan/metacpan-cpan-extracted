use Test::More;
eval "use Test::Pod::Coverage 0.02";
plan skip_all => "Test::Pod::Coverage 0.02 required for testing POD
coverage" if $@;

plan tests => 1;

my $params = { trustme => [qr/^(?:cascade)$/] };

pod_coverage_ok('Class::DBI::Cascade::Plugin::Nullify', $params);