#!perl
use strict;
use warnings;
use lib ('lib', './t');
use Test::Most;
use TestSettings;
use String::Random;
use Data::Dumper;
use JSON::MaybeXS qw(decode_json);


unless ( $ENV{'AMAZON_DYNAMODB_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 107;
}


my $source_data_filename = 'presidents.json';


if (-r "./t/presidents.json") {
    $source_data_filename = "./t/presidents.json";
}
ok(-r $source_data_filename, "Can open $source_data_filename");

my $fh;
open($fh, "<$source_data_filename") || die("Failed to open $source_data_filename");
my $presidents_data;
{
    local $/ = undef;
    $presidents_data = <$fh>;
}
close($fh);

$presidents_data = decode_json($presidents_data);
ok(defined($presidents_data), "presidents.json was successfully read");


my $ddb = TestSettings::get_ddb();
my $table_name = TestSettings::random_table_name();

{
    my @all_tables;    
    ok($ddb->each_table(
        sub {
            my $table_name =shift;
            push @all_tables, $table_name;
        })->is_done, "List tables is complete");
    bail_on_fail;
    is(scalar(grep { $_ eq $table_name } @all_tables), 0, "New table to create does not exist");
}

my $create = $ddb->create_table(TableName => $table_name,
                                ReadCapacityUnits => 2,
                                WriteCapacityUnits => 2,
                                AttributeDefinitions => {
                                    id => 'N',
                                    college => 'S',
                                    age_at_inauguration => 'N',
                                    state_elected_from => 'S',
                                },
                                KeySchema => ['id'],
                                GlobalSecondaryIndexes => [
                                    {
                                        IndexName => 'CollegeIndex',
                                        KeySchema => ['college'],
                                        Projection => {
                                            ProjectionType => 'ALL',
                                        },
                                        ProvisionedThroughput => {
                                            ReadCapacityUnits => 1,
                                            WriteCapacityUnits => 1,
                                        }
                                    },

                                    {
                                        IndexName => 'StateElectedIndex',
                                        KeySchema => ['state_elected_from'],
                                        Projection => {
                                            NonKeyAttributes => ['name'],
                                            ProjectionType => 'INCLUDE',
                                        },
                                        ProvisionedThroughput => {
                                            ReadCapacityUnits => 1,
                                            WriteCapacityUnits => 1,
                                        }
                                    },
                                    {
                                        IndexName => 'StateElectedAgeIndex',
                                        KeySchema => ['state_elected_from', 'age_at_inauguration'],
                                        Projection => {
                                            NonKeyAttributes => ['name'],
                                            ProjectionType => 'INCLUDE',
                                        },
                                        ProvisionedThroughput => {
                                            ReadCapacityUnits => 1,
                                            WriteCapacityUnits => 1,
                                        }
                                    }
                                ]
                            );

ok($create->is_done, "Create request was completed");

my $wait = $ddb->wait_for_table_status(TableName => $table_name);

ok($wait->is_done, "Created table is ready");



my $id = 1;
my $write = $ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            map {
                {
                    PutRequest => {
                        Item => {
                            id => int($id++),
                            %$_
                        }
                    }
                }
            } @$presidents_data
        ]
    });

ok($write->is_done, "Batch write item successfully completed");


# Give some time for the data to make it everywhere
sleep(5);

# Get the total presidents that have been elected from Virginia

# since we have an index on it we can use query.
{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                   },
                   AttributesToGet => ['name', 'id', 'state_elected_from'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 5, "Correct number of items retrieved from index");
    my @seen_keys = List::MoreUtils::uniq(map { keys %$_ } @found_items);
    is(scalar(@seen_keys), 3, "Total seen keys is only 2");
    eq_or_diff([sort @seen_keys], ['id', 'name', 'state_elected_from'], "requested keys (id,name,state_elected_from) were returned");

    # Validate the presidents are correct.
    my @names = sort { $a cmp $b } ('John Tyler',
                                    'Thomas Jefferson',
                                    'James Madison',
                                    'George Washington',
                                    'James Monroe');

    eq_or_diff([sort map { $_->{name} } @found_items], \@names, "Expected presidents from Virginia were found");
}




{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Montana',
                       },
                   },
                   AttributesToGet => ['name', 'id', 'state_elected_from'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 0, "Correct number of items retrieved from index");
}





