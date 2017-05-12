#!perl
use strict;
use warnings;
use lib ('lib', './t');
use Test::Most;
use Test::Differences;
use Data::Dumper;
use TestSettings;
unless ( $ENV{'AMAZON_DYNAMODB_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 4869;
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



my $test_record = {
                   user_id => 1,
                   name => "Test User"
               };

ok($ddb->put_item(TableName => $table_name,
                  Item => $test_record,
              )->is_done, "Saved test item");

    
ok($ddb->batch_get_item(
    sub {
        my ($table, $item) = @_;
        is($table, $table_name, "Table name matches for batch get");
        is_deeply($test_record, $item, "Retrieved test record successfully");
    },
    RequestItems => {
        $table_name => {
            ConsistentRead => 'true',
            AttributesToGet => ['user_id', 'name'],
            Keys => [
                {
                    user_id => 1,
                },
            ],
        }
    })->is_done, "Batch get was successfully completed");


my $batch_size = 800;

my @all_keys;
for (my $i = 0; $i <= $batch_size; $i++) {
    my $key = int($i);
    push @all_keys, $key;
    $test_record = {
        user_id => int($key),
        test_numbers => [820, 1980],
        name => "Test User - " . $i
    };
    
    ok($ddb->put_item(TableName => $table_name,
                      Item => $test_record,
                  )->is_done, "Saved test item - " . $i . " of $batch_size");
}

my $limited_keys_seen = 0;
ok($ddb->batch_get_item(
    sub {
        my ($table, $item) = @_;
        is($table, $table_name, "Table name matches for batch get");
        ok($item->{user_id} =~ /^\d+$/, "Key name is an integer");
        is_deeply($item->{test_numbers}, [820, 1980], "Number array is correct");
        is($item->{name}, "Test User - " . $item->{user_id}, "User id matches");
        $limited_keys_seen++;
    },
    Limit => 13,
    RequestItems => {
        $table_name => {

            Keys => [
                map {
                    {
                        user_id => $_
                    } 
                } @all_keys,
            ],
        }
    })->is_done, "Batch get was successfully completed");

is($limited_keys_seen, 13, "Limit worked for 13 keys");

my %remaining_keys = map { $_ => 1 } @all_keys;

ok($ddb->batch_get_item(
    sub {
        my ($table, $item) = @_;
        is($table, $table_name, "Table name matches for batch get");
        ok($item->{user_id} =~ /^\d+$/, "Key name is an integer");
        is_deeply($item->{test_numbers}, [820, 1980], "Number array is correct");
        is($item->{name}, "Test User - " . $item->{user_id}, "User id matches");
        ok(defined($remaining_keys{$item->{user_id}}), "Key has not been seen multiple times");
        delete $remaining_keys{$item->{user_id}};
    },
    RequestItems => {
        $table_name => {
            Keys => [
                map {
                    {
                        user_id => $_
                    } 
                } @all_keys,
            ],
        }
    })->is_done, "Batch get was successfully completed");

is(scalar(keys %remaining_keys), 0, "No keys are left remaining to be retrieved.");


ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");
