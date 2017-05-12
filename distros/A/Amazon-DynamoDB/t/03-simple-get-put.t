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
    plan tests => 84;
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


my $source_data = {
    email => 'test@example.com',
    user_id => 1,
    name => 'Rusty Conover',
    names => ['R. Conover', 'Rusty Conover'],
    numbers => [1, 3, 5, 5.002],
    numbers_and_strings => [1, 3, 5, "5.002.3.2.3"],
    test_binary => \'Rusty Conover',
    test_binary_array => [\'rusty', \'conover'],
};


{
    my $put = $ddb->put_item(TableName => $table_name,
                             Item => $source_data);
    ok($put->is_done, "put_item completed successfully");
    is_deeply($put->get(), {}, "Results of put_item with no attributes returned didn't return any.");
}


{
    my $put = $ddb->put_item(TableName => $table_name,
                             ReturnItemCollectionMetrics => 'SIZE',
                             Item => $source_data);
    ok($put->is_done, "put_item completed successfully");
    is_deeply($put->get(), {}, "Results of put_item with no attributes returned didn't return any.");
}



{
    my $found_item;
    my $get = $ddb->get_item(
        sub {
            $found_item = shift;
        },
        TableName => $table_name,
        Key => {
            user_id => $source_data->{user_id}
        });
    ok($get->is_done, "get_item completed ok");
    ok(defined($found_item), "an item was retrieved");


    is($found_item->{email}, $source_data->{email},"Email matches");
    is($found_item->{name}, $source_data->{name}, "Name matches");
    is(${$found_item->{test_binary}}, ${$source_data->{test_binary}}, "Binary string matches");
    is($found_item->{user_id}, $source_data->{user_id}, "User id matches");
    
    eq_or_diff([sort @{$source_data->{numbers}}],
               [sort @{$found_item->{numbers}}], "Number array matches");
    
    
    eq_or_diff([sort map { $$_ } @{$source_data->{test_binary_array}}],
               [sort map { $$_ } @{$found_item->{test_binary_array}}], "Binary array matches");
    
    
    eq_or_diff([sort @{$source_data->{numbers_and_strings}}],
               [sort @{$found_item->{numbers_and_strings}}], "Numbers and strings in array match");
}

{
    my $delete = $ddb->delete_item(
        TableName => $table_name,
        Key => {
            user_id => $source_data->{user_id}
        });
    ok($delete->is_done, "delete_item completed ok");
    is_deeply($delete->get, {}, "Delete result is empty with no requested attributes");
}


{
    my $found_item;
    my $get = $ddb->get_item(
        sub {
            $found_item = shift;
        },
        TableName => $table_name,
        Key => {
            user_id => $source_data->{user_id}
        });
    ok($get->is_done, "get_item completed ok:" . Data::Dumper->Dump([$get]));
    ok(!defined($found_item), "an item was not retrieved");
}

# test delete with retrieving the attributes
{
    my $put = $ddb->put_item(TableName => $table_name,
                             Item => $source_data);
    ok($put->is_done, "put_item completed successfully");
    is_deeply($put->get(), {}, "Results of put_item with no attributes returned didn't return any.");
}

{
    my $found_item;
    my $get = $ddb->get_item(
        sub {
            $found_item = shift;
        },
        TableName => $table_name,
        Key => {
            user_id => $source_data->{user_id}
        });
    ok($get->is_done, "get_item completed ok");
    ok(defined($found_item), "an item was retrieved");

    is($found_item->{email}, $source_data->{email},"Email matches");
    is($found_item->{name}, $source_data->{name}, "Name matches");
    is(${$found_item->{test_binary}}, ${$source_data->{test_binary}}, "Binary string matches");
    is($found_item->{user_id}, $source_data->{user_id}, "User id matches");
    
    eq_or_diff([sort @{$source_data->{numbers}}],
               [sort @{$found_item->{numbers}}], "Number array matches");
    
    
    eq_or_diff([sort map { $$_ } @{$source_data->{test_binary_array}}],
               [sort map { $$_ } @{$found_item->{test_binary_array}}], "Binary array matches");
    
    
    eq_or_diff([sort @{$source_data->{numbers_and_strings}}],
               [sort @{$found_item->{numbers_and_strings}}], "Numbers and strings in array match");

}

