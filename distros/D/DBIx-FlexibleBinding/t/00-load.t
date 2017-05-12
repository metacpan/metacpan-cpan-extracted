#!perl
use 5.006;
use strict 'refs', 'vars';
use warnings;
use Data::Dumper::Concise;
use JSON;
use Test::More;

$Data::Dumper::Terse  = 1;
$Data::Dumper::Indent = 0;

BEGIN {
    use_ok(
        'DBIx::FlexibleBinding', -as => 'DBIx::FB',
        -subs => ['DB'], -subs => 'statement', -subs => undef,
    ) || print "Bail out!\n";
}

diag
    "Testing DBIx::FlexibleBinding $DBIx::FlexibleBinding::VERSION, Perl $], $^X";

my $drivers = $ENV{TEST_DRIVER} || 'CSV|SQLite|mysql';
my @drivers = grep {/^(?:$drivers)$/} DBI->available_drivers();

SKIP:
{
    unless ( @drivers ) {
        my $list_of_drivers = join( ', ', map {"DBD::$_"} split( /\|/, $drivers ) );
        skip
            "Tests require at least one of these DBI drivers to execute: $list_of_drivers",
            1;
    }

    # There be giants:
    #
    # My test data originates from a MySQL conversion of CCP's EVE Online Static Data Export, with the conversion
    # being the result of Fuzzwork's hard work. My test data is a subset of that conversion. For more information
    # about EVE Online and Fuzzwork's excellent resource, check them out at the following links:
    #
    # - http://www.eveonline.com/
    # - https://www.fuzzwork.co.uk/
    # - https://www.fuzzwork.co.uk/dump/
    #
    # The test data set is a 7,929 record table containing data for EVE's 7,929 in-game solar systems, and it's
    # fairly large!
    open my $json_test_data_fh, '<:encoding(UTF-8)', './mapsolarsystems.json'
        or die "Unable to open ./mapsolarsystems test data";
    my $json_test_data = do { local $/ = <$json_test_data_fh> };
    close $json_test_data_fh;
    my $test_data = decode_json( $json_test_data );
    my $create    = << 'EOF';
CREATE TABLE mapsolarsystems (
  regionID INT(11) DEFAULT NULL,
  constellationID INT(11) DEFAULT NULL,
  solarSystemID INT(11) NOT NULL,
  solarSystemName varchar(100) DEFAULT NULL,
  x DOUBLE DEFAULT NULL,
  y DOUBLE DEFAULT NULL,
  z DOUBLE DEFAULT NULL,
  xMin DOUBLE DEFAULT NULL,
  xMax DOUBLE DEFAULT NULL,
  yMin DOUBLE DEFAULT NULL,
  yMax DOUBLE DEFAULT NULL,
  zMin DOUBLE DEFAULT NULL,
  zMax DOUBLE DEFAULT NULL,
  luminosity DOUBLE DEFAULT NULL,
  border TINYINT(1) DEFAULT NULL,
  fringe TINYINT(1) DEFAULT NULL,
  corridor TINYINT(1) DEFAULT NULL,
  hub TINYINT(1) DEFAULT NULL,
  international TINYINT(1) DEFAULT NULL,
  regional TINYINT(1) DEFAULT NULL,
  constellation TINYINT(1) DEFAULT NULL,
  security DOUBLE DEFAULT NULL,
  factionID INT(11) DEFAULT NULL,
  radius DOUBLE DEFAULT NULL,
  sunTypeID INT(11) DEFAULT NULL,
  securityClass varchar(2) DEFAULT NULL,
  PRIMARY KEY (solarSystemID)
)
EOF

    # Need the column numbers for each column
    my $count                   = 0;
    my @headings                = @{ shift( @$test_data ) };
    my $columns                 = join( ', ', @headings );
    my %columns                 = map { ( $_ => $count++ ) } @headings;
    my $positional_placeholders = join( ', ', map {"?"} @headings );
    my $n1_placeholders = join( ', ', map {":@{[1 + $columns{$_}]}"} @headings );
    my $n2_placeholders = join( ', ', map {"?@{[1 + $columns{$_}]}"} @headings );
    my $name1_placeholders = join( ', ', map {":$_"} @headings );
    my $name2_placeholders = join( ', ', map {"\@$_"} @headings );

    is_deeply(
        scalar( DBIx::FlexibleBinding::_as_list_or_ref( [] ) ), [],
        '_as_list_or_ref' );
    is_deeply( scalar( DBIx::FlexibleBinding::_as_list_or_ref( undef ) ), undef,
               '_as_list_or_ref' );
    is_deeply(
        [ DBIx::FlexibleBinding::_as_list_or_ref( undef ) ], [],
        '_as_list_or_ref' );
    is_deeply(
        [ DBIx::FlexibleBinding::_as_list_or_ref( [] ) ], [],
        '_as_list_or_ref' );

    my $n_keys = keys %::;
    DBIx::FlexibleBinding->_create_namespace_alias();
    is( scalar( keys %:: ), $n_keys );
    DBIx::FlexibleBinding->_create_namespace_alias( 'Foo' );
    isnt( scalar( keys %:: ), $n_keys );

    DB( undef );
    is( DB, undef );

    eval {
        DB( sub { } );
    };
    like( $@, qr/CRIT_PROXY_UNDEF/ );

    eval {
        DB( bless( sub { }, 'Not_st_or_db' ) );
    };
    like( $@, qr/CRIT_EXP_HANDLE/ );

    eval { DBIx::FlexibleBinding->import( '-unexp_arg' ) };
    like( $@, qr/CRIT_UNEXP_ARG/ );

    eval {
        DBIx::FlexibleBinding->_create_dbi_handle_proxies( 'Foo', sub { } );
    };
    like( $@, qr/CRIT_EXP_SUB_NAMES/ );

    for my $driver ( @drivers ) {
        SKIP:
        {
            my ( $rv, $create_copy, $dbh, $dsn, @user, $attr )
                = ( undef, undef, undef, undef, (), {} );

            if ( $driver eq 'CSV' ) {
                ( $dsn, @user, $attr ) = ( "dbi:$driver:", '', '', { f_dir => '.' } );
                $create_copy = $create;
                s/ DEFAULT NULL//g, s/ DOUBLE/ REAL/g, s/ (?:TINYINT|INT)/ INTEGER/g
                    for $create_copy;
                $dbh = eval { DB( $dsn, @user, $attr ) };

                DB( $dbh );
                is( DB, $dbh );
            }
            elsif ( $driver eq 'SQLite' ) {
                ( $dsn, @user, $attr ) = ( "dbi:$driver:test.db", '', '', {RaiseError=>0} );
                $create_copy = $create;
                $dbh = eval { DB( $dsn, @user, $attr ) };

                DB( $dbh );
                is( DB, $dbh );
            }
            else {
                ( $dsn, @user, $attr ) = (
                                         "dbi:$driver:test;host=127.0.0.1", $ENV{MYSQL_TEST_USER},
                                         $ENV{MYSQL_TEST_PASS},             {RaiseError=>0} );
                $dbh = eval { DB( $dsn, @user, $attr ) };

                DB( $dbh );
                is( DB, $dbh );
                $create_copy = $create;
            }

            skip "$driver tests (no connection to '$dsn')", 1
                unless defined $dbh;

            # Yay, we got a connection, and compile-time tagging clearly works!
            is( ref( DB ), 'DBIx::FlexibleBinding::db', "Testing DBD\::$driver ($dsn)" );

            unless ( $ENV{TEST_NO_RELOAD} ) {
                # Drop the "mapsolarsystems" table
                $rv = $dbh->do( 'DROP TABLE IF EXISTS mapsolarsystems' );
                if ( $driver eq 'CSV' ) {
                    is( $rv, -1, "drop" )
                        ; # Table drop won't do anything useful, delete the table's CSV file manually
                    unlink './mapsolarsystems';
                }
                else {
                    is( $rv, '0E0', "drop" );    # Table was dropped
                }

                # Recreate the "mapsolarsystems" table using a create statement sanitised for the driver
                $rv = $dbh->do( $create_copy );
                is( $rv, '0E0', "create" );      # Table was created

                # Populate the "mapsolarsystems" table
                my $count     = 0;
                my @test_data = @{$test_data};
                while ( @test_data ) {
                    $count++;
                    if ( $count > 440 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    $rv = $dbh->do(
                           "INSERT INTO mapsolarsystems ($columns) VALUES ($positional_placeholders)",
                           @$row );
                    last unless $rv == 1;
                }
                is( $count, 440, "insert ? ( VALUES )" )
                    ;    # do/INSERTs successful using positionals and list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 881 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    $rv = $dbh->do(
                           "INSERT INTO mapsolarsystems ($columns) VALUES ($positional_placeholders)",
                           $row );
                    last unless $rv == 1;
                }
                is( $count, 881, "insert ? [ VALUES ]" )
                    ;    # do/INSERTs successful using positionals and list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 1362 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    $rv = $dbh->do("INSERT INTO mapsolarsystems ($columns) VALUES ($n1_placeholders)",
                                   @$row );
                    last unless $rv == 1;
                }
                is( $count, 1362, "insert :NUMBER ( VALUES )" )
                    ;    # do/INSERTs successful using :N and list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 1762 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    $rv = $dbh->do("INSERT INTO mapsolarsystems ($columns) VALUES ($n1_placeholders)",
                                   $row );
                    last unless $rv == 1;
                }
                is( $count, 1762, "insert :NUMBER [ VALUES ]" )
                    ;    # do/INSERTs successful using :N and anonymous list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 2243 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    $rv = $dbh->do("INSERT INTO mapsolarsystems ($columns) VALUES ($n2_placeholders)",
                                   @$row );
                    last unless $rv == 1;
                }
                is( $count, 2243, "insert ?NUMBER ( VALUES )" )
                    ;    # do/INSERTs successful using ?N and list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 2643 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    $rv = $dbh->do("INSERT INTO mapsolarsystems ($columns) VALUES ($n2_placeholders)",
                                   $row );
                    last unless $rv == 1;
                }
                is( $count, 2643, "insert ?NUMBER [ VALUES ]" )
                    ;    # do/INSERTs successful using ?N and anonymous list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 3524 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    my @data = map { $_ => $row->[ $columns{$_} ] } @headings;
                    $rv = $dbh->do(
                                "INSERT INTO mapsolarsystems ($columns) VALUES ($name1_placeholders)",
                                @data );
                    last unless $rv == 1;
                }
                is( $count, 3524, "insert :NAME ( KEY-VALUE PAIRS )" )
                    ;    # do/INSERTs successful using :NAME with list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 4405 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    my @data = map { $_ => $row->[ $columns{$_} ] } @headings;
                    $rv = $dbh->do(
                                "INSERT INTO mapsolarsystems ($columns) VALUES ($name1_placeholders)",
                                [@data] );
                    last unless $rv == 1;
                }
                is( $count, 4405, "insert :NAME [ KEY-VALUE PAIRS ]" )
                    ;    # do/INSERTs successful using :NAME with anonymous list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 5286 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    my @data = map { $_ => $row->[ $columns{$_} ] } @headings;
                    $rv = $dbh->do(
                        "INSERT INTO mapsolarsystems ($columns) VALUES ($name1_placeholders)",
                        {}, {@data} );
                    last unless $rv == 1;
                }
                is( $count, 5286, "insert :NAME { KEY-VALUE PAIRS }" )
                    ;    # do/INSERTs successful using :NAME with anonymous hash

                while ( @test_data ) {
                    $count++;
                    if ( $count > 6167 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    my @data = map { '@' . $_ => $row->[ $columns{$_} ] } @headings;
                    $rv = $dbh->do(
                                "INSERT INTO mapsolarsystems ($columns) VALUES ($name2_placeholders)",
                                @data );
                    last unless $rv == 1;
                }
                is( $count, 6167, "insert \@NAME ( KEY-VALUE PAIRS )" )
                    ;    # do/INSERTs successful using @NAME with anonymous list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 7048 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    my @data = map { '@' . $_ => $row->[ $columns{$_} ] } @headings;
                    $rv = $dbh->do(
                                "INSERT INTO mapsolarsystems ($columns) VALUES ($name2_placeholders)",
                                [@data] );
                    last unless $rv == 1;
                }
                is( $count, 7048, "insert \@NAME [ KEY-VALUE PAIRS ]" )
                    ;    # do/INSERTs successful using @NAME with anonymous list

                while ( @test_data ) {
                    $count++;
                    if ( $count > 7929 ) {
                        $count -= 1;
                        last;
                    }
                    my $row = shift( @test_data );
                    my @data = map { '@' . $_ => $row->[ $columns{$_} ] } @headings;
                    $rv = $dbh->do(
                        "INSERT INTO mapsolarsystems ($columns) VALUES ($name2_placeholders)",
                        {}, {@data} );
                    last unless $rv == 1;
                }
                is( $count, 7929, "insert \@NAME { KEY-VALUE PAIRS }" )
                    ;    # do/INSERTs successful using @NAME with anonymous hash
            }

            # First, some really basic checks...
            my $sql = 'SELECT COUNT(*) AS count FROM mapsolarsystems';

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my @result = $sth->fetchrow_array();
                is( $result[0], 7929, 'prepare, execute, fetchrow_array' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->fetchrow_arrayref();
                is( $result->[0], 7929, 'prepare, execute, fetchrow_arrayref' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->fetchrow_hashref();
                is( $result->{count}, 7929, 'prepare, execute, fetchrow_hashref' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->fetchall_arrayref();
                is_deeply( $result, [ ['7929'] ], 'prepare, execute, fetchall_arrayref' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->fetchall_arrayref( {} );
                is_deeply(
                    $result, [ { count => '7929' } ],
                    'prepare, execute, fetchall_arrayref({})' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->getrow_arrayref( callback { $_->[0] } );
                is( $result, 7929, 'prepare, execute, getrow_arrayref (sth)' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->getrow_hashref( callback { $_->{count} } );
                is( $result, 7929, 'prepare, execute, getrow_hashref (sth)' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->getrows_arrayref( callback { $_->[0] } );
                is_deeply( $result, [7929], 'prepare, execute, getrows_arrayref (sth)' );
            }

            {
                my $sth = $dbh->prepare( $sql );
                $sth->execute();
                my $result = $sth->getrows_hashref( callback { $_->{count} } );
                is_deeply( $result, [7929], 'prepare, execute, fetchall_hashref (sth)' );
            }

            {
                my @result = $dbh->selectrow_array( $sql );
                is( $result[0], 7929, 'selectrow_array' );
            }

            {
                my $result = $dbh->selectrow_arrayref( $sql );
                is( $result->[0], 7929, 'selectrow_arrayref' );
            }

            {
                my $result = $dbh->selectrow_hashref( $sql );
                is( $result->{count}, 7929, 'selectrow_hashref' );
            }

            {
                my $result = $dbh->selectall_arrayref( $sql );
                is_deeply( $result, [ ['7929'] ], 'selectall_arrayref' );
            }

            {
                my $result = $dbh->selectall_arrayref( $sql, { Slice => {} } );
                is_deeply(
                    $result, [ { count => '7929' } ],
                    'selectall_arrayref({Slice => {}})' );
            }

            {
                my $result = $dbh->getrow_arrayref( $sql, callback { $_->[0] } );
                is( $result, 7929, 'getrow_arrayref (dbh)' );
            }

            {
                my $result = $dbh->getrow_hashref( $sql, callback { $_->{count} } );
                is( $result, 7929, 'getrow_hashref (dbh)' );
            }

            {
                my $result = $dbh->getrows_arrayref( $sql, callback { $_->[0] } );
                is_deeply( $result, [7929], 'getrows_arrayref (dbh)' );
            }

            {
                my $result = $dbh->getrows_hashref( $sql, callback { $_->{count} } );
                is_deeply( $result, [7929], 'getrows_hashref (dbh)' );
            }

            # Now some slightly funkier tests...

            {
                my $result;
                my @result;
                my $sql;
                my $count;
                my $expect;

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = ? AND security >= ?';
                $expect = [ [ 'Kisogo',      '1' ],
                            [ 'New Caldari', '1' ],
                            [ 'Amarr',       '1' ],
                            [ 'Bourynes',    '1' ],
                            [ 'Ryddinjorn',  '1' ],
                            [ 'Luminaire',   '1' ],
                            [ 'Duripant',    '1' ],
                            [ 'Yulai',       '1' ]
                ];
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql, 1, 1.0,
                    callback {
                        my $row = $_;
                        diag sprintf "%2d. %s", ++$count, encode_json( $row );
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = :1 AND security >= :2';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql, 1, 1.0,
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = :1 AND security >= :2';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql,
                    [ 1, 1.0 ],
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = ?1 AND security >= ?2';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql, 1, 1.0,
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = ?1 AND security >= ?2';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql,
                    [ 1, 1.0 ],
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = :regional AND security >= :security';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql,
                    regional => 1,
                    security => 1.0,
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = :regional AND security >= :security';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql,
                    [ regional => 1, security => 1.0 ],
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = :regional AND security >= :security';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql, {}, { regional => 1, security => 1.0 },
                    callback    # Extra hashref needed for statement
                    {           # attribute when presenting bind values as
                        my $row = $_;    # a hashref (why we have the square bracket
                        ++$count;        # option).
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = @regional AND security >= @security';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql,
                    '@regional' => 1,
                    '@security' => 1.0,
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = @regional AND security >= @security';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql,
                    [ '@regional' => 1, '@security' => 1.0 ],
                    callback {
                        my $row = $_;
                        ++$count;
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'result' );    # Good result!

                $sql
                    = 'SELECT solarSystemName, security FROM mapsolarsystems WHERE regional = @regional AND security >= @security';
                $count = 0;
                $result = $dbh->getrows_arrayref(
                    $sql, {}, { '@regional' => 1, '@security' => 1.0 },
                    callback    # Extra hashref needed for statement
                    {           # attribute when presenting bind values as
                        my $row = $_;    # a hashref (why we have the square bracket
                        ++$count;        # option).
                        return $row;
                    }
                );
                is( $count, 8, 'callback' );    # Callback was called 8 times
                is_deeply( $result, $expect, 'getrows_arrayref' );    # Good result!

                $sql
                    = 'SELECT solarSystemName AS name, security FROM mapsolarsystems WHERE regional = :regional AND security >= :security';
                $expect = [ { name => 'Kisogo',      security => '1' },
                            { name => 'New Caldari', security => '1' },
                            { name => 'Amarr',       security => '1' },
                            { name => 'Bourynes',    security => '1' },
                            { name => 'Ryddinjorn',  security => '1' },
                            { name => 'Luminaire',   security => '1' },
                            { name => 'Duripant',    security => '1' },
                            { name => 'Yulai',       security => '1' }
                ];
                my $sth = $dbh->prepare( $sql );
                $sth->execute( regional => 1, security => 1.0 );
                statement( $sth );
                is( statement(), $sth, 'statement handle proxy assignment' );
                $result = statement( regional => 1, security => 1.0 );
                is_deeply( $result, $expect, 'statement handle proxy execution' )
                    ;    # statement proxies work!
            }

            $dbh->disconnect();
        } ## end SKIP:
    } ## end for my $driver ( @drivers)
} ## end SKIP:

done_testing();
