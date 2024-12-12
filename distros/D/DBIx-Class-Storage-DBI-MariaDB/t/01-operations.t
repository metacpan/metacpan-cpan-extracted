# tests inpsired/copied from https://github.com/Perl5/DBIx-Class/blob/maint/0.0828xx/t/71mysql.t

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use Scalar::Util qw/weaken/;

use lib qw(t/lib);
use MyApp::Schema;

my ( $dsn, $user, $pass ) =
  @ENV{ map { "DBICTEST_MARIADB_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBICTEST_MARIADB_DSN}, _USER and _PASS to run tests'
  unless ( $dsn && $user );

my $schema = MyApp::Schema->connect( $dsn, $user, $pass );

my $dbh = $schema->storage->dbh;

# initialize tables
$dbh->do("SET foreign_key_checks=0");
$dbh->do("DROP TABLE IF EXISTS artist");
$dbh->do(
    "CREATE TABLE artist (
    artistid INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    name VARCHAR(100),
    rank INTEGER NOT NULL DEFAULT 13,
    charfield CHAR(10),
    picture MEDIUMBLOB
)"
);
$dbh->do("DROP TABLE IF EXISTS owner");
$dbh->do(
    "CREATE TABLE owner (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
)"
);
$dbh->do("DROP TABLE IF EXISTS book");
$dbh->do(
    "CREATE TABLE book (
    id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    source VARCHAR(100) NOT NULL,
    owner INTEGER NOT NULL,
    title VARCHAR(100) NOT NULL,
    price INTEGER
)"
);
$dbh->do("DROP TABLE IF EXISTS cd");
$dbh->do(
    "CREATE TABLE cd (
    cdid INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    artist INTEGER,
    title TEXT,
    year TEXT
)"
);
$dbh->do("DROP TABLE IF EXISTS producer");
$dbh->do(
    "CREATE TABLE producer (
    producerid INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name TEXT
)"
);
$dbh->do("DROP TABLE IF EXISTS cd_to_producer");
$dbh->do("CREATE TABLE cd_to_producer (cd INTEGER, producer INTEGER)");
$dbh->do("SET foreign_key_checks=1");

subtest 'sqlt_type overrides' => sub {
    my $schema = MyApp::Schema->connect( $dsn, $user, $pass );
    ok( !$schema->storage->_dbh, 'definitely not connected' );
    is( $schema->storage->sqlt_type,
        'MySQL', 'sqlt_type correct pre-connection' );
};

subtest 'primary key handling' => sub {
    my $new =
      $schema->resultset('Artist')->create( { name => 'Duke Ellington' } );
    ok( $new->artistid, 'Auto-PK worked' );
};

subtest 'LIMIT support' => sub {
    for ( 1 .. 6 ) {
        $schema->resultset('Artist')->create( { name => 'Artist ' . $_ } );
    }
    my $it = $schema->resultset('Artist')
      ->search( {}, { rows => 3, offset => 2, order_by => 'artistid' } );
    is( $it->count,      3,          'LIMIT count ok' );
    is( $it->next->name, 'Artist 2', 'iterator->next ok' );
    $it->next;
    $it->next;
    is( $it->next, undef, 'next past end of resultset ok' );
};

subtest 'LIMIT with select-lock' => sub {
    lives_ok {
        $schema->txn_do(
            sub {
                isa_ok(
                    $schema->resultset('Artist')->find(
                        { artistid => 1 },
                        { for      => 'update', rows => 1 }
                    ),
                    'MyApp::Schema::Artist'
                );
            }
        );
    }
    'Limited FOR UPDATE select works';
};

subtest 'LIMIT with shared lock' => sub {
    lives_ok {
        $schema->txn_do(
            sub {
                isa_ok(
                    $schema->resultset('Artist')
                      ->find( { artistid => 1 }, { for => 'shared' } ),
                    'MyApp::Schema::Artist'
                );
            }
        );
    }
    'LOCK IN SHARE MODE select works';
};

$schema->populate( 'Owner',
    [ 
        [qw/id name/], 
        [qw/1  wiggle/], 
        [qw/2  woggle/], 
        [qw/3  boggle/], 
    ] 
);
$schema->populate(
    'BooksInLibrary',
    [
        [qw/source  owner title   /], 
        [qw/Library 1     secrets1/],
        [qw/Eatery  1     secrets2/], 
        [qw/Library 2     secrets3/],
    ]
);

