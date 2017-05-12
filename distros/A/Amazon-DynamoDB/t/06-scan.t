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
    plan tests => 40;
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
        name => "Test batch write - " . $_,
    } ;
} (1..10);
    
ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            map {
                { PutRequest => { Item => $_ } }
            } @put_items
        ]
    })->is_done, "Batch write item successfully completed with " . scalar(@put_items) . " written");


{
    my $scan_future = $ddb->scan(sub {},
                                 TableName => $table_name,
                                 Select => 'COUNT',
                             );
    ok($scan_future->is_done, "Scan for count completed");
    is($scan_future->get()->{Count}, scalar(@put_items), "Scan count is right");
    is($scan_future->get()->{ScannedCount}, scalar(@put_items), "Scanned count is right");
}


{
    my @should_find = grep { $_->{user_id} > 5 } @put_items;
    my $scan_future = $ddb->scan(sub {},
                                 TableName => $table_name,
                                 Select => 'COUNT',
                                 ScanFilter => {
                                     user_id => {
                                         ComparisonOperator => 'GT',
                                         AttributeValueList => 5,
                                     }
                                 }
                             );
    ok($scan_future->is_done, "Scan for count completed");
    is($scan_future->get()->{Count}, scalar(@should_find), "Scan count is right");
    is($scan_future->get()->{ScannedCount}, scalar(@put_items), "Scanned count is right (should be all records)");
}


# Limit is the number of items examined per call, not a total limit on the number of rows to retrieve.
{

    my $limit = int(scalar(@put_items)/3);
    my @found_items;
    ok($ddb->scan(
        sub {
            my $item = shift;
            push @found_items, $item;
        },
        Limit => $limit,
        AttributesToGet => ['user_id'],
        TableName => $table_name
    )->is_done, "Scan completed successfully.");
    
    is(scalar(@found_items), scalar(@put_items), "Equal number of items retrieved from table as were put");
    my @seen_keys = List::MoreUtils::uniq(map { keys %$_ } @found_items);
    is(scalar(@seen_keys), 1, "Total seen keys is only 1");
    is($seen_keys[0], "user_id", "Only user_id was returned");
}

{
    my @found_items;
    ok($ddb->scan(sub {
                      my $item = shift;
                      push @found_items, $item;
                  },
                  TableName => $table_name
              )->is_done, "Scan completed successfully.");
    
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@put_items), "Equal number of items retrieved from table as were put");
    is_deeply(\@found_items, \@put_items, "All items are correctly returned");
}


{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            ScanFilter => {
                user_id => {
                    ComparisonOperator => 'GT',
                    AttributeValueList => 5,
                }
            }
        )->is_done, "Scan completed successfully.");
    
    my @check_items = grep { $_->{user_id} > 5 } @put_items;
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@check_items), "Correct number of items were returned");
    is_deeply(\@found_items, \@check_items, "All items are correctly returned with filter");
}


{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            ScanFilter => {
                user_id => {
                    ComparisonOperator => 'IN',
                    AttributeValueList => [2,4,8],
                }
            }
        )->is_done, "Scan completed successfully.");
    
    my @check_items = grep { $_->{user_id} == 2 || 
                                 $_->{user_id} == 4 ||
                                     $_->{user_id} == 8
                         } @put_items;
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@check_items), "Correct number of items were returned");
    is_deeply(\@found_items, \@check_items, "All items are correctly returned with IN filter");
}



{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            Limit => 3,
        )->is_done, "Scan completed successfully.");
    is(scalar(@found_items), 3, "Correct number of items were returned with limit");
}


{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            Limit => 30000,
        )->is_done, "Scan completed successfully.");
    is(scalar(@found_items), scalar(@put_items), "Correct number of items were returned with limit greater than the total number of records");
}




{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            ScanFilter => {
                user_id => {
                    ComparisonOperator => 'IN',
                    AttributeValueList => 8,
                }
            }
        )->is_done, "Scan completed successfully.");
    
    my @check_items = grep {
        $_->{user_id} == 8
    } @put_items;
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@check_items), "Correct number of items were returned");
    is_deeply(\@found_items, \@check_items, "All items are correctly returned with IN filter");
}





{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            ScanFilter => {
                user_id => {
                    ComparisonOperator => 'BETWEEN',
                    AttributeValueList => [2,4],
                }
            }
        )->is_done, "Scan completed successfully.");
    
    my @check_items = grep { $_->{user_id} >= 2 && $_->{user_id} <= 4 } @put_items;
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@check_items), "Correct number of items were returned");
    is_deeply(\@found_items, \@check_items, "All items are correctly returned with BETWEEN filter");
}



{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name,
            ScanFilter => {
                user_id => {
                    ComparisonOperator => 'NOT_NULL',
                }
            }
        )->is_done, "Scan completed successfully.");
    
    my @check_items = grep { defined($_->{user_id}) } @put_items;
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@check_items), "Correct number of items were returned");
    is_deeply(\@found_items, \@check_items, "All items are correctly returned with NOT_NULL filter");
}


my $large_size = 500;

@put_items = map {
    my $r = {
        user_id => int($_),
        name => "Test batch write - " . $_,
    } ;
} (1..$large_size);

ok($ddb->batch_write_item(
    RequestItems => {
        $table_name => [
            map {
                { PutRequest => { Item => $_ } }
            } @put_items
        ]
    })->is_done, "Batch write " . scalar(@put_items) . " items successfully completed");



{
    my @found_items;
    ok(
        $ddb->scan(
            sub {
                my $item = shift;
                push @found_items, $item;
            },
            TableName => $table_name
        )->is_done, "Scan completed successfully.");
    
    @found_items = sort { $a->{user_id} <=> $b->{user_id} } @found_items;
    
    is(scalar(@found_items), scalar(@put_items), "Equal number of items retrieved from table as were put");
    is_deeply(\@found_items, \@put_items, "All items are correctly returned");
}


ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");
