use Test2::V0;
use Clone 'clone';
use DBIx::Query;

my $dq      = DBIx::Query->connect('dbi:SQLite:dbname=:memory:');
my $dq_ansi = DBIx::Query->connect( 'dbi:SQLite:dbname=:memory:', undef, undef, { dq_dialect => 'ANSI' } );

$_->do('CREATE TABLE user ( name TEXT )') for ( $dq, $dq_ansi );

my $structure;

like(
    warning { $structure = $dq_ansi->sql('SELECT * FROM user')->structure },
    qr/SQL reserved word/,
    'SQL reserved word warning under pure ANSI',
);

like( $structure->{errstr}, qr/SQL reserved word/, '"errstr" has SQL reserved word error' );

ok(
    no_warnings { $structure = $dq->sql('SELECT * FROM user')->structure },
    'No warnings under pseudo ANSI',
);

is( $structure->{errstr}, undef, 'TEST' );

$dq->do('CREATE TABLE movie ( open TEXT, final TEXT, west TEXT, east TEXT )');

my $insert = $dq->prepare('INSERT INTO movie ( open, final, west, east ) VALUES ( ?, ?, ?, ? )');

while ( <DATA> ) {
    chomp;
    $insert->execute( split(/\|/) );
}

# test_query($dq);
# test_crud($dq);
# test_where($dq);
# test_db_helper_methods($dq);
# test_run($dq);
# test_row_set_methods($dq);
# test_row_methods($dq);
# test_cell_methods($dq);

done_testing;

sub test_query {
    my ($dq) = @_;

    is(
        $dq->sql('SELECT west FROM movie WHERE open = ?')->run('Jul 1, 2011')->value,
        'Raising Arizona',
        '$dq->sql(...)->run(...)->value()',
    );
    is(
        $dq->get( 'movie', ['west'], { 'open' => 'Jul 1, 2011' } )->run->value,
        'Raising Arizona',
        '$dq->get(...)->run(...)->value()',
    );
    is(
        $dq->sql_uncached('SELECT west FROM movie WHERE open = ?')->run('Jul 1, 2011')->value,
        'Raising Arizona',
        '$dq->sql_uncached(...)->run(...)->value()',
    );
    is(
        $dq->get_uncached( 'movie', ['west'], { 'open' => 'Jul 1, 2011' } )->run->value,
        'Raising Arizona',
        '$dq->get_uncached(...)->run(...)->value()',
    );
}

sub test_crud {
    my ($dq) = @_;

    like(
        $dq->add(
            'movie',
            {
                'open'  => 'Jun 14, 2013',
                'final' => 'Jun 16, 2013',
                'west'  => 'Vertigo',
                'east'  => 'North by Northwest',
            },
        ),
        qr/^\d+$/,
        'add() succeeds and returns a primary key',
    );
    is(
        $dq->get( 'movie', ['west'], { 'open' => 'Jun 14, 2013' } )->run->value,
        'Vertigo',
        'add() data verified being in the database',
    );

    my $rv = $dq->update( 'movie', { 'west' => 'Another Earth' }, { 'open' => 'Jun 14, 2013' } );
    isa_ok( $rv, 'DBIx::Query::db' );
    is(
        $dq->get( 'movie', ['west'], { 'open' => 'Jun 14, 2013' } )->run->value,
        'Another Earth',
        'update() data verified being in the database',
    );

    $rv = $dq->rm( 'movie', { 'open' => 'Jun 14, 2013' } );
    isa_ok( $rv, 'DBIx::Query::db' );
    is(
        $dq->get( 'movie', ['west'], { 'open' => 'Jun 14, 2013' } )->run->value,
        undef,
        'rm() data verified being not in the database',
    );
}