subtest 'distinct + prefetch on tables with identically named columns' => sub {

    # try ->has_many
    my $owners = $schema->resultset('Owner')->search(
        { 'books.id' => { '!=', undef } },
        { prefetch   => 'books', distinct => 1 }
    );
    my $owners2 = $schema->resultset('Owner')
      ->search( { id => { -in => $owners->get_column('me.id')->as_query } } );
    for ( $owners, $owners2 ) {
        is( $_->all, 2,
            'Prefetched grouped search returns correct number of rows' );
        is( $_->count, 2, 'Prefetched grouped search returns correct count' );
    }

    #try ->belongs_to
    my $books =
      $schema->resultset('BooksInLibrary')
      ->search( { 'owner.name' => 'wiggle' },
        { prefetch => 'owner', distinct => 1 } );
    my $books2 = $schema->resultset('BooksInLibrary')
      ->search( { id => { -in => $books->get_column('me.id')->as_query } } );
    for ( $books, $books2 ) {
        is( $_->all, 1,
            'Prefetched grouped search returns correct number of rows' );
        is( $_->count, 1, 'Prefetched grouped search returns correct count' );
    }
};

my $cd       = $schema->resultset('CD')->create( {} );
my $producer = $schema->resultset('Producer')->create( {} );
lives_ok { $cd->set_producers( [$producer] ) } 'set_relationship doesnt die';

subtest 'joins' => sub {
    my $artist = $schema->resultset('Artist')->next;
    my $cd     = $schema->resultset('CD')->next;
    $cd->set_from_related( 'artist', $artist );
    $cd->update;

    my $rs = $schema->resultset('CD')->search( {}, { prefetch => 'artist' } );

    lives_ok {
        my $cd = $rs->next;
        is( $cd->artist->name, $artist->name, 'Prefetched artist' );
    } 'join does not throw';
};

subtest 'null in search' => sub {
    my $ansi_schema = MyApp::Schema->connect( $dsn, $user, $pass,
        { on_connect_call => 'set_strict_mode' } );
    $ansi_schema->resultset('Artist')
      ->create( { name => 'last created artist' } );

    ok(
        my $artist1_rs =
          $ansi_schema->resultset('Artist')->search( { artistid => 6666 } ),
        'Created an artist resultset of 6666'
    );
    is( $artist1_rs->count, 0, 'Got no returned rows' );

    ok(
        my $artist2_rs =
          $ansi_schema->resultset('Artist')->search( { artistid => undef } ),
        'Created an artist resultset of undef'
    );
    is( $artist2_rs->count, 0, 'Got no returned rows' );

    my $artist = $artist2_rs->single;
    is( $artist, undef, 'nothing found' );
};

subtest 'grouped counts' => sub {
    my $ansi_schema = MyApp::Schema->connect(
        $dsn, $user, $pass,
        {
            on_connect_call => 'set_strict_mode',
            quote_char      => '`',
        }
    );
    my $rs = $ansi_schema->resultset('CD');

    my $years;
    $years->{ $_->year || scalar keys %$years }++ for $rs->all;

    lives_ok {
        is(
            $rs->search( {}, { group_by => 'year' } )->count,
            scalar keys %$years,
            'Grouped count correct'
        );
    } 'Grouped count does not throw';

    lives_ok {
        $ansi_schema->resultset('Owner')->search(
            {},
            {
                join     => 'books',
                group_by => [ 'me.id', 'books.id' ]
            }
        )->count;
    } 'Count on grouped columns with the same name does not throw';
};

subtest 'self-referential double-subquery' => sub {
    my $rs =
      $schema->resultset('Artist')->search( { name => { -like => 'baby_%' } } );
    $rs->populate( [ map { [$_] } ( 'name', map { "baby_$_" } ( 1 .. 10 ) ) ] );

    my ( $count_sql, @count_bind ) = @${ $rs->count_rs->as_query };
    my $complex_rs = $schema->resultset('Artist')->search(
        {
            artistid => {
                -in => $rs->get_column('artistid')->as_query
            }
        },
    );
    $complex_rs->update(
        {
            name =>
              \[ "CONCAT(`name`, '_bell_out_of_', $count_sql)", @count_bind ]
        }
    );

    for ( 1 .. 10 ) {
        is(
            $schema->resultset('Artist')
              ->search( { name => "baby_${_}_bell_out_of_10" } )->count,
            1,
            'Correctly updated babybell $_'
        );
    }

    is( $rs->count, 10, '10 artists present' );
    $complex_rs->delete;
    is( $rs->count, 0, '10 artists correctly deleted' );

    $rs->create(
        {
            name => 'baby_with_cd',
            cds  => [ { title => 'babeeeee', year => '1712' } ],
        }
    );
    is( $rs->count, 1, 'Artist with CD created' );
    $schema->resultset('CD')
      ->search_related( 'artist',
        { 'artist.name' => { -like => 'baby_with_%' } } )->delete;
    is( $rs->count, 0, 'Artist with CD deleted' );
};

