use Test::Most;

use Amazon::DynamoDB::Simple;

my $dynamodb = Amazon::DynamoDB::Simple->new(
    table       => 'server_definitions',
    primary_key => 'node',
);

my $node = 'highlyavailable';
my $server_definition = {
    node      => $node,
    flavor    => 'highlyavailable',
    region    => 'highlyavailable',
    zone      => 'highlyavailable',
    hashthing => [{
        a     => 'firstthing',
        b     => 2000,  
        c     => 200,
    }],
};
my $expected_item = {
    %$server_definition,
    last_updated => re(qr/^\d{4}-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}/),
    deleted      => bool(),
};

subtest 'put' => sub {

    $dynamodb->put(%$server_definition);

    my $ddbs = $dynamodb->dynamodbs();

    for my $ddb (@$ddbs) {

        my $host = $ddb->host();
        my $item = $ddb->get_item(
            sub { shift },
            TableName => 'server_definitions',
            Key       => { node => $node },
        )->get();

        cmp_deeply 
            { $dynamodb->inflate(%$item) }, 
            $expected_item,
            "item created on $host";
    }
};

subtest 'get' => sub {

    my %item = $dynamodb->get($node);

    cmp_deeply \%item, $expected_item, 'got item';

    # update item in one region
    my $ddb = $dynamodb->dynamodbs->[1];
    %item = $dynamodb->deflate(
        %$server_definition,
        flavor       => 'highlyavailable2',
        deleted      => 0,
        last_updated => DateTime->now . ""
    );
    $ddb->put_item(
        TableName => 'server_definitions',
        Item      => \%item,
    );

    %item = $dynamodb->get($node);
    is $item{flavor}, 'highlyavailable2', 'got most recent item';
};

subtest 'delete' => sub {
    $dynamodb->delete('boopx1234567890unique');
    $dynamodb->delete($node);

    my $ddbs = $dynamodb->dynamodbs();

    for my $ddb (@$ddbs) {

        my $host = $ddb->host();
        my $item = $ddb->get_item(
            sub { shift },
            TableName => 'server_definitions',
            Key       => { node => $node },
        )->get();

        ok $item->{deleted}, 'item deleted from all locations';
    }
};

done_testing;
