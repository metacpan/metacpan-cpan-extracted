use strict;
use Test::More;
use Test::More::UTF8;
use Test::Exception;
use POSIX qw( strftime );
use YAML::Syck qw(Dump);
use DBD::SQLite 1.62;
use FindBin::libs;
use DBIx::NamedParams;
use HashCondition;
use ArrayCondition;
use open ':std' => ( $^O eq 'MSWin32' ? ':locale' : ':utf8' );

note("Perl version:\t$]");
note("DBI version:\t${DBI::VERSION}");
note("DBD::SQLite version:\t${DBD::SQLite::VERSION}");
note( strftime( "%Y-%m-%d %H:%M:%S", localtime ) );

my $dbh;

subtest 'Prepare DB' => sub {
    ok( $dbh = DBI->connect(
            'dbi:SQLite:dbname=dbfile',
            '', '',
            {   RaiseError => 1,
                AutoCommit => 1,
            },
        ),
        'Connect to dbfile'
    ) or diag($DBI::errstr);
    ok( $dbh->do('DROP TABLE IF EXISTS `Users`')
            && $dbh->do('CREATE TABLE `Users` (`ID` int, `Name` text, `Status` int)')
            && $dbh->do('INSERT INTO `Users` (`ID`, `Name`, `Status`) VALUES (1, "Rio", 1)')
            && $dbh->do('INSERT INTO `Users` (`ID`, `Name`, `Status`) VALUES (2, "Mint", 2)')
            && $dbh->do('INSERT INTO `Users` (`ID`, `Name`, `Status`) VALUES (3, "Rosa", 3)'),
        'Create test database'
    ) or diag($DBI::errstr);
};

subtest 'driver_typename_map' => sub {
    is_deeply(
        { $dbh->driver_typename_map() },
        {   ''      => 'ALL_TYPES',
            BLOB    => 'BLOB',
            INTEGER => 'INTEGER',
            REAL    => 'DOUBLE',
            TEXT    => 'VARCHAR',
        },
        'driver_typename_map'
        )
        or diag(
        Dump(
            [   map {
                    my $typeInfo = $_;
                    scalar {
                        map      { $_ => $typeInfo->{$_}; }
                            grep { $_ =~ /TYPE/ }
                            keys( %{$typeInfo} )
                    };
                } $dbh->type_info()
            ]
        )
        );
};

subtest 'Insert data (scalar binding)' => sub {
    my $sth;
    ok( $sth = $dbh->prepare_ex(
            'INSERT INTO `Users` ( `ID`, `Name`, `Status` ) VALUES ( :ID-INTEGER, :Name-VARCHAR, :State-INTEGER )'
        ),
        'Prepare INSERT'
    ) or diag($DBI::errstr);
    my @inputs = (
        { ID => 4, Name => 'Linda', State => 4, },
        { ID => 5, Name => 'Rina',  State => 5, },
        { ID => 6, Name => 'Anya',  State => 6, },
    );
    foreach my $input (@inputs) {
        ok( $sth->bind_param_ex($input), "Bind '$input->{Name}'" )
            or diag($DBI::errstr);
        ok( $sth->execute(), "Insert '$input->{Name}'" ) or diag($DBI::errstr);
    }
    $sth->finish;
};

subtest 'Select all data' => sub {
    my $sth;
    ok( $sth = $dbh->prepare_ex( 'SELECT `ID`, `Name`, `Status` FROM `Users`', ), 'Prepare SELECT' )
        or diag($DBI::errstr);
    ok( $sth->execute(), 'Execute query' ) or diag($DBI::errstr);
    my @expecteds = (
        { ID => 1, Name => 'Rio',   Status => 1, },
        { ID => 2, Name => 'Mint',  Status => 2, },
        { ID => 3, Name => 'Rosa',  Status => 3, },
        { ID => 4, Name => 'Linda', Status => 4, },
        { ID => 5, Name => 'Rina',  Status => 5, },
        { ID => 6, Name => 'Anya',  Status => 6, },
        undef,
    );
    foreach my $expected (@expecteds) {
        is_deeply( $sth->fetchrow_hashref, $expected, toTestName($expected) );
    }
    $sth->finish;
};

subtest 'Select data (fixed array binding)' => sub {
    my $sth;
    ok( $sth = $dbh->prepare_ex(
            'SELECT `ID`, `Name`, `Status` FROM `Users` WHERE `Status` in (:State{4}-INTEGER)',
        ),
        'Prepare SELECT'
    ) or diag($DBI::errstr);
    ok( $sth->bind_param_ex( { State => [ 1, 2, 4, 8 ], } ), "Bind 'State'" )
        or diag($DBI::errstr);
    ok( $sth->execute(), 'Execute query' ) or diag($DBI::errstr);
    my @expecteds = (
        { ID => 1, Name => 'Rio',   Status => 1, },
        { ID => 2, Name => 'Mint',  Status => 2, },
        { ID => 4, Name => 'Linda', Status => 4, }, undef,
    );
    foreach my $expected (@expecteds) {
        is_deeply( $sth->fetchrow_hashref, $expected, toTestName($expected) );
    }
    $sth->finish;
};