# Look at the age index but only query on the state
{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedAgeIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                   },
                   AttributesToGet => ['name', 'id', 'state_elected_from'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 5, "Correct number of items retrieved from index");

    # Validate the presidents are correct.
    my @names = sort { $a cmp $b } ('John Tyler',
                                    'Thomas Jefferson',
                                    'James Madison',
                                    'George Washington',
                                    'James Monroe');

    eq_or_diff([sort map { $_->{name} } @found_items], \@names, "Expected presidents from Virginia were found");
}



{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedAgeIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                       age_at_inauguration => {
                           ComparisonOperator => 'GT',
                           AttributeValueList => 60,
                       }
                   },
                   AttributesToGet => ['name', 'id', 'state_elected_from', 'age_at_inauguration'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 0, "Correct number of items retrieved from index for presidents begin from Virginia and age at inauguration being over 60");

}


{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedAgeIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                       age_at_inauguration => {
                           ComparisonOperator => 'GT',
                           AttributeValueList => 55,
                       }
                   },
                   AttributesToGet => ['name', 'id', 'state_elected_from', 'age_at_inauguration'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    


    # Validate the presidents are correct.
    my @names = sort { $a cmp $b } ('Thomas Jefferson',
                                    'James Madison',
                                    'George Washington',
                                    'James Monroe');

    is(scalar(@found_items), scalar(@names), "Correct number of items retrieved from index for presidents begin from Virginia and age at inauguration being over 55");

    eq_or_diff([sort map { $_->{name} } @found_items], \@names, "Expected presidents from Virginia were found");
}


{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedAgeIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                       age_at_inauguration => {
                           ComparisonOperator => 'BETWEEN',
                           AttributeValueList => [50, 53],
                       }
                   },
                   AttributesToGet => ['name', 'id', 'state_elected_from', 'age_at_inauguration'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    # Validate the presidents are correct.
    my @names = sort ('John Tyler');

    is(scalar(@found_items), scalar(@names), "Correct number of items retrieved from index for presidents begin from Virginia and age between 50 and 53");

    eq_or_diff([sort map { $_->{name} } @found_items], \@names, "Expected presidents from Virginia were found");
}



{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedAgeIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                   },
                   ScanIndexForward => 'true',
                   AttributesToGet => ['age_at_inauguration'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 5, "Correct number of items retrieved from index");


    my @ages = (51, 57, 57, 57, 58);

    eq_or_diff([map { $_->{age_at_inauguration} } @found_items], \@ages, "Expected ages in order of Presidents from Virginia were found");
}


{
    my @found_items;
    ok($ddb->query(sub {
                       my $item = shift;
                       push @found_items, $item;
                   },
                   IndexName => "StateElectedAgeIndex",
                   KeyConditions => {
                       state_elected_from => {
                           ComparisonOperator => 'EQ',
                           AttributeValueList => 'Virginia',
                       },
                   },
                   ScanIndexForward => 'false',
                   AttributesToGet => ['age_at_inauguration'],
                   TableName => $table_name
               )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 5, "Correct number of items retrieved from index");

    my @ages = reverse (51, 57, 57, 57, 58);

    eq_or_diff([map { $_->{age_at_inauguration} } @found_items], \@ages, "Expected ages in order of Presidents from Virginia were found (reverse)");
}




{
    my @found_items;
    ok($ddb->scan(sub {
                      my $item = shift;
                      push @found_items, $item;
                  },
                  AttributesToGet => ['college'],
                  TableName => $table_name
              )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), 44, "Correct number of items retrieved from index to get every state");

    my @unique_colleges = List::MoreUtils::uniq(map { $_->{college} } @found_items);

    is(scalar(@unique_colleges), 24, "Correct number of unique colleges found from index");

    foreach my $college_name (@unique_colleges) {
        
        # Lets use the state_elected_from index to get the presidents.

        my @found_presidents;

        my $query = $ddb->query(sub {
                                    my $item = shift;
                                    push @found_presidents, $item;
                                },
                                IndexName => "CollegeIndex",
                                KeyConditions => {
                                    college => {
                                        ComparisonOperator => 'EQ',
                                        AttributeValueList => $college_name
                                    },
                                },
                                AttributesToGet => ['name'],
                                TableName => $table_name,
                                ReturnConsumedCapacity => 'INDEXES',
                            );


        ok($query->is_done, "Query completed successfully.");

        ok(defined($query->get()->{ConsumedCapacity}), "Got defined consumed capacity");
        ok(scalar(@found_presidents) > 0, "Found atleast one president that went to $college_name");
    }

}

ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");

