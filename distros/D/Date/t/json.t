use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

plan skip_all => 'JSON::XS required for this test' unless eval { require JSON::XS; 1};

my $json = JSON::XS->new->utf8->convert_blessed;

my $date = date("2012-01-01 15:16:17");

my $serialized = $json->encode({date => $date});
is($serialized, '{"date":1325416577}');

done_testing();
