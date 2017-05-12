#!perl
use strict;
use warnings;
use lib ('lib', './t');
use Test::Most;
use Test::Differences;
use TestSettings;
use Data::Dumper;

unless ( $ENV{'AMAZON_DYNAMODB_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 2417;
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




    
ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            {
                PutRequest => {
                    Item =>  {
                        user_id => 3000,
                        name => "Test batch write",
                    }
                }
            }
        ]
    })->is_done, "Batch write item successfully completed");

my $returned_item;
ok($ddb->get_item(sub {
                      my $i = shift;
                      $returned_item = $i;
                  },
                  ConsistentRead => 'true',
                  TableName => $table_name,
                  Key => {
                      user_id => 3000
                  },
              )->is_done, "get item completed successfully");

ok(defined($returned_item), "Returned item is defined");
is($returned_item->{user_id}, 3000, "Returned item has the correct user_id");
is($returned_item->{name}, "Test batch write", "Returned item has the correct name");



ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            {
                DeleteRequest => {
                    Key => {
                        user_id => 3000,
                    }
                }
            }
        ]
    })->is_done, "Batch write item with delete successfully completed");

$returned_item = undef;
ok($ddb->get_item(sub {
                   my $i = shift;
                   $returned_item = $i;
               },
                  TableName => $table_name,
                  Key => {
                      user_id => 3000
                  },
              )->is_done, "get item completed successfully");

ok(!defined($returned_item), "Returned item is not defined");



my $batch_size = 800;
my @batch_keys = map { int($_) }(1..$batch_size);

ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            map {
                {
                    PutRequest => {
                        Item => {
                            user_id => $_,
                            email => 'example@test.com',
                        }
                    }
                }
            } @batch_keys
        ]
    })->is_done, "Batch write item $batch_size items to put successfully completed");



my $total_found = 0;
ok($ddb->batch_get_item(
    sub {
        my ($table, $item) = @_;
        is($table, $table_name, "Table name matches for batch get");
        ok($item->{user_id} =~ /^\d+$/, "Key name is an integer");
        is($item->{email}, 'example@test.com', "Email address matches");
        $total_found++;
    },
    RequestItems => {
        $table_name => {
            Keys => [
                map {
                    {
                        user_id => $_
                    } 
                } @batch_keys
            ],
        }
    })->is_done, "Batch get of $batch_size items was successfully completed");

is($total_found, $batch_size, "All batch keys were successfully retrieved");


ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            map {
                {
                    DeleteRequest => {
                        Key => {
                            user_id => $_
                        }
                    }
                }
            } @batch_keys
        ]
    })->is_done, "Batch write item $batch_size items to delete successfully completed");


$total_found = 0;
ok($ddb->batch_get_item(
    sub {
        my ($table, $item) = @_;
        is($table, $table_name, "Table name matches for batch get");
        ok($item->{user_id} =~ /^\d+$/, "Key name is an integer");
        is($item->{email}, 'example@test.com', "Email address matches");
        $total_found++;
    },
    RequestItems => {
        $table_name => {
            Keys => [
                map {
                    {
                        user_id => $_
                    } 
                } @batch_keys
            ],
        }
    })->is_done, "Batch get of $batch_size items was successfully completed");

is($total_found, 0, "No batch keys were successfully retrieved.");

# Now we we wanted to read all of the items it should not get any items.

ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");