sub test_where {
    my ($dq) = @_;

    is(
        scalar( $dq->get('movie')->where( 'final' => 'Aug 7, 2011' )->run->all({}) ),
        [{
            'open'  => 'Aug 5, 2011',
            'final' => 'Aug 7, 2011',
            'west'  => 'Indiana Jones and the Temple of Doom',
            'east'  => 'A Better Life'
        }],
        '$db->get($table)->where($where)',
    );

    is(
        $dq
            ->get('movie', undef, { 'final' => 'Aug 7, 2011' } )
            ->where( 'final' => 'Jul 17, 2011' )->run->all({}),
        [{
            'open'  => 'Jul 15, 2011',
            'final' => 'Jul 17, 2011',
            'west'  => 'Big Lebowski',
            'east'  => 'Midnight in Paris'
        }],
        '$db->get( $table, undef, $where )->where($where_change)',
    );

    is(
        $dq
            ->get('movie', undef, { 'final' => 'Aug 7, 2011' } )
            ->where( '"open"' => 'Aug 5, 2011' )->run->all({}),
        [{
            'open'  => 'Aug 5, 2011',
            'final' => 'Aug 7, 2011',
            'west'  => 'Indiana Jones and the Temple of Doom',
            'east'  => 'A Better Life'
        }],
        '$db->get( $table, undef, $where )->where($where_append)',
    );

    is(
        $dq
            ->get('movie', undef, { 'final' => 'Aug 7, 2011' } )
            ->where( '"open"' => 'Jul 15, 2011' )->run->all({}),
        [],
        '$db->get( $table, undef, $where )->where($where_addition)',
    );
}

sub test_db_helper_methods {
    my ($dq) = @_;

    is(
        $dq->fetch_value( 'movie', ['west'], { 'open' => 'Jul 1, 2011' } ),
        'Raising Arizona',
        '$dq->fetch_value()',
    );
    is(
        $dq->fetchall_arrayref( 'movie', ['west'], { 'open' => 'Jul 1, 2011' } ),
        [ ['Raising Arizona'] ],
        '$dq->fetchall_arrayref()',
    );
    is(
        $dq->fetchall_hashref( 'movie', ['west'], { 'open' => 'Jul 1, 2011' } ),
        [ { 'west' => 'Raising Arizona' } ],
        '$dq->fetchall_hashref()',
    );
    is(
        $dq->fetch_column_arrayref( 'movie', ['west'] ),
        [
            'Hunt for Red October',
            'Robots',
            'Raising Arizona',
            'Miller\'s Crossing',
            'Big Lebowski',
            'Super 8',
            'Raiders of the Lost Ark',
            'Indiana Jones and the Temple of Doom',
            'Indiana Jones and the Last Crusade',
            'Neverending Story',
            'Gladiator',
        ],
        '$dq->fetch_column_arrayref()',
    );
    is(
        $dq->fetchrow_hashref( 'SELECT west FROM movie WHERE open = ?', 'Jul 1, 2011' ),
        { 'west' => 'Raising Arizona' },
        '$dq->fetchrow_hashref()',
    );
}

sub test_run {
    my ($dq) = @_;

    is(
        $dq->sql(
            'SELECT west, east FROM movie WHERE open = ?',
            undef,
            undef,
            ['Jul 1, 2011'],
        )->run->all({}),
        [
            {
                'west' => 'Raising Arizona',
                'east' => 'There Be Dragons'
            }
        ],
        '$dq->sql( $sql, undef, undef, [$variable] )->run()->all({})',
    );

    is(
        $dq->sql('SELECT west, east FROM movie WHERE open = ?')->run('Jul 1, 2011')->all({}),
        [
            {
                'west' => 'Raising Arizona',
                'east' => 'There Be Dragons'
            }
        ],
        '$dq->sql($sql)->run($variable)->all({})',
    );
    is(
        $dq->get( 'movie', [ 'west', 'east' ], { 'open' => 'Jul 1, 2011' } )->run->all({}),
        [
            {
                'west' => 'Raising Arizona',
                'east' => 'There Be Dragons'
            }
        ],
        '$dq->get(...)->run()->all({})',
    );
}

