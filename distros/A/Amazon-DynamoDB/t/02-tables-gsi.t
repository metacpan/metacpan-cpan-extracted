#!perl
use strict;
use warnings;
use lib ('lib', './t');
use Test::Most;
use TestSettings;
use String::Random;
use Data::Dumper;

unless ( $ENV{'AMAZON_DYNAMODB_EXPENSIVE_TESTS'} ) {
    plan skip_all => 'Testing this module for real costs money.';
} else {
    plan tests => 9;
}

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
                                    user_id => 'N',
                                    email => 'S'
                                },
                                KeySchema => ['user_id'],
                                GlobalSecondaryIndexes => [
                                    {
                                        IndexName => 'EmailIndex',
                                        KeySchema => ['email'],
                                        Projection => {
                                            ProjectionType => 'KEYS_ONLY',
                                        },
                                        ProvisionedThroughput => {
                                            ReadCapacityUnits => 2,
                                            WriteCapacityUnits => 2,
                                        }
                                    }
                                ]
                            );

ok($create->is_done, "Create request was completed");

my $wait = $ddb->wait_for_table_status(TableName => $table_name);

ok($wait->is_done, "Created table is ready");


my $description = $ddb->describe_table(TableName => $table_name);

ok($description->is_done, "Successfully described table");



$description = $description->get();

# Creation times always change.
delete $description->{CreationDateTime};

is_deeply($description, 
          {
              'TableSizeBytes' => 0,
              'ItemCount' => 0,
              'GlobalSecondaryIndexes' => [
                  {
                      'IndexName' => 'EmailIndex',
                      'KeySchema' => [
                          {
                              'KeyType' => 'HASH',
                              'AttributeName' => 'email'
                          }
                      ],
                      'ItemCount' => 0,
                      'IndexSizeBytes' => 0,
                      'Projection' => {
                          'ProjectionType' => 'KEYS_ONLY'
                      },
                      'ProvisionedThroughput' => {
                          'ReadCapacityUnits' => 2,
                          'WriteCapacityUnits' => 2,
                          'NumberOfDecreasesToday' => 0,
                      },
                      'IndexStatus' => 'ACTIVE'
                  }
              ],
              'AttributeDefinitions' => [
                  {
                      'AttributeType' => 'S',
                      'AttributeName' => 'email'
                  },
                  {
                      'AttributeType' => 'N',
                      'AttributeName' => 'user_id'
                  }
              ],
              'KeySchema' => [
                  {
                      'KeyType' => 'HASH',
                      'AttributeName' => 'user_id'
                  }
              ],
              'TableName' => $table_name,
              'ProvisionedThroughput' => {
                  'ReadCapacityUnits' => 2,
                  'NumberOfDecreasesToday' => 0,
                  'WriteCapacityUnits' => 2,
              },
              'TableStatus' => 'ACTIVE'
          }, "Table was correctly defined and described");

{
    my @all_tables;    
    ok($ddb->each_table(
        sub {
            my $table_name =shift;
            push @all_tables, $table_name;
        })->is_done, "List tables is complete");
    
    is(scalar(grep { $_ eq $table_name } @all_tables), 1, "Newly created table was found");
}

ok($ddb->delete_table(TableName => $table_name)->is_done, "Successfully deleted table named $table_name");

