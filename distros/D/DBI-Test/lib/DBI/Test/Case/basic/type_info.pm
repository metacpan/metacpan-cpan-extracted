use strict;
use warnings;
use Test::More;

our @DB_CREDS = ('dbi:SQLite::memory:', undef, undef, {});

# NOTES: This test is a draft. Need to figure out several things.
# TODO : We should implement stricter tests for the datastructure keys

my @required_keys = qw(
TYPE_NAME DATA_TYPE COLUMN_SIZE
LITERAL_PREFIX LITERAL_SUFFIX
CREATE_PARAMS NULLABLE CASE_SENSITIVE
SEARCHABLE UNSIGNED_ATTRIBUTE FIXED_PREC_SCALE
AUTO_UNIQUE_VALUE LOCAL_TYPE_NAME MINIMUM_SCALE
MAXIMUM_SCALE SQL_DATA_TYPE SQL_DATETIME_SUB
NUM_PREC_RADIX INTERVAL_PRECISION );

my $dbh = DBI->connect( @DB_CREDS );
isa_ok($dbh, 'DBI::db');

{ #Checks that type_info returns a list of hashrefs containing the correct keys
  # if the method is called without arguments
  my @data_without_args = $dbh->type_info(); #No argument should be passed
  test_type_info( @data_without_args ); 
}

{ #Check that type_info() returns the same with no arguments as with argument SQL_ALL_TYPES
  
  #TODO import DBI constants
  my @data_with_args = $dbh->type_info( DBI::SQL_ALL_TYPES );
  
  test_type_info(@data_with_args);
  
  #To be sure, match the two datastructures
  my @data_without_args = $dbh->type_info();
  is_deeply(\@data_without_args, \@data_with_args, "Calling type_info without and with argument is equal");
}

{ #If type_info is called with an arrayref as an argument, it should return
  # the information from the first type in the array that has any matches  
  TODO : {
    local $TODO = 'Need to check that $sql_timestamp_type is correct';
    my $sql_timestamp_type = $dbh->type_info( [ 99999, DBI::SQL_TIMESTAMP ] ); #99999 is a chosen number that hopefully is not defined by a DBI constant
  }
}


sub test_type_info{
  my @type_info_data = @_;
  
  #Check that each element in the array is a hashref with the correct keys
  for( my $i = 0; $i < scalar(@type_info_data); $i++){
    my $element = $type_info_data[$i];
    
    cmp_ok(ref($element), 'eq', 'HASH', 'Element #' . $i . ' is a hashref');
    
    #Testing that we have the required hashkeys
    ok(exists $element->{$_}, 'Element #' . $i . ' has key ' . $_) for(@required_keys);
    
    #Check the TYPE_NAME
    # TODO : Implement some sort of more specific check. Can we produce a list of valid TYPE_NAMES?
    
    #Check that DATA_TYPE has a valid integer value or undef
    #TODO : This should be checked against DBI constant or something?
    ok( !defined $element->{DATA_TYPE} || $element->{DATA_TYPE} =~ m/^\d+$/, 'DATA_TYPE is an integer');
    
    #Check that COLUMN_SIZE is an integer or undef
    ok( !defined $element->{COLUMN_SIZE} || $element->{COLUMN_SIZE} =~ m/^\d+$/, 'COLUMN_SIZE is an integer');
        
    # TODO: Create a stricter test for this key
    
    #Check that NULLABLE is 0, empty string, 1 or 2
    # Valid values are:
    # undef - not set by the DBD
    # 0 or an empty string = no
    # 1 = yes
    # 2 = unknown
    ok(
      !defined $element->{NULLABLE} ||
      $element->{NULLABLE} eq '' ||
      $element->{NULLABLE} =~ m/^(1|2)$/,
      'NULLABLE is undef, empty string, 0, 1 or 2'
    );
    
    #Check that SEARCHABLE is undef, 0, 1, 2 or 3
    # Valid values:
    # undef - Not set by the DBD
    # 0 - Cannot be used in a WHERE clause
    # 1 - Only with a LIKE predicate
    # 2 - All comparison operators except LIKE
    # 3 - Can be used in a WHERE clause with any comparison operator
    
    ok(
      !defined $element->{SEARCHABLE} ||
      $element->{SEARCHABLE} =~ m/^(0|1|2|3)$/,
      'SEARCHABLE is undef, 0, 1, 2 or 3'
    );
    
    
    #If FIXED_PREC_SCALE is set MINIMUM_SCALE and MAXIMUM_SCALE should be equal
    SKIP : {
      skip 'FIXED_PREC_SCALE is undef', 1 if !$element->{FIXED_PREC_SCALE};
      cmp_ok( $element->{MINIMUM_SCALE}, '==', $element->{MAXIMUM_SCALE}, 'MINIMUM_SCALE == MAXIMUM_SCALE');
    }
    
    #Check that MINIMUM_SCALE is undef or an integer
    ok( !defined $element->{MINIMUM_SCALE} || $element->{MINIMUM_SCALE} =~ m/^\d+$/, 'MINIMUM_SCALE is undef or integer');

    #Check that MAXIMUM_SCALE is undef or an integer
    ok( !defined $element->{MAXIMUM_SCALE} || $element->{MAXIMUM_SCALE} =~ m/^\d+$/, 'MAXIMUM_SCALE is undef or integer');
    
    #Check that SQL_DATA_TYPE is an integer
    # TODO : Do a better test
    ok(
      !defined $element->{SQL_DATA_TYPE} ||
      $element->{SQL_DATA_TYPE} =~ m/^\d+$/,
      "SQL_DATA_TYPE is undef or integer"
    );
    
    #Check that SQL_DATETIME_SUB is an integer
    # TODO : Do a better test
    ok(
      !defined $element->{SQL_DATETIME_SUB} ||
      $element->{SQL_DATETIME_SUB} =~ m/^\d+$/,
      "SQL_DATETIME_SUB is undef or integer"
    );
    
    #Check that NUM_PREC_RADIX is an integer
    # TODO : Do a better test
    ok(
      !defined $element->{NUM_PREC_RADIX} ||
      $element->{NUM_PREC_RADIX} =~ m/^\d+$/,
      "NUM_PREC_RADIX is undef or integer"
    );
    
    #Check that INTERVAL_PRECISION is an integer
    # TODO : Do a better test
    ok(
      !defined $element->{INTERVAL_PRECISION} ||
      $element->{INTERVAL_PRECISION} =~ m/^\d+$/,
      "INTERVAL_PRECISION is undef or integer"
    );    
  }
}

done_testing();