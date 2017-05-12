#!perl -T
use strict;
use File::Spec::Functions;
use Test::More;

plan skip_all => "Test::DatabaseRow not available"
    unless eval "use Test::DatabaseRow; 1";

my $tests;

plan tests => $tests;


BEGIN { $tests += 3 }
# load and check the presence of the function
use_ok( 'DBIx::Connect::FromConfig', '-in_dbi' );
can_ok( 'DBIx::Connect::FromConfig' => 'connect' );
can_ok( 'DBI' => 'connect_from_config');


BEGIN { $tests += 8 }
# check diagnostics when called as a standard class method
eval { DBIx::Connect::FromConfig->connect() };
like( $@, q{/^error: No parameter given/}, 
    "calling DBIx::Connect::FromConfig->connect() with no argument" );

eval { DBIx::Connect::FromConfig->connect('plonk') };
like( $@, q{/^error: Odd number of arguments/}, 
    "calling DBIx::Connect::FromConfig->connect() with one argument" );

eval { DBIx::Connect::FromConfig->connect(config => []) };
like( $@, q{/^error: Unknown type of configuration/}, 
    "calling DBIx::Connect::FromConfig->connect() with an arrayref as configuration" );

eval {
    DBIx::Connect::FromConfig->connect(
        config => { driver => "Mock", attributes => [] }
    );
};
like( $@, q{/^error: DBI attributes must be given as a hashref or a string/},
    "calling DBIx::Connect::FromConfig->connect() with an improper value for the DBI attributes" );

# check diagnostics when called as a DBI method
eval { DBI->connect_from_config() };
like( $@, q{/^error: No parameter given/}, 
    "calling DBI->connect_from_config() with no argument" );

eval { DBI->connect_from_config('plonk') };
like( $@, q{/^error: Odd number of arguments/}, 
    "calling DBI->connect_from_config() with one argument" );

eval { DBI->connect_from_config(config => []) };
like( $@, q{/^error: Unknown type of configuration/}, 
    "calling DBI->connect_from_config() with an arrayref as configuration" );

eval {
    DBI->connect_from_config(config => { driver => "Mock", attributes => [] });
};
like( $@, q{/^error: DBI attributes must be given as a hashref or a string/},
    "calling DBI->connect_from_config() with an improper value for the DBI attributes" );


my ($dbh, $sth);

BEGIN { $tests += 2 }
# try to "connect" to a mocked database with settings in a hashref
SKIP: {
    skip "DBD::Mock not available", 2 unless eval "use DBD::Mock; 1";

    my %settings = ( driver => "Mock", database => "any" );
    $dbh = eval { DBI->connect_from_config(config => \%settings) };
    is( $@, '', "DBI->connect_from_config(): [hashref] "
                . "driver=$settings{driver} database=$settings{database}" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );
}

BEGIN { $tests += 4 }
# try to "connect" to a mocked database with settings in a Config::IniFiles object
SKIP: {
    skip "DBD::Mock not available", 4 unless eval "use DBD::Mock; 1";
    skip "Config::IniFiles not available", 4 unless eval "use Config::IniFiles; 1";

    my $config = Config::IniFiles->new(-file => catfile(qw(t files mock-default.ini)));
    $dbh = eval { DBI->connect_from_config(config => $config) };
    is( $@, '', "DBI->connect_from_config(): [Config::IniFiles]" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );

    $config = Config::IniFiles->new(-file => catfile(qw(t files mock-custom.ini)));
    $dbh = eval { DBI->connect_from_config(config => $config, section => 'customers_db') };
    is( $@, '', "DBI->connect_from_config(): [Config::IniFiles]" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );
}

BEGIN { $tests += 4 }
# try to "connect" to a mocked database with settings in a Config::Simple object
SKIP: {
    skip "DBD::Mock not available", 4 unless eval "use DBD::Mock; 1";
    skip "Config::Simple not available", 4 unless eval "use Config::Simple; 1";

    my $config = Config::Simple->new(catfile(qw(t files mock-default.ini)));
    $dbh = eval { DBI->connect_from_config(config => $config) };
    is( $@, '', "DBI->connect_from_config(): [Config::Simple]" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );

    $config = Config::Simple->new(catfile(qw(t files mock-custom.ini)));
    $dbh = eval { DBI->connect_from_config(config => $config, section => 'customers_db') };
    is( $@, '', "DBI->connect_from_config(): [Config::Simple]" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );
}

BEGIN { $tests += 4 }
# try to "connect" to a mocked database with settings in a Config::Tiny object
SKIP: {
    skip "DBD::Mock not available", 4 unless eval "use DBD::Mock; 1";
    skip "Config::Tiny not available", 4 unless eval "use Config::Tiny; 1";

    my $config = Config::Tiny->read(catfile(qw(t files mock-default.ini)));
    $dbh = eval { DBI->connect_from_config(config => $config) };
    is( $@, '', "DBI->connect_from_config(): [Config::Tiny]" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );

    $config = Config::Tiny->read(catfile(qw(t files mock-custom.ini)));
    $dbh = eval { DBI->connect_from_config(config => $config, section => 'customers_db') };
    is( $@, '', "DBI->connect_from_config(): [Config::Tiny]" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );
}


BEGIN { $tests += 3 }
# try to "connect" to a local database in CSV files
SKIP: {
    skip "DBD::CSV not available", 3 unless eval "use DBD::CSV; 1";

    my %settings = ( driver => "CSV", database => "t/db", options => "csv_sep_char=|" );
    $dbh = eval { DBI->connect_from_config(config => \%settings) };
    is( $@, '', "DBI->connect_from_config(): [hashref] "
                . "driver=$settings{driver} database=$settings{database}" );
    isa_ok( $dbh, 'DBI::db', "checking that \$dbh" );

    row_ok(
        dbh => $dbh, 
        table => "klortho",  where => [ number => 11917 ], 
        tests => [ advice => "Read.  Learn.  Evolve." ], 
        verbose => 1, 
    );
}
