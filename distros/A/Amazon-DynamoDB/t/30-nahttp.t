#!perl
use strict;
use warnings;
use lib ('lib', './t');
use Test::Most;
use TestSettings;
use String::Random;
use Data::Dumper;
use IO::Async::Loop;
use IO::Async::SSL;

unless ( $ENV{'AMAZON_DYNAMODB_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 7;
}


# Net::Async::HTTP requires the use of an event loop

my $loop = IO::Async::Loop->new();

my $ddb = TestSettings::get_ddb(loop => $loop,
                                implementation => 'Amazon::DynamoDB::NaHTTP');

my $table_name = TestSettings::random_table_name();

{
    my @all_tables;    

    my $each = $ddb->each_table(
        sub {
            my $table_name =shift;
            push @all_tables, $table_name;
        });
    $loop->await($each);
    ok($each->is_done, "List tables is complete");
    bail_on_fail;
    is(scalar(grep { $_ eq $table_name } @all_tables), 0, "New table to create does not exist");
}

my $create = $ddb->create_table(TableName => $table_name,
                                ReadCapacityUnits => 2,
                                WriteCapacityUnits => 2,
                                AttributeDefinitions => {
                                    user_id => 'N',
                                },
                                KeySchema => ['user_id'],
                            );
$loop->await($create);
ok($create->is_done, "Create request was completed");

my $wait = $ddb->wait_for_table_status(TableName => $table_name);
$loop->await($wait);
ok($wait->is_done, "Created table is ready");

{
    my @all_tables;    
    my $each = $ddb->each_table(
        sub {
            my $table_name =shift;
            push @all_tables, $table_name;
        });
    $loop->await($each);
    ok($each->is_done, "List tables is complete");
    is(scalar(grep { $_ eq $table_name } @all_tables), 1, "Newly created table was found");
}


{
    my $delete = $ddb->delete_table(TableName => $table_name);
    $loop->await($delete);
    ok($delete->is_done, "Successfully deleted table named $table_name");    
}


