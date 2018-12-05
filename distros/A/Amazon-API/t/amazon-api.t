# Test Amazon::API 

use Test::More tests => 3;

use Amazon::API;

my $api = eval {
    Amazon::API->new({service_url_base => 'events'});
};

ok(!$@, "constuctor did not throw exception") or diag($@);
ok(defined($api), "constructor returned a value");
isa_ok($api, "Amazon::API");
