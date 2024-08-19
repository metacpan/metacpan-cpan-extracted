BEGIN {
    delete $INC{'FindBin.pm'};
    require FindBin;
}

use autobox::Core;
use Test::Most;
use Capture::Tiny 'capture_stdout', 'capture_stderr', 'capture';
use Cwd 'realpath';
use DBIx::Squirrel::util ':all';
use DBIx::Squirrel;

use lib realpath("$FindBin::Bin/../lib");
use T::Database ':all';

our (
    $sql, $sth, $res, $got, @got, $exp, @exp, $row, $dbh, $it, $stdout,
    $stderr, @hashrefs, @arrayrefs, $standard_dbi_dbh, $standard_ekorn_dbh,
    $cached_ekorn_dbh,
);

test_the_basics();

ok 1, __FILE__ . ' complete';
done_testing;

sub test_the_basics
{

    diag "";
    diag "Test the basics";
    diag "";

    # Check that "whine" emits warnings

    ( $exp, $got ) = (
        99,
        do {
            ($stderr) = capture_stderr {
                whine 'Got a warning';
            };
            99;
        },
    );
    is $got, $exp, 'whine';
    like $stderr, qr/Got a warning at/, 'whine';

    ($stderr) = capture_stderr {
        whine 'Got %s warning', 'another';
    };
    like $stderr, qr/Got another warning at/, 'whine';

    # Check that "throw" triggers exceptions

    throws_ok { throw 'An error' } ( qr/An error at/, 'throw' );
    throws_ok { throw '%s error', 'Another' } ( qr/Another error at/, 'throw' );

    # Check that "DBIx::Squirrel::dr::_is_dbh" does its thing

    $standard_dbi_dbh = DBI->connect(@T_DB_CONNECT_ARGS);

    # Check that we can open standard and cached DBIx::Squirrel::db
    # connections

    $standard_ekorn_dbh = DBIx::Squirrel->connect(@T_DB_CONNECT_ARGS);
    isa_ok $standard_ekorn_dbh, 'DBIx::Squirrel::db';

    $cached_ekorn_dbh = DBIx::Squirrel->connect_cached(@T_DB_CONNECT_ARGS);
    isa_ok $cached_ekorn_dbh, 'DBIx::Squirrel::db';

    # Check that "DBIx::Squirrel::db::study_statement" works properly

    ( $exp, $got ) = (
        [
            undef,
            'SELECT * FROM table WHERE col = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col = ?'),
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col = ? ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            undef,
            'SELECT * FROM table WHERE col1 = ? AND col2 = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col1 = ? AND col2 = ?'),
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col1 = ? AND col2 = ? ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => '$1',
            },
            'SELECT * FROM table WHERE col = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col = $1')
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col = $1 ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => '$1',
                2 => '$2',
            },
            'SELECT * FROM table WHERE col1 = ? AND col2 = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col1 = $1 AND col2 = $2')
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col1 = $1 AND col2 = $2 ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => '?1',
            },
            'SELECT * FROM table WHERE col = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col = ?1')
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col = ?1 ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => '?1',
                2 => '?2',
            },
            'SELECT * FROM table WHERE col1 = ? AND col2 = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col1 = ?1 AND col2 = ?2')
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col1 = ?1 AND col2 = ?2 ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => ':1',
            },
            'SELECT * FROM table WHERE col = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col = :1')
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col = :1 ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => ':1',
                2 => ':2',
            },
            'SELECT * FROM table WHERE col1 = ? AND col2 = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col1 = :1 AND col2 = :2'),
        ],
        do {
            [
                study_statement(' SELECT * FROM table WHERE col1 = :1 AND col2 = :2 '),
            ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => ':n',
            },
            'SELECT * FROM table WHERE col = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col = :n'),
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col = :n ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            {
                1 => ':n1',
                2 => ':n2',
            },
            'SELECT * FROM table WHERE col1 = ? AND col2 = ?',
            get_trimmed_sql_and_digest('SELECT * FROM table WHERE col1 = :n1 AND col2 = :n2')
        ],
        do {
            [ study_statement(' SELECT * FROM table WHERE col1 = :n1 AND col2 = :n2 ') ];
        },
    );
    is_deeply $got, $exp, 'study_statement'
      or dump_val { exp => $exp, got => $got };

    # Check that "DBIx::Squirrel::st::_placeholders_are_positional"
    # works properly

    ( $exp, $got ) = (
        undef,
        DBIx::Squirrel::st::_placeholders_are_positional(undef),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        undef,
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => ':name',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        undef,
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => ':name',
                2 => ':2',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        {
            1 => ':1',
        },
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => ':1',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        {
            1 => ':1',
            2 => ':2'
        },
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => ':1',
                2 => ':2',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        {
            1 => ':1',
        },
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => ':1',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        {
            1 => '$1',
            2 => '$2'
        },
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => '$1',
                2 => '$2',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        {
            1 => '?1',
            2 => '?2'
        },
        DBIx::Squirrel::st::_placeholders_are_positional(
            {
                1 => '?1',
                2 => '?2',
            }
        ),
    );
    is_deeply $got, $exp, '_placeholders_are_positional'
      or dump_val { exp => $exp, got => $got };

    # Check that "DBIx::Squirrel::st::_map_placeholders_to_values" works

    ( $exp, $got ) = (
        [],
        [DBIx::Squirrel::st::_map_placeholders_to_values(undef)],
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [ 'a', 'b' ],
        [
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    undef,
                    ( 'a', 'b' ),
                )
            }
        ],
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { '?1' => 'a', '?2' => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1 => '?1', 2 => '?2' },
                    ( 'a', 'b' ),
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { '$1' => 'a', '$2' => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1 => '$1', 2 => '$2' },
                    ( 'a', 'b' ),
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { ':1' => 'a', ':2' => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1 => ':1', 2 => ':2' },
                    ( 'a', 'b' ),
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { ':n1' => 'a', ':n2' => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1 => ':n1', 2 => ':n2' },
                    ( ':n1' => 'a', ':n2' => 'b' ),
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { n1 => 'a', n2 => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1 => ':n1', 2 => ':n2' },
                    ( n1 => 'a', n2 => 'b' ),
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { n1 => 'a', n2 => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1 => ':n1', 2 => ':n2' },
                    [ n1 => 'a', n2 => 'b' ],
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { n1 => 'a', n2 => 'b' },
        {
            @{
                DBIx::Squirrel::st::_map_placeholders_to_values(
                    { 1    => ':n1', 2    => ':n2' },
                    { n1 => 'a',   n2 => 'b' },
                )
            }
        },
    );
    is_deeply $got, $exp, '_map_placeholders_to_values'
      or dump_val { exp => $exp, got => $got };

    # Check that "DBIx::Squirrel::st::bind_param" works properly

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = ?',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( 1 => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = ?1',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( '?1' => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( 1 => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = $1',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( '$1' => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( 1 => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = :1',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( ':1' => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( 1 => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = :name',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( ':name' => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( name => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        { $sth->bind_param( 1 => 'AAC audio file' ) },
    );
    is_deeply $got, $exp, 'bind_param'
      or dump_val { exp => $exp, got => $got };

    # Check the "DBIx::Squirrel::st::bind" works properly

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = ?',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind('AAC audio file');
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = ?1',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind('AAC audio file');
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = $1',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind('AAC audio file');
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = :1',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind('AAC audio file');
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = :name',
        )
    );

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind( ':name' => 'AAC audio file' );
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind( { ':name' => 'AAC audio file' } );
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind( [ ':name' => 'AAC audio file' ] );
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind( name => 'AAC audio file' );
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind( { name => 'AAC audio file' } );
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { 1 => 'AAC audio file' },
        do {
            $res = $sth->bind( [ name => 'AAC audio file' ] );
            is $res, $sth, 'bind';
            $sth->{ParamValues};
        },
    );
    is_deeply $got, $exp, 'bind'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE Name = :name',
        )
    );

    $it = $sth->it( name => 'AAC audio file' )->_maxrows(10);
    isa_ok $it, 'DBIx::Squirrel::it';

    ( $exp, $got ) = (
        bless( { MaxRows => 10, Slice => [], }, 'DBIx::Squirrel::it' ),
        $it,
    );
    is_deeply $got, $exp, 'iterate'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        {
            Iterator   => $it,
            Placeholders => {
                1 => ":name",
            },
            OriginalStatement   => "SELECT * FROM media_types WHERE Name = :name",
            NormalisedStatement => "SELECT * FROM media_types WHERE Name = ?",
            Hash => DBIx::Squirrel::util::hash_sql_string("SELECT * FROM media_types WHERE Name = :name"),
        },
        $sth->{private_ekorn},
    );
    is_deeply $got, $exp, 'iterate'
      or dump_val { exp => $exp, got => $got };

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
        )
    );

    $it = $sth->it;

    ( $exp, $got ) = (
        [ 1, 'MPEG audio file' ],
        do {
            diag "";
            diag "THE FOLLOWING WARNING IS EXPECTED";
            diag "";
            $it->single;
        }
    );
    is_deeply $got, $exp, 'single'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [ 1, 'MPEG audio file' ],
        $it->first,
    );
    is_deeply $got, $exp, 'first'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { MediaTypeId => 1, Name => "MPEG audio file" },
        do {
            $it->reset( {} );
            $it->first;
        },
    );
    is_deeply $got, $exp, 'first'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { MediaTypeId => 1, Name => "MPEG audio file" },
        $it->first( {} ),
    );
    is_deeply $got, $exp, 'first'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        { MediaTypeId => 2, Name => "Protected AAC audio file" },
        $it->next,
    );
    is_deeply $got, $exp, 'next'
      or dump_val { exp => $exp, got => $got };

    $sth->finish;

    $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
            'WHERE MediaTypeId = :id',
        )
    );

    $it = $sth->it( id => 1 );

    ( $exp, $got ) = (
        [ 1, 'MPEG audio file' ],
        $it->single,
    );
    is_deeply $got, $exp, 'single'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [ 5, 'AAC audio file' ],
        $it->single( id => 5 ),
    );
    is_deeply $got, $exp, 'single'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [ 1, 'MPEG audio file' ],
        $it->single,
    );
    is_deeply $got, $exp, 'single'
      or dump_val { exp => $exp, got => $got };

    my $sth = $standard_ekorn_dbh->prepare(
        join ' ', (
            'SELECT *',
            'FROM media_types',
        )
    );

    ( $exp, $got ) = (
        bless( { MaxRows => 100, Slice => {} }, 'DBIx::Squirrel::rs' ),
        do {
            my $sth = $standard_ekorn_dbh->prepare(
                join ' ', (
                    'SELECT *',
                    'FROM media_types',
                )
            );
            $sth->rs->reset( {}, 100 );
        },
    );
    is_deeply $got, $exp, 'results'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        bless( { MaxRows => 100, Slice => [] }, 'DBIx::Squirrel::rs' ),
        do {
            my $sth = $standard_ekorn_dbh->prepare(
                join ' ', (
                    'SELECT *',
                    'FROM media_types',
                )
            );
            $sth->rs->reset( [], 100 );
        },
    );
    is_deeply $got, $exp, 'results'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        bless( { MaxRows => 10, Slice => [] }, 'DBIx::Squirrel::rs' ),
        $sth->rs->_maxrows(10),
    );
    is_deeply $got, $exp, 'results'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        bless( [ 1, "MPEG audio file" ], 'DBIx::Squirrel::rs' ),
        $sth->rs->first,
    );
    is_deeply $got, $exp, 'first'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            [
                1,
                "MPEG audio file",
            ],
            [
                2,
                "Protected AAC audio file",
            ],
            [
                3,
                "Protected MPEG-4 video file",
            ],
            [
                4,
                "Purchased AAC audio file",
            ],
            [
                5,
                "AAC audio file",
            ],
        ],
        ,
        do {
            [ $sth->rs->all ];
        },
    );
    is_deeply $got, $exp, 'all'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        5,
        do {
            my $res = $sth->rs;
            $res->count;
        },
    );
    is_deeply $got, $exp, 'count'
      or dump_val { exp => $exp, got => $got };

    ( $exp, $got ) = (
        [
            'MPEG audio file',
            'Protected AAC audio file',
            'Protected MPEG-4 video file',
            'Purchased AAC audio file',
            'AAC audio file',
        ],
        do {
            $sth->finish;
            $sth = $standard_ekorn_dbh->prepare(
                'SELECT MediaTypeId, Name FROM media_types',
            );
            $res = $sth->rs( sub { $_[0]->get_column('Name') } );
            my @ary;
            push @ary, $_ while $res->next;
            \@ary;
        },
    );
    is_deeply $got, $exp, 'rs, get_column'
      or dump_val { exp => $exp, got => $got };

    $it = $sth->it( sub { $_->{Name} } )->reset( {} );
    diag "$_\n" for $it->all;

    diag "$_\n" for $standard_ekorn_dbh->rs(
        'SELECT MediaTypeId, Name FROM media_types',
        sub { $_->Name },
        sub { "Media type: $_" },
    )->all;

    diag "$_\n" for $standard_ekorn_dbh->select('media_types')->rs(
        sub { $_->Name },
        sub { "Media type: $_" },
    )->all;

    $standard_ekorn_dbh->disconnect;
    $standard_dbi_dbh->disconnect;

    return;
}