subtest 'Select data (variable array binding)' => sub {
    my $sth;
    ok( $sth = $dbh->prepare_ex(
            'SELECT `ID`, `Name`, `Status` FROM `Users` WHERE `Status` in (:State+-INTEGER)',
            { State => [ 1, 2, 5 ], }
        ),
        'Prepare SELECT'
    ) or diag($DBI::errstr);
    ok( $sth->execute(), 'Execute query' ) or diag($DBI::errstr);
    my @expecteds = (
        { ID => 1, Name => 'Rio',  Status => 1, },
        { ID => 2, Name => 'Mint', Status => 2, },
        { ID => 5, Name => 'Rina', Status => 5, }, undef,
    );
    foreach my $expected (@expecteds) {
        is_deeply( $sth->fetchrow_hashref, $expected, toTestName($expected) );
    }
    $sth->finish;
};

subtest 'Select data (two steps binding)' => sub {
    $DBIx::NamedParams::KeepBindingIfNoKey = 1;
    my $sth;
    ok( $sth = $dbh->prepare_ex(
            qq{
                SELECT `ID`, `Name`, `Status` FROM `Users` 
                WHERE `ID` = :ID-INTEGER AND `Status` in (:State+-INTEGER)
            },
            { State => [ 1, 3, 6 ], }
        ),
        'Prepare SELECT'
    ) or diag($DBI::errstr);
    my @expecteds = (
        { ID => 1,  Name => 'Rio',       Status => 1, },
        { ID => 3,  Name => 'Rosa',      Status => 3, },
        { ID => 6,  Name => 'Anya',      Status => 6, },
        { ID => -1, Name => 'Not exist', Status => -1, },
    );
    foreach my $expected (@expecteds) {
        ok( $sth->bind_param_ex( { ID => $expected->{'ID'}, } ), "Bind ID:$expected->{ID}" )
            or diag($DBI::errstr);
        ok( $sth->execute(), 'Execute query' ) or diag($DBI::errstr);
        is_deeply( $sth->fetchrow_hashref, $expected->{'Name'} eq 'Not exist' ? undef : $expected,
            toTestName($expected) );
    }
    $sth->finish;
    $DBIx::NamedParams::KeepBindingIfNoKey = 0;
};

subtest 'KeepBindingIfNoKey' => sub {
    $DBIx::NamedParams::KeepBindingIfNoKey = 1;
    my @inputs = (
        { ID => 7, Name => 'Tiffany', State => 7, },
        { ID => 8, Name => 'Dana', },                      # `State` is not defined.
        { ID => 9, Name => 'Cartia', State => undef, },    # clear `State`.
    );
    my @expecteds = (
        { ID => 7, Name => 'Tiffany', Status => 7, },
        { ID => 8, Name => 'Dana',    Status => 7, },        # `Status` is same to previous record.
        { ID => 9, Name => 'Cartia',  Status => undef, },    # `Status` is cleared.
        undef,
    );
    my $sth;
    ok( $sth = $dbh->prepare_ex(
            'INSERT INTO `Users` ( `ID`, `Name`, `Status` ) VALUES ( :ID-INTEGER, :Name-VARCHAR, :State-INTEGER )'
        ),
        'Prepare INSERT'
    ) or diag($DBI::errstr);
    foreach my $input (@inputs) {
        ok( $sth->bind_param_ex($input), "Bind '$input->{Name}'" )
            or diag($DBI::errstr);
        ok( $sth->execute(), "Insert '$input->{Name}'" ) or diag($DBI::errstr);
    }
    $sth->finish;
    ok( $sth = $dbh->prepare_ex('SELECT `ID`, `Name`, `Status` FROM `Users` WHERE `ID` in (7,8,9)'),
        'Prepare SELECT'
    ) or diag($DBI::errstr);
    ok( $sth->execute(), 'Execute query' ) or diag($DBI::errstr);
    foreach my $expected (@expecteds) {
        is_deeply( $sth->fetchrow_hashref, $expected, toTestName($expected) );
    }
    $sth->finish;
    $DBIx::NamedParams::KeepBindingIfNoKey = 0;
};

subtest 'prepare_ex need hash' => sub {
    my $sql = 'SELECT `ID`, `Name`, `Status` FROM `Users` WHERE `Status` in (:State+-INTEGER)';
    my $sth;
    throws_ok {
        $sth = $dbh->prepare_ex( $sql, undef );
        $sth->finish;
    }
    qr/need a hash reference/, 'undef';
    throws_ok {
        $sth = $dbh->prepare_ex( $sql, 1 );
        $sth->finish;
    }
    qr/need a hash reference/, 'number';
    throws_ok {
        $sth = $dbh->prepare_ex( $sql, 'string' );
        $sth->finish;
    }
    qr/need a hash reference/, 'string';
    throws_ok {
        $sth = $dbh->prepare_ex( $sql, [ 1, 2, 5 ] );
        $sth->finish;
    }
    qr/need a hash reference/, 'array';
    lives_ok {
        $sth = $dbh->prepare_ex( $sql, { State => [ 1, 2, 5 ], } );
        $sth->finish;
    }
    'hash';
    lives_ok {
        $sth = $dbh->prepare_ex( $sql, HashCondition->new( undef, undef, [ 1, 2, 5 ] ) );
        $sth->finish;
    }
    'HashCondition';
    throws_ok {
        $sth = $dbh->prepare_ex( $sql, ArrayCondition->new( undef, undef, [ 1, 2, 5 ] ) );
        $sth->finish;
    }
    qr/need a hash reference/, 'ArrayCondition';
};

