use Test::More qw( no_plan );
use warnings;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for POD coverage" if $@;

#all_pod_coverage_ok();

my $trustme = { trustme => [ qr/^check/ ] };


pod_coverage_ok( 'Authen::Tcpdmatch::TcpdmatchRD', $trustme );