{
    my $delete = $ddb->delete_item(
        TableName => $table_name,
        Key => {
            user_id => $source_data->{user_id}
        },
        ReturnValues => 'ALL_OLD'
    );
    ok($delete->is_done, "delete_item completed ok");

    my $found_item = $delete->get()->{Attributes};
    ok(defined($found_item), "Got attributes form delete_item");

    is($found_item->{email}, $source_data->{email},"Email matches");
    is($found_item->{name}, $source_data->{name}, "Name matches");
    is(${$found_item->{test_binary}}, ${$source_data->{test_binary}}, "Binary string matches");
    is($found_item->{user_id}, $source_data->{user_id}, "User id matches");
    
    eq_or_diff([sort @{$source_data->{numbers}}],
               [sort @{$found_item->{numbers}}], "Number array matches");
    
    
    eq_or_diff([sort map { $$_ } @{$source_data->{test_binary_array}}],
               [sort map { $$_ } @{$found_item->{test_binary_array}}], "Binary array matches");
    
    
    eq_or_diff([sort @{$source_data->{numbers_and_strings}}],
               [sort @{$found_item->{numbers_and_strings}}], "Numbers and strings in array match");


}


{
    my $found_item;
    my $get = $ddb->get_item(
        sub {
            $found_item = shift;
        },
        TableName => $table_name,
        Key => {
            user_id => $source_data->{user_id}
        });
    ok($get->is_done, "get_item completed ok");
    ok(!defined($found_item), "an item was not retrieved");
}


{
    my $found_item;
    my $diff_id = $source_data->{user_id} - 1;
    my $get = $ddb->get_item(
        sub {
            $found_item = shift;
        },
        TableName => $table_name,
        Key => {
            user_id => $diff_id
        });
    ok($get->is_done, "get_item completed ok");
    ok(!defined($found_item), "an item was not retrieved with id: $diff_id");
}


{
    my $custom = {
        user_id => 2,
        name => 'Rusty Conover~2'
    };
    
    {
        my $put = $ddb->put_item(TableName => $table_name,
                                 Item => $custom);
        ok($put->is_done, "put_item with custom definition completed successfully");
        is_deeply($put->get(), {}, "Results of put_item with no attributes returned didn't return any.");
    }


    {
        my $put = $ddb->put_item(TableName => $table_name,
                                 Item => {
                                     %$custom,
                                     name => 'Rusty Conover~3'
                                 },
                                 ReturnValues => 'ALL_OLD');
        ok($put->is_done, "put_item with custom definition completed successfully");
        eq_or_diff($put->get()->{Attributes}, 
                   {
                       %$custom,
                       name => 'Rusty Conover~2'
                   }, "Found old values in expected result from put_item");
    }
}

{
    my $delete = $ddb->delete_item(
        TableName => $table_name,
        Key => {
            user_id => 2,
        });
    ok($delete->is_done, "delete_item completed ok");
    is_deeply($delete->get, {}, "Delete result is empty with no requested attributes");
}

{
    my $found_item;
    my $get = $ddb->get_item(
        sub {
            $found_item = shift;
        },
        TableName => $table_name,
        Key => {
            user_id => 2,
        });
    ok($get->is_done, "get_item completed ok");
    ok(!defined($found_item), "an item was not retrieved with id: 2");
}


{
    my $put = $ddb->put_item(TableName => $table_name,
                             Item => {
                                 user_id => 2,
                                 name => 'Rusty Conover-2',
                                 test_numbers => [500, 600, 800],
                                 added_number => 1000,
                                 favorite_color => 'blue',
                                 subtracted_number => 1000,
                             });
    ok($put->is_done, "Put item completed successfully");
    is_deeply($put->get(), {}, "Results of put_item with no attributes returned correctly");
}



{
    my $update = $ddb->update_item(
        TableName => $table_name,
        Key => {
            user_id => 2
        },
        AttributeUpdates => {
            name => {
                Action => 'PUT',
                Value => "Rusty Conover-3",
            },
            favorite_color => {
                Action => 'DELETE'
            },
            test_numbers => {
                Action => 'DELETE',
                Value => [500]
            },
            added_number => {
                Action => 'ADD',
                Value => 5,
            },
            subtracted_number => {
                Action => 'ADD',
                Value => -5,
            },
            new_string_set => {
                Action => 'ADD',
                Value => ['Hello', 'Rusty']
            },
            
            new_number_set => {
                Action => 'ADD',
                Value => [1]
            },
            
            new_binary_set => {
                Action => 'ADD',
                Value => [\'hello', \'world']
            },
        });
    ok($update->is_done, "update_item was successful");
    is_deeply($update->get(), {}, "update_item returned not attributes when not requested");
}