subtest 'bind_param_ex need hash' => sub {
    my $sth = $dbh->prepare_ex( 'INSERT INTO `Users` ( `ID`, `Name`, `Status` ) '
            . 'VALUES ( :ID-INTEGER, :Name-VARCHAR, :State-INTEGER )' );
    throws_ok { $sth->bind_param_ex(undef); }
    qr/need a hash reference/, 'undef';
    throws_ok { $sth->bind_param_ex(1); }
    qr/need a hash reference/, 'number';
    throws_ok { $sth->bind_param_ex('string'); }
    qr/need a hash reference/, 'string';
    throws_ok { $sth->bind_param_ex( [ 1, 2, 5 ] ); }
    qr/need a hash reference/, 'array';
    lives_ok { $sth->bind_param_ex( { State => [ 1, 2, 5 ], } ); }
    'hash';
    lives_ok { $sth->bind_param_ex( HashCondition->new( undef, undef, [ 1, 2, 5 ] ) ); }
    'HashCondition';
    throws_ok { $sth->bind_param_ex( ArrayCondition->new( undef, undef, [ 1, 2, 5 ] ) ); }
    qr/need a hash reference/, 'ArrayCondition';
    $sth->finish;
};

subtest 'Multi statements' => sub {
    my $sth_check;
    ok( $sth_check = $dbh->prepare_ex(
            q{  SELECT * 
                FROM `Users` 
                WHERE `ID` = :ID-INTEGER },
        ),
        'Prepare CHECK'
    ) or diag($DBI::errstr);
    my $sth_insert;
    ok( $sth_insert = $dbh->prepare_ex(
            q{  INSERT INTO `Users` ( `ID`, `Name`, `Status` ) 
                VALUES ( :ID-INTEGER, :Name-VARCHAR, :State-INTEGER ) }
        ),
        'Prepare INSERT'
    ) or diag($DBI::errstr);
    my $sth_update;
    ok( $sth_update = $dbh->prepare_ex(
            q{  UPDATE `Users` 
                SET `Name` = :Name-VARCHAR, 
                    `Status` = :State-INTEGER 
                WHERE `ID` = :ID-INTEGER }
        ),
        'Prepare UPDATE'
    ) or diag($DBI::errstr);
    showAll();
    my @inputs = (
        { ID => 2,  Name => 'Misery', State => 3, Action => 'Update', },
        { ID => 10, Name => 'Elle',   State => 4, Action => 'Insert', },
        { ID => 3,  Name => 'Ilina',  State => 5, Action => 'Update', },
        { ID => 11, Name => 'Risa',   State => 6, Action => 'Insert', },
    );
    foreach my $input (@inputs) {
        $sth_check->bind_param_ex($input) or diag($DBI::errstr);
        $sth_check->execute()             or diag($DBI::errstr);
        if ( !$sth_check->fetchrow_hashref ) {
            is( $input->{'Action'}, 'Insert', toTestName( $input, 'Insert' ) );
            $sth_insert->bind_param_ex($input) or diag($DBI::errstr);
            $sth_insert->execute()             or diag($DBI::errstr);
        } else {
            is( $input->{'Action'}, 'Update', toTestName( $input, 'Update' ) );
            $sth_update->bind_param_ex($input) or diag($DBI::errstr);
            $sth_update->execute()             or diag($DBI::errstr);
        }
        $sth_check->bind_param_ex($input) or diag($DBI::errstr);
        $sth_check->execute()             or diag($DBI::errstr);
        is_deeply(
            $sth_check->fetchrow_hashref,
            {   ID     => $input->{'ID'},
                Name   => $input->{'Name'},
                Status => $input->{'State'},
            },
            toTestName($input)
        );
    }
    $sth_check->finish;
    $sth_insert->finish;
    $sth_update->finish;
    showAll();
};

$dbh->disconnect;
unlink('dbfile');

done_testing;

sub showAll {
    my @fields = qw(ID Name Status);
    my $sth    = $dbh->prepare( 'SELECT * FROM `Users`', ) or diag($DBI::errstr);
    $sth->execute() or diag($DBI::errstr);
    note( join( "\t", @fields ) );
    while ( my $row = $sth->fetchrow_hashref ) {
        note( join( "\t", map { $row->{$_} } @fields ) );
    }
    $sth->finish;
}

sub toTestName {
    my $expected = shift or return 'No more data';
    my $action   = shift || 'Get';
    return "$action $expected->{ID}:$expected->{Name}";
}
