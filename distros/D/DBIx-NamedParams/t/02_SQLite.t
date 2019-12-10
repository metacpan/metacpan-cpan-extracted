use strict;
use Test::More;
use Test::More::UTF8;
use POSIX qw( strftime );
use YAML::Syck qw(Dump);
use DBD::SQLite 1.62;
use FindBin::libs;
use DBIx::NamedParams;
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
};

subtest 'KeepBindingIfNoKey' => sub {
    $DBIx::NamedParams::KeepBindingIfNoKey = 1;
    my @inputs = (
        { ID => 7, Name => 'Tiffany', State => 7, },
        { ID => 8, Name => 'Dana', },                  # `State` is not defined.
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
};

$dbh->disconnect;
unlink('dbfile');

done_testing;

sub toTestName {
    my $expected = shift or return 'No more data';
    return "Get $expected->{ID}:$expected->{Name}";
}
