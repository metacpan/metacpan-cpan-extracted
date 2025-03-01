use strict;
use warnings;
use 5.010_001;

use Test::Exception;
use Test::Warn;
use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More;
#
# We use Test::More::UTF8 to enable UTF-8 on Test::Builder
# handles (failure_output, todo_output, and output) created
# by Test::More. Requires Test::Simple 1.302210+, and seems
# to eliminate the following error on some CPANTs builds:
#
# > Can't locate object method "e" via package "warnings"
#
use Test::More::UTF8;

BEGIN {
    use_ok( 'DBIx::Squirrel', database_entities => [qw(db artist artists)] )
        or print "Bail out!\n";
    use_ok( 'T::Squirrel', qw(:var diagdump) )
        or print "Bail out!\n";
    use_ok(
        'DBIx::Squirrel::st', qw(
            statement_digest
            statement_study
            statement_trim
        ),
    ) or print "Bail out!\n";
}

sub SQLite_is_too_old {
    return $DBD::SQLite::VERSION < 1.56;
}

diag join(
    ', ',
    "Testing DBIx::Squirrel $DBIx::Squirrel::VERSION",
    "Perl $]", "$^X",
);

{
    for my $t (
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim() ],
            exp  => [""],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim(undef) ],
            exp  => [""],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim("") ],
            exp  => [""],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim("SELECT 1") ],
            exp  => ["SELECT 1"],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim("SELECT 1  -- COMMENT") ],
            exp  => ["SELECT 1"],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim("SELECT 1\n-- COMMENT") ],
            exp  => ["SELECT 1"],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim("  SELECT 1\n-- COMMENT  ") ],
            exp  => ["SELECT 1"],
        },
        {
            line => __LINE__, name => "ok - statement_trim",
            got  => [ statement_trim("\tSELECT 1\n-- COMMENT  ") ],
            exp  => ["SELECT 1"],
        },
    ) {
        is_deeply(
            UNIVERSAL::isa( $t->{got}, 'CODE' ) ? $t->{got}->() : $t->{got},
            $t->{exp},
            sprintf( 'line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : '' ),
        );
    }
}