sub test_row_set_methods {
    my ($dq) = @_;

    my $row_set = $dq->sql('SELECT * FROM movie')->run;

    is(
        $row_set->next->data,
        {
            'open' => 'Jun 17, 2011',
            'final' => 'Jun 19, 2011',
            'west' => 'Hunt for Red October',
            'east' => 'Jane Eyre'
        },
        '$dq->sql(...)->run()->next()->data()',
    );

    is(
        $row_set->next(2)->data,
        {
            'open' => 'Jul 8, 2011',
            'final' => 'Jul 10, 2011',
            'west' => 'Miller\'s Crossing',
            'east' => 'Forks Over Knives'
        },
        '$dq->sql(...)->run()->next(2)->data()',
    );

    is(
        $row_set->next(6)->data,
        {
            'open'  => 'Aug 26, 2011',
            'final' => 'Aug 28, 2011',
            'west'  => 'Gladiator',
            'east'  => 'The Trip',
        },
        '$dq->sql(...)->run()->next(6)->data()',
    );

    is(
        $row_set->next,
        undef,
        'next at end of data returns undef',
    );

    is(
        $dq->sql('SELECT west, east FROM movie WHERE east LIKE ?')->run('%he%')->all,
        [
            [ 'Raising Arizona', 'There Be Dragons' ],
            [ 'Gladiator', 'The Trip' ],
        ],
        '$dq->sql(...)->run(...)->all()',
    );

    is(
        $dq->sql('SELECT west, east FROM movie WHERE east LIKE ?')->run('%he%')->all({}),
        [
            {
                'west' => 'Raising Arizona',
                'east' => 'There Be Dragons'
            },
            {
                'west' => 'Gladiator',
                'east' => 'The Trip'
            }
        ],
        '$dq->sql(...)->run(...)->all({})',
    );

    my @rows;
    $dq
        ->sql('SELECT west, east FROM movie WHERE east LIKE ?')->run('%he%')
        ->each( sub { push( @rows, $_[0]->data ) } );
    is(
        \@rows,
        [
            {
                'west' => 'Raising Arizona',
                'east' => 'There Be Dragons'
            },
            {
                'west' => 'Gladiator',
                'east' => 'The Trip'
            }
        ],
        '$dq->sql(...)->run(...)->each( sub {...} )',
    );

    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('Jane Eyre')->value,
        'Hunt for Red October',
        '$dq->sql(...)->run(...)->value() in scalar context',
    );

    is(
        [ $dq->sql('SELECT west, east FROM movie WHERE east = ?')->run('Jane Eyre')->value ],
        [ 'Hunt for Red October', 'Jane Eyre' ],
        '$dq->sql(...)->run(...)->value() in list context',
    );

    is(
        [ $dq->sql('SELECT * FROM movie')->run->first ],
        [ [
            'Jun 17, 2011',
            'Jun 19, 2011',
            'Hunt for Red October',
            'Jane Eyre',
        ] ],
        'first()',
    );

    is(
        [ $dq->sql('SELECT * FROM movie')->run->first({}) ],
        [ {
            east  => 'Jane Eyre',
            final => 'Jun 19, 2011',
            open  => 'Jun 17, 2011',
            west  => 'Hunt for Red October',
        } ],
        'first({})',
    );

    my $titles = [
        'Hunt for Red October',
        'Robots',
        'Raising Arizona',
        q{Miller's Crossing},
        'Big Lebowski',
        'Super 8',
        'Raiders of the Lost Ark',
        'Indiana Jones and the Temple of Doom',
        'Indiana Jones and the Last Crusade',
        'Neverending Story',
        'Gladiator',
    ];

    is(
        [ $dq->sql('SELECT west FROM movie')->run->column ],
        $titles,
        'column() array context',
    );

    is(
        scalar( $dq->sql('SELECT west FROM movie')->run->column ),
        $titles,
        'column() scalar context',
    );
}

