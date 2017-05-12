#!perl -T
use common::sense;

use lib '..';
use Test::More;

use Coro::Amazon::SimpleDB;
use List::Util qw(first max);


sub untaint {
    my $value = shift;
    my $regexp = shift or die 'regexp required to untaint';
    my @cleaned = $value =~ /$regexp/;
    return @cleaned;
}


sub hash_to_requests {
    my $request_type = shift;
    my %items = @_;
    my @requests = map {
        my $item_name = $_;
        {
            RequestType => $request_type,
            ItemName => $item_name,
            Attribute => [ map { { Name => $_, Value => $items{$item_name}{$_} } } keys %{ $items{$item_name} } ],
        };
    } keys %items;
    return @requests;
}


sub expected_response_types {
    my $responses = shift;
    my $expected_types = shift;
    return (@{$responses} && @{$expected_types}) and not first {
        ref $responses->[$_] ne $expected_types->[$_];
    } $[ .. max($#{$responses}, $#{$expected_types});
}


sub expected_response_type {
    my $responses = shift;
    my $expected_type = shift;
    my $count = shift;
    return expected_response_types($responses, [ map { $expected_type } 1 .. $count ]);
}


my $untaint_regexp = qr{\A ([[:word:]+-]+) : ([[:word:]+-]+) : ([[:word:]+-]+) \z}xms;
my ($key, $secret_key, $domain)
    = untaint join(':', @ENV{qw(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SIMPLEDB_DOMAIN)}), $untaint_regexp;

if ($key and $secret_key and $domain) {
    plan tests => 8;
}
else {
    plan(skip_all => "missing key or domain for live test");
}

my $sdb = Coro::Amazon::SimpleDB->new;
$sdb->aws_access_key($key);
$sdb->aws_secret_access_key($secret_key);
$sdb->domain_name($domain);

# Remove the test domain.  Don't make this a test since it might not
# even be there, so who knows what will happen.  We'll delete this
# domain when we're done with it and we can test things then.
$sdb->async_requests({ RequestType => 'deleteDomain' });


my $results = $sdb->async_requests({ RequestType => 'createDomain' });
ok(
    expected_response_type($results, 'Amazon::SimpleDB::Model::CreateDomainResponse', 1),
    "createDomain",
);


my %items = map { sprintf('item%03d', $_) => { constant => 'mu', num => $_ } } 0..9;

$results = $sdb->async_requests(hash_to_requests(putAttributes => %items));
ok(
    expected_response_type($results, 'Amazon::SimpleDB::Model::PutAttributesResponse', 10),
    "async_requests putAttributes",
);


$results = $sdb->async_get_items(keys %items);
is_deeply($results, \%items, "async_get_items");


$results = $sdb->async_requests(
    {
        RequestType => 'deleteAttributes',
        ItemName => 'item000',
        Attribute => [ { Name => 'constant' }, { Name => 'num' } ],
    },
    {
        RequestType => 'deleteAttributes',
        ItemName => 'item001',
        Attribute => [ { Name => 'constant' } ],
    },
);
ok(
    expected_response_type($results, 'Amazon::SimpleDB::Model::DeleteAttributesResponse', 2),
    "async_requests deleteAttributes",
);

delete $items{item000};
delete $items{item001}{constant};
$results = $sdb->async_get_items(keys %items);
is_deeply($results, \%items, "attributes after async_requests deleteAttributes");


$results = $sdb->async_requests({ RequestType => 'deleteDomain' });
ok(
    expected_response_type($results, 'Amazon::SimpleDB::Model::DeleteDomainResponse', 1),
    "deleteDomain",
);

$results = $sdb->async_requests({ RequestType => 'listDomains' });
ok(
    expected_response_type($results, 'Amazon::SimpleDB::Model::ListDomainResponse', 1),
    "listDomains",
);
ok(
    (! grep { $_ eq $domain } @{ $results->[0]->getListDomainsResult->getDomainName }),
    "test domain deleted",
);


done_testing();