{
    local $DBIx::Squirrel::st::STATEMENT_DIGEST = sub { 'DETERMINISTIC-DIGEST' };

    throws_ok {
        statement_study( bless( {}, 'NotAStatementHandle' ) );
    }
    (
        qr/Expected a statement handle/,
        'ok - blessed ref must be statement handle',
    );

    my $db1 = DBIx::Squirrel->connect(@MOCK_DB_CONNECT_ARGS);
    my $st1 = $db1->prepare('SELECT :foo, :bar');

    my $db2 = DBI->connect(@MOCK_DB_CONNECT_ARGS);
    my $st2 = $db2->prepare('SELECT ?, ?');

    for my $t (
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('') ],
            exp  => [],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT 1') ],
            exp  => [ {}, 'SELECT 1', 'SELECT 1', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT ?') ],
            exp  => [ {}, 'SELECT ?', 'SELECT ?', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT ?1') ],
            exp  => [ { 1 => '?1' }, 'SELECT ?', 'SELECT ?1', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT :1') ],
            exp  => [ { 1 => ':1' }, 'SELECT ?', 'SELECT :1', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT $1') ],
            exp  => [ { 1 => '$1' }, 'SELECT ?', 'SELECT $1', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT :foo') ],
            exp  => [ { 1 => ':foo' }, 'SELECT ?', 'SELECT :foo', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT ?, ?') ],
            exp  => [ {}, 'SELECT ?, ?', 'SELECT ?, ?', 'DETERMINISTIC-DIGEST' ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT ?1, ?2') ],
            exp  => [
                { 1 => '?1', 2 => '?2' }, 'SELECT ?, ?', 'SELECT ?1, ?2',
                'DETERMINISTIC-DIGEST',
            ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT :1, :2') ],
            exp  => [
                { 1 => ':1', 2 => ':2' }, 'SELECT ?, ?', 'SELECT :1, :2',
                'DETERMINISTIC-DIGEST',
            ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT $1, $2') ],
            exp  => [
                { 1 => '$1', 2 => '$2' }, 'SELECT ?, ?', 'SELECT $1, $2',
                'DETERMINISTIC-DIGEST',
            ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study('SELECT :foo, :bar') ],
            exp  => [
                { 1 => ':foo', 2 => ':bar' }, 'SELECT ?, ?', 'SELECT :foo, :bar',
                'DETERMINISTIC-DIGEST',
            ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study($st1) ],
            exp  => [
                { 1 => ':foo', 2 => ':bar' }, 'SELECT ?, ?', 'SELECT :foo, :bar',
                'DETERMINISTIC-DIGEST',
            ],
        },
        {
            line => __LINE__, name => "ok - statement_study",
            got  => [ statement_study($st2) ],
            exp  => [ {}, 'SELECT ?, ?', 'SELECT ?, ?', 'DETERMINISTIC-DIGEST' ],
        },
    ) {
        is_deeply(
            UNIVERSAL::isa( $t->{got}, 'CODE' ) ? $t->{got}->() : $t->{got},
            $t->{exp},
            sprintf( 'line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : '' ),
        );
    }

    $db2->disconnect();
    $db1->disconnect();
}


{
    db( DBIx::Squirrel->connect(@TEST_DB_CONNECT_ARGS) );

    my $artist_legacy_sql = 'SELECT * FROM artists WHERE ArtistId=? LIMIT 1';
    my $artist_legacy     = db->prepare($artist_legacy_sql);

    for my $s (
        'SELECT * FROM artists WHERE ArtistId=? LIMIT 1',
        [
            'SELECT * FROM artists',
            'WHERE ArtistId=? LIMIT 1',
        ],
        sub {
            'SELECT * FROM artists WHERE ArtistId=? LIMIT 1';
        },
        sub { [
            'SELECT * FROM artists',
            'WHERE ArtistId=? LIMIT 1',
        ] },
    ) {
        my $artist_legacy = db->prepare($s);
        my $n             = ( $_ = ref $s ) ? "${_}REF" : 'string';
        for my $t (
            {
                line => __LINE__, name => "ok - statement as $n internal state",
                got  => [ length( $artist_legacy->_private_state->{Hash} ) ],
                exp  => [43],
            },    ## 43-char Base64 string
            {
                line => __LINE__, name => "ok - statement as $n internal state",
                got  => [ $artist_legacy->_private_state->{NormalisedStatement} ],
                exp  => [$artist_legacy_sql],
            },
            {
                line => __LINE__, name => "ok - statement as $n internal state",
                got  => [ $artist_legacy->_private_state->{OriginalStatement} ],
                exp  => [$artist_legacy_sql],
            },
            {
                line => __LINE__, name => "ok - statement as $n internal state",
                got  => [ $artist_legacy->_private_state->{Placeholders} ],
                exp  => [ {} ],
            },
        ) {
            is_deeply(
                UNIVERSAL::isa( $t->{got}, 'CODE' ) ? $t->{got}->() : $t->{got},
                $t->{exp},
                sprintf( 'line %d%s', $t->{line}, $t->{name} ? " - $t->{name}" : '' ),
            );
        }
    }

    is(
        $artist_legacy->{Statement}, $artist_legacy_sql,
        'ok - normalised (? placeholders)',
    );
    is $artist_legacy->execute(3), '0E0', 'ok - execute';

SKIP:
    {
        if ( SQLite_is_too_old() ) {
            skip "DBD\::SQLite too old for ParamValues check", 1;
        }
        is_deeply(
            $artist_legacy->{ParamValues}, { 1 => 3 },
            'ok - statement ParamValues',
        );
    }

    my $artist_named = db->prepare(
        'SELECT * FROM artists WHERE ArtistId=:id LIMIT 1',
    );

    is $artist_named->{Statement}, $artist_legacy_sql,
        'ok - normalised (:named placeholders)';

    is(
        $artist_named->execute( id => 3 ), '0E0',
        'ok - execute (named placeholder, bind key-value list)',
    );
    is(
        $artist_named->fetchrow_hashref->{Name}, 'Aerosmith',
        'ok - fetchrow_hashref',
    );

    is(
        $artist_named->execute( { id => 3 } ), '0E0',
        'ok - execute (named placeholder, bind key-value hashref)',
    );
    is(
        $artist_named->fetchrow_arrayref->[1], 'Aerosmith',
        'ok - fetchrow_arrayref',
    );

    is(
        $artist_named->execute( [ id => 3 ] ), '0E0',
        'ok - execute (named placeholder, bind key-value arrayref)',
    );
    is(
        $artist_named->fetchrow_hashref->{Name}, 'Aerosmith',
        'ok - fetchrow_hashref',
    );

    is(
        $artist_named->execute( ':id' => 3 ), '0E0',
        'ok - execute (named placeholder, bind :key-value list)',
    );
    is(
        $artist_named->fetchrow_arrayref->[1], 'Aerosmith',
        'ok - fetchrow_arrayref',
    );

    is(
        $artist_named->execute( { ':id' => 3 } ), '0E0',
        'ok - execute (named placeholder, bind :key-value hashref)',
    );
    is(
        $artist_named->fetchrow_hashref->{Name}, 'Aerosmith',
        'ok - fetchrow_hashref',
    );

    is(
        $artist_named->execute( [ ':id' => 3 ] ), '0E0',
        'ok - execute (named placeholder, bind :key-value arrayref)',
    );
    is(
        $artist_named->fetchrow_arrayref->[1], 'Aerosmith',
        'ok - fetchrow_arrayref',
    );

    warnings_exist { $artist_named->execute(3) } (
        [ qr/Check bind values/, qr/Odd number of elements/ ],
        'ok - warning on odd number of bind values',
    );

SKIP:
    {
        if ( SQLite_is_too_old() ) {
            skip "DBD\::SQLite too old for ParamValues check", 1;
        }
        is_deeply(
            $artist_named->{ParamValues}, { 1 => 3 },
            'ok - statement ParamValues',
        );
    }

    is $artist_named->execute( ":id" => 3 ), '0E0', 'ok - execute';

    my $artist_numbered = db->prepare( [
        'SELECT * FROM artists',
        'WHERE ArtistId=:1 LIMIT 1',
    ] );

    is(
        $artist_numbered->{Statement}, $artist_legacy_sql,
        'ok - normalised (:n placeholders)',
    );
    is $artist_numbered->execute(3), '0E0', 'ok - execute';

SKIP:
    {
        if ( SQLite_is_too_old() ) {
            skip "DBD\::SQLite too old for ParamValues check", 1;
        }
        is_deeply(
            $artist_numbered->{ParamValues}, { 1 => 3 },
            'ok - statement ParamValues',
        );
    }

    my $artist_pg = db->prepare('SELECT * FROM artists WHERE ArtistId=$1 LIMIT 1');
    is(
        $artist_pg->{Statement}, $artist_legacy_sql,
        'ok - normalised ($n placeholders)',
    );
    is $artist_pg->execute(3), '0E0', 'ok - execute';

SKIP:
    {
        if ( SQLite_is_too_old() ) {
            skip "DBD\::SQLite too old for ParamValues check", 1;
        }
        is_deeply $artist_pg->{ParamValues}, { 1 => 3 }, 'ok - statement ParamValues';
    }

    my $artist_sqlite = db->prepare( sub { [
        'SELECT * FROM artists',
        'WHERE ArtistId=?1 LIMIT 1',
    ] } );
    is(
        $artist_sqlite->{Statement}, $artist_legacy->{Statement},
        'ok - normalised (?n placeholders)',
    );
    is( $artist_sqlite->execute(3), '0E0', 'ok - execute' );

SKIP:
    {
        if ( SQLite_is_too_old() ) {
            skip "DBD\::SQLite too old for ParamValues check", 1;
        }
        is_deeply(
            $artist_sqlite->{ParamValues}, { 1 => 3 },
            'ok - statement ParamValues',
        );
    }

    artists( db->prepare('SELECT * FROM artists') );
    is(
        artists->{Statement}, 'SELECT * FROM artists',
        'ok - statement helper',
    );

    artist($artist_legacy);

    is artist->{Statement}, $artist_legacy_sql, 'ok - statement helper';
    is_deeply(
        artist->fetchrow_arrayref, [ 3, 'Aerosmith' ],
        'ok - fetchrow_arrayref',
    );
    is_deeply artist->fetchrow_arrayref, undef, 'ok - fetchrow_arrayref exhausted';
    ok !artist->{Active}, 'ok - statement not Active';
    is artist(128), '0E0', 'ok - execute';

SKIP:
    {
        if ( SQLite_is_too_old() ) {
            skip "DBD\::SQLite too old for ParamValues check", 1;
        }
        is_deeply artist->{ParamValues}, { 1 => 128 }, 'ok - statement ParamValues';
    }

    ok artist->{Active}, 'ok - statement Active';
    is_deeply(
        artist->fetchrow_hashref, { ArtistId => 128, Name => 'Rush' },
        'ok - fetchrow_hashref',
    );
    is_deeply( artist->fetchrow_hashref, undef, 'ok - fetchrow_hashref exhausted' );
    ok !artist->{Active}, 'statement not Active';
}

done_testing();