{
    my $found_item;
    ok($ddb->get_item(sub {
                          $found_item = shift;
                      },
                      TableName => $table_name,
                      Key => {
                          user_id => 2
                      }
                  )->is_done, "Updated item retrieved");
    
    ok(defined($found_item), "Updated item was successfully retrieved");
    is($found_item->{user_id}, 2, "user_id is 2");
    is($found_item->{name}, "Rusty Conover-3", "updated name is found");
    is($found_item->{added_number}, 1005, "updated added_number is mathematically added");
    is($found_item->{subtracted_number}, 995, "updated subtracted_number is mathematically added");
    ok(!defined($found_item->{favorite_color}), "updated favorite_color is undefined, since it was deleted");
    eq_or_diff([600, 800],
               [sort @{$found_item->{test_numbers}}], "Deleted Number array matches");
    
    
    eq_or_diff([1],
               [sort @{$found_item->{new_number_set}}], "New number set matches");
    
    eq_or_diff(['Hello', 'Rusty'],
               [sort @{$found_item->{new_string_set}}], "New string set matches");
    
    eq_or_diff(['hello', 'world'],
               [sort map { $$_ } @{$found_item->{new_binary_set}}], "New binary set matches");
}



ok($ddb->delete_item(TableName => $table_name,
                     Key => {
                         user_id => 2,
                     })->is_done, "Deleted custom item");


# Create an item then lets play with the exists rules and check for updates.

{
    my $put = $ddb->put_item(TableName => $table_name,
                             Item => {
                                 user_id => 3,
                                 name => 'Rusty',
                             });
    ok($put->is_done, "Put item completed successfully");
}



# only update if the name of user_id 3 is Fred.
{
    my $update = $ddb->update_item(
        TableName => $table_name,
        Key => {
            user_id => 3,
        },
        AttributeUpdates => {
            name => {
                Action => 'PUT',
                Value => "R2D2",
            },
        },
        Expected => {
            name => {
                Value => "Fred",
            },
        }
    );
    ok(!$update->is_done, "update_item was failed");

    is($update->failure()->{type}, "ConditionalCheckFailedException", "update_item failed with ConditionalCheckFailedException exception as expected");
}


{
    my $update = $ddb->update_item(
        TableName => $table_name,
        Key => {
            user_id => 3,
        },
        AttributeUpdates => {
            name => {
                Action => 'PUT',
                Value => "R2D2",
            },
        },
        Expected => {
            name => {
                ComparisonOperator => 'EQ',
                AttributeValueList => 'Fred',
            },
        }
    );
    ok(!$update->is_done, "update_item was failed");

    is($update->failure()->{type}, "ConditionalCheckFailedException", "update_item failed with ConditionalCheckFailedException exception as expected when using comparison operator EQ");
}


{
    my $update = $ddb->update_item(
        TableName => $table_name,
        Key => {
            user_id => 3,
        },
        AttributeUpdates => {
            name => {
                Action => 'PUT',
                Value => "R2D2",
            },
        },
        Expected => {
            name => {
                ComparisonOperator => 'IN',
                AttributeValueList => ['Fred'],
            },
        }
    );
    ok(!$update->is_done, "update_item was failed");

    is($update->failure()->{type}, "ConditionalCheckFailedException", "update_item failed with ConditionalCheckFailedException exception as expected when using comparison operator IN");
}



{
    my $found_item;
    ok($ddb->get_item(sub {
                          $found_item = shift;
                      },
                      TableName => $table_name,
                      Key => {
                          user_id => 3,
                      }
                  )->is_done, "Updated item retrieved");
    
    ok(defined($found_item), "Updated item was successfully retrieved");
    is($found_item->{user_id}, 3, "user_id is 3");
    is($found_item->{name}, "Rusty", "non updated name is found");
}


{
    my $update = $ddb->update_item(
        TableName => $table_name,
        Key => {
            user_id => 3,
        },
        AttributeUpdates => {
            name => {
                Action => 'PUT',
                Value => "R2D2",
            },
        },
        Expected => {
            name => {
                Value => "Rusty",
                Exists => 'true',
            },
            email => {
                Exists => 'false'
            }
        }
    );
    ok($update->is_done, "update_item was successful");
}

{
    my $found_item;
    ok($ddb->get_item(sub {
                          $found_item = shift;
                      },
                      TableName => $table_name,
                      Key => {
                          user_id => 3,
                      }
                  )->is_done, "Updated item retrieved");
    
    ok(defined($found_item), "Updated item was successfully retrieved");
    is($found_item->{user_id}, 3, "user_id is 3");
    is($found_item->{name}, "R2D2", "updated name is found");
}


ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");