subtest 'zero in search' => sub {
    my $cds_per_year = {
        2001 => 2,
        2002 => 1,
        2005 => 3,
    };

    my $rs = $schema->resultset('CD');
    $rs->delete;
    for my $y ( keys %$cds_per_year ) {
        for my $c ( 1 .. $cds_per_year->{$y} ) {
            $rs->create(
                { title => "CD $y-$c", artist => 1, year => "$y-01-01" } );
        }
    }
    is( $rs->count, 6, 'CDs created successfully' );

    $rs = $rs->search(
        {},
        {
            select   => [ \'YEAR(year)' ],
            as       => ['y'],
            distinct => 1,
        }
    );

    my $y_rs = $rs->get_column('y');
    warnings_exist {
        is_deeply(
            [ sort( $y_rs->all ) ],
            [ sort keys %$cds_per_year ],
            'Years group successfully'
        )
    }
    qr/
        \QUse of distinct => 1 while selecting anything other than a column \E
        \Qdeclared on the primary ResultSource is deprecated\E
    /x, 'deprecation warning';

    $rs->create( { artist => 1, year => '0-1-1', title => 'Chocolate Rain' } );

    is_deeply(
        [ sort $y_rs->all ],
        [ 0, sort keys %$cds_per_year ],
        'Zero-year groups successful',
    );

    my $restrict_rs = $rs->search(
        {
            -and => [
                year => { '!=', 0 },
                year => { '!=', undef },
            ]
        }
    );

    warnings_exist {
        is_deeply(
            [ sort $restrict_rs->get_column('y')->all ],
            [ sort $y_rs->all ],
            'Zero year was correctly excluded from the resultset'
        )
    }
    qr/
        \QUse of distinct => 1 while selecting anything other than a column \E
        \Qdeclared on the primary ResultSource is deprecated\E
    /x, 'deprecation warning';
};

subtest 'find hooks determine driver' => sub {
    my $schema = MyApp::Schema->connect( $dsn, $user, $pass );
    $schema->resultset('Artist')->find(4);
    isa_ok( $schema->storage->sql_maker, 'DBIx::Class::SQLMaker::MySQL' );
};

subtest 'mariadb_auto_reconnect' => sub {
    local $ENV{MOD_PERL} = 'whyisperllikethis';
    my $schema = MyApp::Schema->connect( $dsn, $user, $pass );
    ok(
        !$schema->storage->_get_dbh->{mariadb_auto_reconnect},
        'mariadb_auto_reconnect unset regardless of ENV'
    );

    my $schema_autorecon = MyApp::Schema->connect( $dsn, $user, $pass,
        { mariadb_auto_reconnect => 1 } );
    my $orig_dbh = $schema_autorecon->storage->_get_dbh;
    weaken $orig_dbh;

    ok( $orig_dbh, 'Got weak $dbh ref' );
    ok( $orig_dbh->{mariadb_auto_reconnect},
        'mariadb_auto_reconnect is properly set if explicitly requested' );

    my $rs = $schema_autorecon->resultset('Artist');

    # kill our $dbh
    $schema_autorecon->storage->_dbh(undef);
    ok( !defined $orig_dbh, '$dbh handle is gone' );

    $rs->create( { name => "test" } );
    ok( !defined $orig_dbh,
        'DBIC operation triggered reconnect - old $dbh is gone' );
    ok( $rs->find( { name => "test" } ), 'Expected row created' );
};

subtest 'blob round trip' => sub {
    my $new =
      $schema->resultset('Artist')->create( { name => 'blob round trip', picture => "\302\243" } );
    ok( $new->artistid, 'Auto-PK worked' );

    my $artist2_rs =
      $schema->resultset('Artist')->search( { artistid => $new->artistid } );

    is($artist2_rs->single->picture, "\302\243", "Round-tripped a blob");
};

done_testing;
