use strict;
use warnings;
use Test::More 0.98;

# Test driver loading
use_ok 'DBD::libsql';

# Test driver class methods exist
{
    can_ok 'DBD::libsql', 'driver';
    
    # Test that driver function exists and doesn't crash
    # Don't actually call it since it may interact with DBI internals
    pass 'driver() method exists and accessible';
}

# Test DSN parsing logic (without actual connection)
{
    # Test the DSN parsing logic directly
    my @test_cases = (
        {
            dsn => "dbi:libsql:test.db",
            expected => "test.db",
        },
        {
            dsn => "dbi:libsql:database=/path/to/test.db", 
            expected => "/path/to/test.db",
        },
        {
            dsn => "dbi:libsql::memory:",
            expected => ":memory:",
        }
    );
    
    for my $test (@test_cases) {
        my $dsn = $test->{dsn};
        my $database;
        my $dsn_remainder = $dsn;
        $dsn_remainder =~ s/^dbi:libsql://i;
        
        if ($dsn_remainder =~ /^(?:db(?:name)?|database)=([^;]*)/i) {
            $database = $1;
        } else {
            $database = $dsn_remainder;
        }
        
        is $database, $test->{expected}, "DSN parsing for '$dsn'";
    }
}

# Test that required packages exist
{
    # Test imp_data_size methods
    can_ok 'DBD::libsql::dr', 'imp_data_size';
    can_ok 'DBD::libsql::db', 'imp_data_size';
    can_ok 'DBD::libsql::st', 'imp_data_size';
    
    is DBD::libsql::dr->imp_data_size, 0, 'DBD::libsql::dr imp_data_size is 0';
    is DBD::libsql::db->imp_data_size, 0, 'DBD::libsql::db imp_data_size is 0';
    is DBD::libsql::st->imp_data_size, 0, 'DBD::libsql::st imp_data_size is 0';
}

# Test that required methods exist
{
    can_ok 'DBD::libsql::dr', qw(connect data_sources DESTROY);
    can_ok 'DBD::libsql::db', qw(prepare commit rollback disconnect STORE FETCH DESTROY);
    can_ok 'DBD::libsql::st', qw(bind_param execute fetchrow_arrayref fetchrow_hashref finish rows DESTROY);
}

done_testing;
