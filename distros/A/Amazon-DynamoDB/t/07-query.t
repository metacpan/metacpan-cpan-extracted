#!perl
use strict;
use warnings;
use lib ('lib', './t');
use Test::Most;
use Test::Differences;
use List::MoreUtils;
use Data::Dumper;
use TestSettings;

unless ( $ENV{'AMAZON_DYNAMODB_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 10;
}

bail_on_fail;

my $ddb = TestSettings::get_ddb();
my $table_name = TestSettings::random_table_name();


my $create = $ddb->create_table(TableName => $table_name,
                                ReadCapacityUnits => 2,
                                WriteCapacityUnits => 2,
                                AttributeDefinitions => {
                                    user_id => 'N',
                                },
                                KeySchema => ['user_id'],
                            );

ok($create->is_done, "Create request was completed");

my $wait = $ddb->wait_for_table_status(TableName => $table_name);

ok($wait->is_done, "Created table is ready");



my @put_items = map {
    my $r = {
        user_id => int($_),
        name => "Test record: " . $_,
    } ;
} (1..10);
    
ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            map {
                {
                    PutRequest => { Item => $_ }
                }
            } @put_items
        ]
    })->is_done, "Batch write item successfully completed");


{
    my $query = $ddb->query(sub {},
                            TableName => $table_name,
                            Select => 'COUNT',
                            KeyConditions => {
                                user_id => {
                                    ComparisonOperator => 'EQ',
                                    AttributeValueList => 1,
                                }
                            }
                        );
    ok($query->is_done, "Query for count completed");
    is($query->get()->{Count}, 1, "Query count is right");
}


{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   KeyConditions => {
                       user_id => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 1,
                       },
                   },
                   AttributesToGet => ['user_id'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    
    is(scalar(@found_items), 1, "Correct number of items retrieved from table on primary key");
    my @seen_keys = List::MoreUtils::uniq(map { keys %$_ } @found_items);
    is(scalar(@seen_keys), 1, "Total seen keys is only 1");
    is($seen_keys[0], "user_id", "Only user_id was returned");
}


ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");