sub test_row_methods {
    my ($dq) = @_;

    is(
        $dq
            ->sql('SELECT * FROM movie WHERE east = ?')
            ->run('There Be Dragons')->next->cell('west')->value,
        'Raising Arizona',
        q{$dq->sql('SELECT * FROM ...')->run(...)->next()->cell($name)->value()},
    );

    is(
        $dq->get('movie')->run->next(2)->cell('west')->value,
        'Raising Arizona',
        '$dq->get(...)->run(...)->next(2)->cell($name)->value()',
    );

    is(
        $dq
            ->sql('SELECT east, west FROM movie WHERE east = ?')
            ->run('There Be Dragons')->next->cell(1)->value,
        'Raising Arizona',
        q{$dq->sql('SELECT a, b FROM ...')->run($name)->next()->cell($integer)->value()},
    );

    is(
        $dq->get('movie')->run->next(2)->cell( 'west', 'New Value' )->value,
        'New Value',
        '$dq->get(...)->run(...)->next(2)->cell( $name, $new_value )->value()',
    );

    my @titles;
    $dq
        ->sql('SELECT east, west FROM movie WHERE east = ?')
        ->run('There Be Dragons')->next->each( sub { push @titles, $_[0]->value } );
    is(
        \@titles,
        [ 'There Be Dragons', 'Raising Arizona' ],
        '$dq->sql(...)->run(...)->next()->each( sub { ... } )',
    );

    is(
        $dq->sql('SELECT east, west FROM movie')->run->next->data,
        {
            'west' => 'Hunt for Red October',
            'east' => 'Jane Eyre',
        },
        '$dq->sql(...)->run()->next()->data()',
    );

    is(
        $dq->sql('SELECT east, west FROM movie')->run->next->row,
        [
            'Jane Eyre',
            'Hunt for Red October',
        ],
        '$dq->sql(...)->run()->next()->row()',
    );

    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('There Be Dragons')->value,
        'Raising Arizona',
        '$db->sql(...)->run(...)->value() test original value',
    );

    my $sth = $dq->sql('SELECT "open", west FROM movie WHERE "open" = ?');
    $sth->run('Jul 1, 2011')->next->cell( 'west', 'Iron Man' )->up->save('"open"');

    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('There Be Dragons')->value,
        'Iron Man',
        '$db->sql(...)->run(...)->value() test changed value 1',
    );

    $sth->run('Jul 1, 2011')->next->save( '"open"', { 'west' => 'Star Wars' }, 0 );
    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('There Be Dragons')->value,
        'Star Wars',
        '$db->sql(...)->run(...)->value() test changed value 2',
    );

    $sth->run('Jul 1, 2011')->next->save( '"open"', { 'west' => 'Raising Arizona' } );
    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('There Be Dragons')->value,
        'Raising Arizona',
        '$db->sql(...)->run(...)->value() reset original value',
    );
}

sub test_cell_methods {
    my ($dq) = @_;

    my $cell = $dq
        ->sql('SELECT "open", final, west FROM movie WHERE east = ?')
        ->run('There Be Dragons')->next->cell('west');

    is(
        $cell->name,
        'west',
        '$dq->sql(...)->run(...)->next()->cell(...)->name()',
    );

    is(
        $cell->value,
        'Raising Arizona',
        '$dq->sql(...)->run(...)->next()->cell(...)->value()',
    );

    is(
        $cell->index,
        2,
        '$dq->sql(...)->run(...)->next()->cell(...)->index()',
    );

    my $row = $cell->save( '"open"', { 'west' => 'Star Wars' } );
    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('There Be Dragons')->value,
        'Star Wars',
        '$db->sql(...)->run(...)->next()->cell(...)->save() test changed value',
    );

    $row->cell('west')->save( '"open"', { 'west' => 'Raising Arizona' } );
    is(
        $dq->sql('SELECT west FROM movie WHERE east = ?')->run('There Be Dragons')->value,
        'Raising Arizona',
        '$db->sql(...)->run(...)->next()->cell(...)->save() reset original value',
    );
}

__DATA__
Jun 17, 2011|Jun 19, 2011|Hunt for Red October|Jane Eyre
Jun 24, 2011|Jun 26, 2011|Robots|Meek's Cutoff
Jul 1, 2011|Jul 3, 2011|Raising Arizona|There Be Dragons
Jul 8, 2011|Jul 10, 2011|Miller's Crossing|Forks Over Knives
Jul 15, 2011|Jul 17, 2011|Big Lebowski|Midnight in Paris
Jul 22, 2011|Jul 24, 2011|Super 8|Midnight in Paris
Jul 29, 2011|Jul 31, 2011|Raiders of the Lost Ark|Tree of Life
Aug 5, 2011|Aug 7, 2011|Indiana Jones and the Temple of Doom|A Better Life
Aug 12, 2011|Aug 14, 2011|Indiana Jones and the Last Crusade|First Grader
Aug 19, 2011|Aug 21, 2011|Neverending Story|Buck
Aug 26, 2011|Aug 28, 2011|Gladiator|The Trip
