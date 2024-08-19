BEGIN {
    delete $INC{'FindBin.pm'};
    require FindBin;
}

use Test::Most;
use Capture::Tiny ('capture_merged', 'capture_stdout', 'capture_stderr', 'capture', 'tee_merged', 'tee_stdout',
    'tee_stderr', 'tee',);
use Cwd 'realpath';
use Data::Dumper::Concise;
use DBI;
use DBIx::Squirrel::util (':all');
use DBIx::Squirrel       (':utils', database_entities => ['db', 'st', 'it', 'rs', 'artist', 'artists'],);

use lib realpath("$FindBin::Bin/../lib");
use T::Database ':all';

our($stdout, $stderr, $merged);
our($res,    @res);
our($got,    $exp);
our(@arr,    %hash);
our($aref,   $href);
our($cref,   $crefs);
our(@args);

subtest get_trimmed_sql_and_digest => sub {
    is(get_trimmed_sql_and_digest("  \n\t  SELECT * \nFROM t  \n  "), "SELECT *\nFROM t");
};

subtest connect => sub {
    no strict 'subs';    ## no critic

    my $dbi_dbh = DBI->connect(@T_DB_CONNECT_ARGS);
    my $dbi_sth = $dbi_dbh->prepare("  SELECT * FROM media_types  ");
    $dbi_dbh->disconnect;

    my $ekorn_dbh = DBIx::Squirrel->connect(@T_DB_CONNECT_ARGS);
    my $ekorn_sth = $ekorn_dbh->prepare('  SELECT COUNT(*) AS foo FROM media_types  ');

    ok(!defined(db));
    db $ekorn_dbh;
    isa_ok(db, 'DBIx::Squirrel::db');
    undef $DBIx::Squirrel::db;

    ok(!defined(st));
    st $ekorn_sth;
    isa_ok(st, 'DBIx::Squirrel::st');
    undef $DBIx::Squirrel::st;

    ok(!defined(it));
    it $ekorn_sth->it;
    isa_ok(it, 'DBIx::Squirrel::it');
    undef $DBIx::Squirrel::it;

    ok(!defined(rs));
    rs $ekorn_sth->rs;
    isa_ok(rs, 'DBIx::Squirrel::rs');
    undef $DBIx::Squirrel::rs;

    ok(defined(&neat));
    is(neat('foo'), "'foo'");

    $ekorn_dbh->disconnect;
};

subtest example_1 => sub {
    db do {DBIx::Squirrel->connect(@T_DB_CONNECT_ARGS)};
    isa_ok(db, 'DBIx::Squirrel::db');

    # Using the "db" association, associate the "artists" and "artist"
    # helpers with their prepared statements:

    artists do {db->results('SELECT * FROM artists')};
    isa_ok(artists, 'DBIx::Squirrel::rs');

    artist do {
        db->results(
            'SELECT * FROM artists WHERE Name=? LIMIT 1' => sub {
                my $row = $_;
                print STDERR "# -- ", $row->ArtistId, ": ", $row->Name, " --\n";
                return $row;
            }
        );
    };

    isa_ok(artist, 'DBIx::Squirrel::rs');

    # Have the statement helpers to execute their queries.

    @arr = artists->all;
    is($arr[0]->Name,  'AC/DC');
    is($arr[-1]->Name, 'Philip Glass Ensemble');
    artist('Aerosmith')->single;
    is($_->ArtistId, 3);

    db->disconnect;
};

subtest normalise_statement => sub {
    undef $DBIx::Squirrel::NORMALISE_SQL;

    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = ?   '),
        'SELECT * FROM media_types WHERE MediatypeId = ?',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = ?1   '),
        'SELECT * FROM media_types WHERE MediatypeId = ?1',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = $1   '),
        'SELECT * FROM media_types WHERE MediatypeId = $1',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = :1   '),
        'SELECT * FROM media_types WHERE MediatypeId = :1',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = :id   '),
        'SELECT * FROM media_types WHERE MediatypeId = :id',
    );

    $DBIx::Squirrel::NORMALISE_SQL = 1;

    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = ?1 AND Name = ?2   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = $1 AND Name = $2   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is( normalise_statement('   SELECT * FROM media_types WHERE MediatypeId = :1 AND Name = :2   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
};

subtest cbargs => sub {
    %hash = (
        sub1 => sub {1},
        sub2 => sub {2},
    );

    is_deeply([cbargs(1 .. 5)], [[], 1 .. 5]);

    is_deeply([cbargs(1 .. 5, $hash{sub1})], [[$hash{sub1}], 1 .. 5],);

    is_deeply([cbargs(1 .. 5, $hash{sub1}, $hash{sub2})], [[$hash{sub1}, $hash{sub2},], 1 .. 5],);
};

subtest cbargs_using => sub {
    %hash = (
        sub1 => sub {1},
        sub2 => sub {2},
    );

    is_deeply([cbargs_using(undef, 1 .. 5)], [[], 1 .. 5]);

    is_deeply([cbargs_using([], 1 .. 5)], [[], 1 .. 5]);

    is_deeply([cbargs_using([], 1 .. 5, $hash{sub1})], [[$hash{sub1}], 1 .. 5],);

    is_deeply([cbargs_using([], 1 .. 5, $hash{sub1}, $hash{sub2})], [[$hash{sub1}, $hash{sub2},], 1 .. 5],);

    is_deeply([cbargs_using([$hash{sub2}], 1 .. 5, $hash{sub1},)], [[$hash{sub1}, $hash{sub2},], 1 .. 5],);
};

subtest transform => sub {
    is_deeply([transform()], []);

    is_deeply([transform([])], []);

    is_deeply([transform([], 99)], [99]);

    is_deeply([transform([], 98, 99)], [98, 99]);

    is_deeply([transform(sub {$_ + 1}, 99)], [100],);

    is_deeply([transform(sub {$_[0] + 1}, 99)], [100],);

    is_deeply([transform([sub {$_ + 1}], 99)], [100],);

    is_deeply([transform([sub {$_[0] + 1}], 99)], [100],);

    is_deeply([
            transform(
                [sub {
                    map {$_ + 1} @_;
                }],
                98,
                99,
            )
        ],
        [99, 100],
    );

    is_deeply([transform([sub {$_ + 1}, sub {$_ - 2},], 99,)], [98],);

    is_deeply([transform([sub {$_[0] + 1}, sub {$_[0] - 2},], 99,)], [98],);

    is_deeply([
            transform([
                    sub {
                        map {$_ + 1} @_;
                    },
                    sub {
                        map {$_ - 2} @_;
                    },
                ],
                98,
                99,
            )
        ],
        [97, 98],
    );
};

subtest throw => sub {
    eval {throw undef};
    like($@, qr/\AException at /);

    eval {throw 'Got an exception'};
    like($@, qr/\AGot an exception at /);

    eval {throw 'Exception %d, %d, %d', 1, 2, 3};
    like($@, qr/\AException 1, 2, 3 at/);

    eval {
        $@ = 'Rethrow this';
        throw;
    };
    like($@, qr/\ARethrow this at/);
};

subtest whine => sub {
    $stderr = capture_stderr {whine undef};
    like($stderr, qr/\AWarning at /);

    $stderr = capture_stderr {whine 'Got a warning'};
    like($stderr, qr/\AGot a warning at /);

    $stderr = capture_stderr {whine 'Warning %d, %d, %d', 1, 2, 3};
    like($stderr, qr/\AWarning 1, 2, 3 at/);

    $stderr = capture_stderr {whine};
    like($stderr, qr/\AWarning at/);
};

ok 1, __FILE__ . ' complete';
done_testing;
