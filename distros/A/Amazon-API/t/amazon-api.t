# Test Amazon::API 

use Test::More tests => 1;

use Amazon::API;

sub get_aws_secret_access_key  { return 'key' };
sub get_aws_access_key_id { return 'secret' };

my $api = eval {
    Amazon::API->new({service_url_base => 'events', credentials => main });
};

isa_ok($api, "Amazon::API");
