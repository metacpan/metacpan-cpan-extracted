use Test2::V0;
use Bible::Reference;

my $obj;
ok( lives { $obj = Bible::Reference->new }, 'new' ) or note $@;
isa_ok( $obj, 'Bible::Reference' );

my $test_data = [
    undef,
    0,
    '',
    'Text with no Reference 3:16 data included',
    'Text Samuel 3:15 said in 1 Samuel 4:16 that 2 Samuel 3-5 was as clear as 1 Peter in full',
    'Text Pet text II Pet text II Pet 3:15 text 2pt 3-4 text ' .
        '2 Peter 3:15-17, 18, 20-22, 2 Peter 5:1 text',
    'The book of rev. The verse of rEv. 3:15. The book of Rev.',
    'Books of Revel, Gal, and Roma exist',
    'Verses Mark 12:4 and Mark 12:3-5 and Mark 12:4-7, 13:1-2 and Genesis 4:1 and Genesis 1:2 exist',
    'Mark 3:15-17, Ps 117, 3 John, Mark 3:6, 20-23, Mark 4-5',
    'A = Matthew 1:18-25, 2-12, 14-22, 28-26 = A',
    'B = Romans, James = B',
    'C = Acts 1-20 = C',
    'D = Galatians, Ephesians, Philippians, Colossians = D',
    'E = Luke 1-3:23, 9-11, 13-19, 21-24 = E',
    'F = 1 Corinthians, 2 Corinthians = F',
    'G = John = G',
    'H = Hebrews, 1 Peter, 2 Peter = H',
];

attributes_and_classes();
bible_type();
in_and_clear();
require_settings();
books();
expand_ranges();
as_array();
as_hash();
as_verses();
as_runs();
as_chapters();
as_books();
refs();
as_text();
set_bible_data();

done_testing;

sub attributes_and_classes {
    can_ok( $obj, $_ ) for ( qw(
        acronyms sorting require_verse_match require_book_ucfirst minimum_book_length add_detail
        bible new expand_ranges in clear books
        as_array as_hash as_verses as_runs as_chapters as_books
        refs as_text set_bible_data
    ) );
}

sub bible_type {
    is( $obj->bible, 'Protestant', 'default bible() set ok');
    is( $obj->bible('c'), 'Catholic', 'can set "Catholic" with bible("c")' );
    is( $obj->bible, 'Catholic', 'bible type set to "Catholic"');
    is( $obj->bible('ogh'), 'Orthodox', 'can set "Orthodox" with bible("ogh")' );
    is( $obj->bible, 'Orthodox', 'bible type set to "Orthodox"');

    like(
        dies { $obj->bible('barf') },
        qr/^Could not determine a valid Bible type from input/,
        'fails to set bible("barf")',
    );
}

sub in_and_clear {
    ok(
        lives { $obj->clear },
        'clear lives',
    ) or note $@;

    is( $obj->_data, [], 'in() is empty' );

    ok(
        lives { $obj->in('Text with I Pet 3:16 and Rom 12:13-14,17 references in it.') },
        'in("text") lives',
    ) or note $@;

    is( $obj->_data, [
        [
            'Text with ',
            [ '1 Peter', [ [ 3, [16] ] ] ],
            ' and ',
            [ 'Romans', [ [ 12, [ 13, 14, 17 ] ] ] ],
            ' references in it.',
        ],
    ], 'in() is set correctly' );

    ok(
        lives { $obj->in('Text with Roms 12:16, 13:14-15 in it.') },
        'in("text 2") lives',
    ) or note $@;

    is( $obj->_data, [
        [
            'Text with ',
            [ '1 Peter', [ [ 3, [16] ] ] ],
            ' and ',
            [ 'Romans', [ [ 12, [ 13, 14, 17 ] ] ] ],
            ' references in it.',
        ],
        [ 'Text with ', [ 'Romans', [ [ 12, [16] ], [ 13, [ 14, 15 ] ], ], ], ' in it.' ],
    ], 'in() is set correctly' );

    ok(
        lives {
            $obj->in(
                'Even more text with Jam 1:5 in it.',
                'And one last bit of text with 1 Cor 12:8-12 in it.',
            );
        },
        'in( "text 3", "text 4" ) lives',
    ) or note $@;

    is( $obj->_data, [
        [
            'Text with ',
            [ '1 Peter', [ [ 3, [16] ] ] ],
            ' and ',
            [ 'Romans', [ [ 12, [ 13, 14, 17 ] ] ] ],
            ' references in it.',
        ],
        [ 'Text with ', [ 'Romans', [ [ 12, [16] ], [ 13, [ 14, 15 ] ], ], ], ' in it.' ],
        [ 'Even more text with ', [ 'James', [ [ 1, [5] ] ] ], ' in it.' ],
        [ 'And one last bit of text with ',
            [ '1 Corinthians', [ [ 12, [ 8, 9, 10, 11, 12 ] ] ] ], ' in it.' ],
    ], 'in() is set correctly' );

    ok(
        lives { $obj->clear },
        'clear lives',
    ) or note $@;

    is( $obj->_data, [], '_data is empty' );
}

sub require_settings {
    $obj->clear->require_book_ucfirst(1);
    is( $obj->in('header romans 12:13 footer')->_data, [
        ['header romans 12:13 footer'],
    ], '"romans 12:13" and require_book_ucfirst(0)' );

    $obj->clear->require_book_ucfirst(0);
    is( $obj->in('header romans 12:13 footer')->_data, [
        [ 'header ', [ 'Romans', [[ 12, [13]]]], ' footer' ],
    ], '"romans 12:13" and require_book_ucfirst(1)' );

    $obj->clear->require_verse_match(1);
    is( $obj->in('header romans 12 footer')->_data, [
        ['header romans 12 footer'],
    ], '"romans 12" and require_verse_match(1)' );

    $obj->clear->require_verse_match(0);
    is( $obj->in('header romans 12 footer')->_data, [
        [ 'header ', [ 'Romans', [[12]]], ' footer' ],
    ], '"romans 12" and require_verse_match(0)' );
}

sub books {
    my @books;

    $obj->bible('Protestant');
    ok(
        lives { @books = $obj->books },
        'books lives',
    ) or note $@;
    is( scalar @books, 66, 'Protestant book count' );
    is( $books[0], 'Genesis', 'Protestant Genesis location' );
    is( $books[1], 'Exodus', 'Protestant Exodus location' );
    is( $books[-1], 'Revelation', 'Protestant Revelation location' );

    $obj->bible('Catholic');
    @books = $obj->books;
    is( scalar @books, 73, 'Catholic book count' );
    is( $books[0], 'Genesis', 'Catholic Genesis location' );
    is( $books[1], 'Exodus', 'Catholic Exodus location' );
    is( $books[-1], 'Revelation', 'Catholic Revelation location' );

    $obj->bible('Orthodox');
    @books = $obj->books;
    is( scalar @books, 78, 'Orthodox book count' );
    is( $books[0], 'Genesis', 'Orthodox Genesis location' );
    is( $books[1], 'Exodus', 'Orthodox Exodus location' );
    is( $books[-1], 'Revelation', 'Orthodox Revelation location' );

    $obj->bible('Vulgate');
    @books = $obj->books;
    is( scalar @books, 73, 'Vulgate book count' );
    is( $books[0], 'Genesis', 'Vulgate Genesis location' );
    is( $books[1], 'Exodus', 'Vulgate Exodus location' );
    is( $books[-1], 'Revelation', 'Vulgate Revelation location' );
}

sub expand_ranges {
    $obj->bible('Protestant');

    is( $obj->expand_ranges( 'Mark', '3-3', 1 ), '3', 'C: "3-3" = consider as "3"' );
    is( $obj->expand_ranges( 'Mark', '3-5', 1 ), '3,4,5', 'D: "3-5" = consider as a simple range' );
    is( $obj->expand_ranges( 'Mark', '5-3', 1 ), '5,4,3', 'E: "5-3" = consider as a simple reversed range' );
    is( $obj->expand_ranges( 'Mark', '1:3-7', 1 ), '1:3,4,5,6,7', 'F: "1:3-7" = consider 3-7 as verses' );
    is( $obj->expand_ranges( 'Mark', '1:43-3', 1 ), '1:43,44,45;2;3', 'G: "1:43-3" = consider 3 a chapter' );

    is(
        $obj->expand_ranges( 'Mark', '1:3-3', 1 ),
        '1:' . join( ',', 3 .. 45 ) . ';2;3',
        'H: "1:3-3"  = consider the second 3 a chapter',
    );

    is( $obj->expand_ranges( 'Mark', '3:2-3', 1 ), '3:2,3', 'I: "3:2-3"  = consider 2-3 as verses' );
    is( $obj->expand_ranges( 'Mark', '3:3-2', 1 ), '3:3,2', 'J: "3:3-2"  = consider 3-2 as verses' );

    is(
        $obj->expand_ranges( 'Mark', '3-5:2', 1 ),
        '3;4;5:1,2',
        'K: "3-5:2" = 3-4 are full chapters; plus 5:1-5:2',
    );

    is( $obj->expand_ranges( 'Mark', '3-3:2', 1 ), '3:1,2', 'L: "3-3:2" = interpretted as "3:1-2"' );

    is(
        $obj->expand_ranges( 'Mark', '3:4-4:7', 1 ),
        '3:' . join( ',', 4 .. 35 ) . ';4:1,2,3,4,5,6,7',
        'M: "3:4-4:7" becomes "3:4-*;4:1-7"',
    );

    is(
        $obj->expand_ranges( 'Mark', '4:7-3:4', 1 ),
        '4:7,6,5,4,3,2,1;3:' . join( ',', reverse 4 .. 35 ),
        'N: "4:7-3:4" becomes reverse of "3:4-*;4:1-7"',
    );

    is(
        $obj->expand_ranges( 'Mark', '3:4-5:2', 1 ),
        '3:' . join( ',', 4 .. 35 ) . ';4;5:1,2',
        'O: "3:4-5:2" becomes "3:4-*;4;5:1-2"',
    );

    is(
        $obj->expand_ranges( 'Mark', '5:2-3:4', 1 ),
        '5:2,1;4;3:' . join( ',', reverse 4 .. 35 ),
        'P: "5:2-3:4" becomes reverse of "3:4-*;4;5:2-*"',
    );

    is(
        $obj->expand_ranges( 'Mark', '5-3:4', 1 ),
        '5:1;4;3:' . join( ',', reverse 4 .. 35 ),
        'A: "5-3:4" = translated to "5:1-3:4"',
    );

    is(
        $obj->expand_ranges( 'Mark', '3:4-3:7', 1 ),
        '3:4,5,6,7',
        'B: "3:4-3:7" = translated to "3:4-7"',
    );

    is(
        $obj->expand_ranges( 'Mark', '3:37-3:4', 1 ),
        '3:' . join( ',', reverse 4 .. 37 ),
        'Q: "3:37-3:4" is the reverse of 3:4-3:37',
    );

    is(
        $obj->expand_ranges( 'Mark', '4:37-9', 1 ),
        '4:37,38,39,40,41;5;6;7;8;9',
        '4:37-9',
    );
    is(
        $obj->expand_ranges( 'Mark', '3:23-27,4:37-9,6', 1 ),
        '3:23,24,25,26,27,4:37,38,39,40,41;5;6;7;8;9,6',
        '3:23-27,4:37-9,6',
    );
    is(
        $obj->expand_ranges( 'Mark', '4:37-5:9', 1 ),
        '4:37,38,39,40,41;5:1,2,3,4,5,6,7,8,9',
        '4:37-5:9',
    );
    is(
        $obj->expand_ranges( 'Mark', '3:23-27,4:37-5:9,6', 1 ),
        '3:23,24,25,26,27,4:37,38,39,40,41;5:1,2,3,4,5,6,7,8,9,6',
        '3:23-27,4:37-5:9,6',
    );
}

sub as_array {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_array }, 'as_array lives' ) or note $@;

    is(
        $refs,
        [
            [ 'Genesis', [ [ 1, [ 2 ] ], [ 4, [ 1 ] ] ] ],
            [ '1 Samuel', [ [ 4, [ 16 ] ] ] ],
            [ '2 Samuel', [ [ 3 ], [ 4 ], [ 5 ] ] ],
            [ 'Psalm', [ [ 117 ] ] ],
            [ 'Matthew', [
                [ 1, [ 18, 19, 20, 21, 22, 23, 24, 25 ] ],
                [ 2 ], [ 3 ], [ 4 ], [ 5 ], [ 6 ], [ 7 ], [ 8 ], [ 9 ], [ 10 ], [ 11 ], [ 12 ], [ 14 ],
                [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 20 ], [ 21 ], [ 22 ], [ 26 ], [ 27 ], [ 28 ]
            ] ],
            [ 'Mark', [
                [ 3, [ 6, 15, 16, 17, 20, 21, 22, 23 ] ],
                [ 4 ], [ 5 ], [ 12, [ 3, 4, 5, 6, 7 ] ], [ 13, [ 1, 2 ] ]
            ] ],
            [ 'Luke', [
                [ 1 ], [ 2 ],
                [ 3, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ] ],
                [ 9 ], [ 10 ], [ 11 ], [ 13 ], [ 14 ], [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 21 ],
                [ 22 ], [ 23 ], [ 24 ]
            ] ],
            [ 'John' ],
            [ 'Acts', [
                [ 1 ], [ 2 ], [ 3 ], [ 4 ], [ 5 ], [ 6 ], [ 7 ], [ 8 ], [ 9 ], [ 10 ], [ 11 ], [ 12 ],
                [ 13 ], [ 14 ], [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 20 ]
            ] ],
            [ 'Romans' ],
            [ '1 Corinthians' ],
            [ '2 Corinthians' ],
            [ 'Galatians' ],
            [ 'Ephesians' ],
            [ 'Philippians' ],
            [ 'Colossians' ],
            [ 'Hebrews' ],
            [ 'James' ],
            [ '1 Peter' ],
            [ '2 Peter', [ [ 3, [ 15, 16, 17, 18, 20, 21, 22 ] ], [ 4 ], [ 5, [ 1 ] ] ] ],
            [ '3 John' ],
            [ 'Revelation', [ [ 3, [ 15 ] ] ] ]
        ],
        'as_array data normal',
    );

    $obj->acronyms(1);
    $refs = $obj->as_array;

    is(
        $refs,
        [
            [ 'Ge', [ [ 1, [ 2 ] ], [ 4, [ 1 ] ] ] ],
            [ '1Sa', [ [ 4, [ 16 ] ] ] ],
            [ '2Sa', [ [ 3 ], [ 4 ], [ 5 ] ] ],
            [ 'Ps', [ [ 117 ] ] ],
            [ 'Mt', [
                [ 1, [ 18, 19, 20, 21, 22, 23, 24, 25 ] ],
                [ 2 ], [ 3 ], [ 4 ], [ 5 ], [ 6 ], [ 7 ], [ 8 ], [ 9 ], [ 10 ], [ 11 ], [ 12 ], [ 14 ],
                [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 20 ], [ 21 ], [ 22 ], [ 26 ], [ 27 ], [ 28 ]
            ] ],
            [ 'Mk', [
                [ 3, [ 6, 15, 16, 17, 20, 21, 22, 23 ] ],
                [ 4 ], [ 5 ], [ 12, [ 3, 4, 5, 6, 7 ] ], [ 13, [ 1, 2 ] ]
            ] ],
            [ 'Lk', [
                [ 1 ], [ 2 ],
                [ 3, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ] ],
                [ 9 ], [ 10 ], [ 11 ], [ 13 ], [ 14 ], [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 21 ],
                [ 22 ], [ 23 ], [ 24 ]
            ] ],
            [ 'Joh' ],
            [ 'Ac', [
                [ 1 ], [ 2 ], [ 3 ], [ 4 ], [ 5 ], [ 6 ], [ 7 ], [ 8 ], [ 9 ], [ 10 ], [ 11 ], [ 12 ],
                [ 13 ], [ 14 ], [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 20 ]
            ] ],
            [ 'Ro' ],
            [ '1Co' ],
            [ '2Co' ],
            [ 'Ga' ],
            [ 'Ep' ],
            [ 'Php' ],
            [ 'Cl' ],
            [ 'He' ],
            [ 'Jam' ],
            [ '1Pt' ],
            [ '2Pt', [ [ 3, [ 15, 16, 17, 18, 20, 21, 22 ] ], [ 4 ], [ 5, [ 1 ] ] ] ],
            [ '3Jn' ],
            [ 'Rv', [ [ 3, [ 15 ] ] ] ]
        ],
        'as_array data acronyms',
    );

    $obj->acronyms(0);
    $obj->sorting(0);
    $refs = $obj->as_array;

    is(
        $refs,
        [
            [ '1 Samuel', [ [ 4, [ 16 ] ] ] ],
            [ '2 Samuel', [ [ 3 ], [ 4 ], [ 5 ] ] ],
            [ '1 Peter' ],
            [ '2 Peter' ],
            [ '2 Peter', [ [ 3, [ 15 ] ] ] ],
            [ '2 Peter', [ [ 3 ], [ 4 ] ] ],
            [ '2 Peter', [ [ 3, [ 15, 16, 17, 18, 20, 21, 22 ] ] ] ],
            [ '2 Peter', [ [ 5, [ 1 ] ] ] ],
            [ 'Revelation' ],
            [ 'Revelation', [ [ 3, [ 15 ] ] ] ],
            [ 'Revelation' ],
            [ 'Revelation' ],
            [ 'Galatians' ],
            [ 'Romans' ],
            [ 'Mark', [ [ 12, [ 4 ] ] ] ],
            [ 'Mark', [ [ 12, [ 3, 4, 5 ] ] ] ],
            [ 'Mark', [ [ 12, [ 4, 5, 6, 7 ] ], [ 13, [ 1, 2 ] ] ] ],
            [ 'Genesis', [ [ 4, [ 1 ] ] ] ],
            [ 'Genesis', [ [ 1, [ 2 ] ] ] ],
            [ 'Mark', [ [ 3, [ 15, 16, 17 ] ] ] ],
            [ 'Psalm', [ [ 117 ] ] ],
            [ '3 John' ],
            [ 'Mark', [ [ 3, [ 6, 20, 21, 22, 23 ] ] ] ],
            [ 'Mark', [ [ 4 ], [ 5 ] ] ],
            [ 'Matthew', [
                [ 1, [ 18, 19, 20, 21, 22, 23, 24, 25 ] ],
                [ 2 ], [ 3 ], [ 4 ], [ 5 ], [ 6 ], [ 7 ], [ 8 ], [ 9 ], [ 10 ], [ 11 ], [ 12 ], [ 14 ],
                [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 20 ], [ 21 ], [ 22 ], [ 28 ], [ 27 ], [ 26 ]
            ] ],
            [ 'Romans' ],
            [ 'James' ],
            [ 'Acts', [
                [ 1 ], [ 2 ], [ 3 ], [ 4 ], [ 5 ], [ 6 ], [ 7 ], [ 8 ], [ 9 ], [ 10 ], [ 11 ], [ 12 ],
                [ 13 ], [ 14 ], [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 20 ]
            ] ],
            [ 'Galatians' ],
            [ 'Ephesians' ],
            [ 'Philippians' ],
            [ 'Colossians' ],
            [ 'Luke', [
                [ 1 ], [ 2 ],
                [ 3, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ] ],
                [ 9 ], [ 10 ], [ 11 ], [ 13 ], [ 14 ], [ 15 ], [ 16 ], [ 17 ], [ 18 ], [ 19 ], [ 21 ],
                [ 22 ], [ 23 ], [ 24 ]
            ] ],
            [ '1 Corinthians' ],
            [ '2 Corinthians' ],
            [ 'John' ],
            [ 'Hebrews' ],
            [ '1 Peter' ],
            [ '2 Peter' ]
        ],
        'as_array data no sorting',
    );

    $obj->sorting(1);
    $obj->add_detail(1);
    $refs = $obj->as_array;

    is(
        $refs->[20],
        [ '3 John', [ [ '1', [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ] ] ] ],
        'as_array data add detail',
    );

    $obj->add_detail(0);
}

sub as_hash {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_hash }, 'as_hash lives' ) or note $@;

    is(
        $refs,
        {
            'Philippians'   => {},
            '1 Corinthians' => {},
            '1 Peter'       => {},
            'Genesis'       => { 1 => [ 2 ], 4 => [ 1 ] },
            'Matthew'       => {
                21 => [], 28 => [], 10 => [], 7 => [], 3 => [], 5 => [], 8 => [],
                1 => [ 18, 19, 20, 21, 22, 23, 24, 25 ], 16 => [], 17 => [], 12 => [], 6 => [], 15 => [],
                11 => [], 18 => [], 20 => [], 27 => [], 22 => [], 14 => [], 19 => [], 4 => [], 2 => [],
                9 => [], 26 => []
            },
            '2 Corinthians' => {},
            'James'         => {},
            'Romans'        => {},
            '2 Peter'       => { 3 => [ 15, 16, 17, 18, 20, 21, 22 ], 5 => [ 1 ], 4 => [] },
            'Colossians'    => {},
            'John'          => {},
            '1 Samuel'      => { 4 => [ 16 ] },
            'Acts'          => {
                7 => [], 20 => [], 18 => [], 11 => [], 5 => [], 3 => [], 10 => [], 15 => [], 9 => [],
                12 => [], 2 => [], 17 => [], 6 => [], 1 => [], 14 => [], 8 => [], 4 => [], 19 => [],
                16 => [], 13 => []
            },
            'Luke'          => {
                19 => [], 13 => [], 16 => [], 22 => [], 14 => [], 1 => [], 23 => [], 2 => [], 24 => [],
                9 => [], 17 => [], 15 => [], 10 => [], 21 => [],
                3 => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 ],
                11 => [], 18 => []
            },
            '3 John'        => {},
            'Galatians'     => {},
            'Psalm'         => { 117 => [] },
            'Ephesians'     => {},
            '2 Samuel'      => { 5 => [], 3 => [], 4 => [] },
            'Revelation'    => { 3 => [ 15 ] },
            'Mark'          => {
                12 => [ 3, 4, 5, 6, 7 ], 4 => [], 5 => [],
                3 => [ 6, 15, 16, 17, 20, 21, 22, 23 ],
                13 => [ 1, 2 ]
            },
            'Hebrews'       => {}
        },
        'as_hash data',
    );
}

sub as_verses {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_verses }, 'as_verses lives' ) or note $@;

    is(
        $refs,
        [
            'Genesis 1:2', 'Genesis 4:1', '1 Samuel 4:16', '2 Samuel 3', '2 Samuel 4', '2 Samuel 5',
            'Psalm 117', 'Matthew 1:18', 'Matthew 1:19', 'Matthew 1:20', 'Matthew 1:21', 'Matthew 1:22',
            'Matthew 1:23', 'Matthew 1:24', 'Matthew 1:25', 'Matthew 2', 'Matthew 3', 'Matthew 4',
            'Matthew 5', 'Matthew 6', 'Matthew 7', 'Matthew 8', 'Matthew 9', 'Matthew 10', 'Matthew 11',
            'Matthew 12', 'Matthew 14', 'Matthew 15', 'Matthew 16', 'Matthew 17', 'Matthew 18', 'Matthew 19',
            'Matthew 20', 'Matthew 21', 'Matthew 22', 'Matthew 26', 'Matthew 27', 'Matthew 28', 'Mark 3:6',
            'Mark 3:15', 'Mark 3:16', 'Mark 3:17', 'Mark 3:20', 'Mark 3:21', 'Mark 3:22', 'Mark 3:23',
            'Mark 4', 'Mark 5', 'Mark 12:3', 'Mark 12:4', 'Mark 12:5', 'Mark 12:6', 'Mark 12:7', 'Mark 13:1',
            'Mark 13:2', 'Luke 1', 'Luke 2', 'Luke 3:1', 'Luke 3:2', 'Luke 3:3', 'Luke 3:4', 'Luke 3:5',
            'Luke 3:6', 'Luke 3:7', 'Luke 3:8', 'Luke 3:9', 'Luke 3:10', 'Luke 3:11', 'Luke 3:12',
            'Luke 3:13', 'Luke 3:14', 'Luke 3:15', 'Luke 3:16', 'Luke 3:17', 'Luke 3:18', 'Luke 3:19',
            'Luke 3:20', 'Luke 3:21', 'Luke 3:22', 'Luke 3:23', 'Luke 9', 'Luke 10', 'Luke 11', 'Luke 13',
            'Luke 14', 'Luke 15', 'Luke 16', 'Luke 17', 'Luke 18', 'Luke 19', 'Luke 21', 'Luke 22', 'Luke 23',
            'Luke 24', 'John', 'Acts 1', 'Acts 2', 'Acts 3', 'Acts 4', 'Acts 5', 'Acts 6', 'Acts 7', 'Acts 8',
            'Acts 9', 'Acts 10', 'Acts 11', 'Acts 12', 'Acts 13', 'Acts 14', 'Acts 15', 'Acts 16', 'Acts 17',
            'Acts 18', 'Acts 19', 'Acts 20', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
            'Ephesians', 'Philippians', 'Colossians', 'Hebrews', 'James', '1 Peter', '2 Peter 3:15',
            '2 Peter 3:16', '2 Peter 3:17', '2 Peter 3:18', '2 Peter 3:20', '2 Peter 3:21', '2 Peter 3:22',
            '2 Peter 4', '2 Peter 5:1', '3 John', 'Revelation 3:15'
        ],
        'as_verses data',
    );
}

sub as_runs {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_runs }, 'as_runs lives' ) or note $@;

    is(
        $refs,
        [
            'Genesis 1:2', 'Genesis 4:1', '1 Samuel 4:16', '2 Samuel 3', '2 Samuel 4', '2 Samuel 5',
            'Psalm 117', 'Matthew 1:18-25', 'Matthew 2', 'Matthew 3', 'Matthew 4', 'Matthew 5', 'Matthew 6',
            'Matthew 7', 'Matthew 8', 'Matthew 9', 'Matthew 10', 'Matthew 11', 'Matthew 12', 'Matthew 14',
            'Matthew 15', 'Matthew 16', 'Matthew 17', 'Matthew 18', 'Matthew 19', 'Matthew 20', 'Matthew 21',
            'Matthew 22', 'Matthew 26', 'Matthew 27', 'Matthew 28', 'Mark 3:6', 'Mark 3:15-17',
            'Mark 3:20-23', 'Mark 4', 'Mark 5', 'Mark 12:3-7', 'Mark 13:1-2', 'Luke 1', 'Luke 2',
            'Luke 3:1-23', 'Luke 9', 'Luke 10', 'Luke 11', 'Luke 13', 'Luke 14', 'Luke 15', 'Luke 16',
            'Luke 17', 'Luke 18', 'Luke 19', 'Luke 21', 'Luke 22', 'Luke 23', 'Luke 24', 'John', 'Acts 1',
            'Acts 2', 'Acts 3', 'Acts 4', 'Acts 5', 'Acts 6', 'Acts 7', 'Acts 8', 'Acts 9', 'Acts 10',
            'Acts 11', 'Acts 12', 'Acts 13', 'Acts 14', 'Acts 15', 'Acts 16', 'Acts 17', 'Acts 18', 'Acts 19',
            'Acts 20', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
            'Colossians', 'Hebrews', 'James', '1 Peter', '2 Peter 3:15-18', '2 Peter 3:20-22', '2 Peter 4',
            '2 Peter 5:1', '3 John', 'Revelation 3:15'
        ],
        'as_runs data',
    );
}

sub as_chapters {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_chapters }, 'as_chapters lives' ) or note $@;

    is(
        $refs,
        [
            'Genesis 1:2', 'Genesis 4:1', '1 Samuel 4:16', '2 Samuel 3', '2 Samuel 4', '2 Samuel 5',
            'Psalm 117', 'Matthew 1:18-25', 'Matthew 2', 'Matthew 3', 'Matthew 4', 'Matthew 5', 'Matthew 6',
            'Matthew 7', 'Matthew 8', 'Matthew 9', 'Matthew 10', 'Matthew 11', 'Matthew 12', 'Matthew 14',
            'Matthew 15', 'Matthew 16', 'Matthew 17', 'Matthew 18', 'Matthew 19', 'Matthew 20', 'Matthew 21',
            'Matthew 22', 'Matthew 26', 'Matthew 27', 'Matthew 28', 'Mark 3:6, 15-17, 20-23', 'Mark 4',
            'Mark 5', 'Mark 12:3-7', 'Mark 13:1-2', 'Luke 1', 'Luke 2', 'Luke 3:1-23', 'Luke 9', 'Luke 10',
            'Luke 11', 'Luke 13', 'Luke 14', 'Luke 15', 'Luke 16', 'Luke 17', 'Luke 18', 'Luke 19',
            'Luke 21', 'Luke 22', 'Luke 23', 'Luke 24', 'John', 'Acts 1', 'Acts 2', 'Acts 3', 'Acts 4',
            'Acts 5', 'Acts 6', 'Acts 7', 'Acts 8', 'Acts 9', 'Acts 10', 'Acts 11', 'Acts 12', 'Acts 13',
            'Acts 14', 'Acts 15', 'Acts 16', 'Acts 17', 'Acts 18', 'Acts 19', 'Acts 20', 'Romans',
            '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians', 'Colossians',
            'Hebrews', 'James', '1 Peter', '2 Peter 3:15-18, 20-22', '2 Peter 4', '2 Peter 5:1', '3 John',
            'Revelation 3:15'
        ],
        'as_chapters data',
    );
}

sub as_books {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_books }, 'as_books lives' ) or note $@;

    is(
        $refs,
        [
            'Genesis 1:2; 4:1',
            '1 Samuel 4:16',
            '2 Samuel 3-5',
            'Psalm 117',
            'Matthew 1:18-25; 2-12; 14-22; 26-28',
            'Mark 3:6, 15-17, 20-23; 4-5; 12:3-7; 13:1-2',
            'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24',
            'John',
            'Acts 1-20',
            'Romans',
            '1 Corinthians',
            '2 Corinthians',
            'Galatians',
            'Ephesians',
            'Philippians',
            'Colossians',
            'Hebrews',
            'James',
            '1 Peter',
            '2 Peter 3:15-18, 20-22; 4; 5:1',
            '3 John',
            'Revelation 3:15'
        ],
        'as_books data',
    );
}

sub refs {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->refs }, 'refs lives' ) or note $@;

    is(
        $refs,
        'Genesis 1:2; 4:1; 1 Samuel 4:16; 2 Samuel 3-5; Psalm 117; ' .
            'Matthew 1:18-25; 2-12; 14-22; 26-28; Mark 3:6, 15-17, 20-23; 4-5; 12:3-7; 13:1-2; ' .
            'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24; John; Acts 1-20; Romans; 1 Corinthians; 2 Corinthians; ' .
            'Galatians; Ephesians; Philippians; Colossians; Hebrews; James; 1 Peter; ' .
            '2 Peter 3:15-18, 20-22; 4; 5:1; 3 John; Revelation 3:15',
        'refs data',
    );
}

sub as_text {
    $obj->clear->acronyms(0);
    $obj->in(@$test_data);

    my $refs;
    ok( lives { $refs = $obj->as_text }, 'as_text lives' ) or note $@;

    is(
        $refs,
        [
            '',
            '0',
            '',
            'Text with no Reference 3:16 data included',
            'Text Samuel 3:15 said in 1 Samuel 4:16 that 2 Samuel 3-5 was as clear as 1 Peter in full',
            'Text Pet text 2 Peter text 2 Peter 3:15 text 2 Peter 3-4 text ' .
                '2 Peter 3:15-18, 20-22, 2 Peter 5:1 text',
            'The book of Revelation. The verse of Revelation 3:15. The book of Revelation.',
            'Books of Revelation, Galatians, and Romans exist',
            'Verses Mark 12:4 and Mark 12:3-5 and Mark 12:4-7; 13:1-2 and Genesis 4:1 and Genesis 1:2 exist',
            'Mark 3:15-17, Psalm 117, 3 John, Mark 3:6, 20-23, Mark 4-5',
            'A = Matthew 1:18-25; 2-12; 14-22; 26-28 = A',
            'B = Romans, James = B',
            'C = Acts 1-20 = C',
            'D = Galatians, Ephesians, Philippians, Colossians = D',
            'E = Luke 1-2; 3:1-23; 9-11; 13-19; 21-24 = E',
            'F = 1 Corinthians, 2 Corinthians = F',
            'G = John = G',
            'H = Hebrews, 1 Peter, 2 Peter = H'
        ],
        'as_text data',
    );
}

sub set_bible_data {
    like( dies { $obj->set_bible_data }, qr/^First argument/, 'set_bible_data()' );
    like( dies { $obj->set_bible_data('Special') }, qr/^Second argument/, 'set_bible_data()' );
    like( dies { $obj->set_bible_data( 'Special' => [
        [ 'Genesis', 'Ge' ],
        [ \'Genesis', \'Ge' ],
    ] ) }, qr/^Second argument/, 'set_bible_data()' );

    ok( lives { $obj->set_bible_data(
        'Special' => [
            [ 'Genesis',         'Ge'  ],
            [ 'Exodus',          'Ex'  ],
            [ 'Leviticus',       'Lv'  ],
            [ 'Numbers',         'Nu'  ],
            [ 'Deuteronomy',     'Dt'  ],
            [ 'Joshua',          'Jsh' ],
            [ 'Judges',          'Jdg' ],
            [ 'Ruth',            'Ru'  ],
            [ '1 Samuel',        '1Sa' ],
            [ '2 Samuel',        '2Sa' ],
            [ '1 Kings',         '1Ki' ],
            [ '2 Kings',         '2Ki' ],
            [ '1 Chronicles',    '1Ch' ],
            [ '2 Chronicles',    '2Ch' ],
            [ 'Ezra',            'Ezr' ],
            [ 'Nehemiah',        'Ne'  ],
            [ 'Esther',          'Est' ],
            [ 'Job',             'Jb'  ],
            [ 'Psalms',          'Ps'  ],
            [ 'Proverbs',        'Pr'  ],
            [ 'Ecclesiastes',    'Ec'  ],
            [ 'Song of Solomon', 'SS'  ],
            [ 'Isaiah',          'Is'  ],
            [ 'Jeremiah',        'Jr'  ],
            [ 'Lamentations',    'Lm'  ],
            [ 'Ezekiel',         'Ezk' ],
            [ 'Daniel',          'Da'  ],
            [ 'Hosea',           'Ho'  ],
            [ 'Joel',            'Jl'  ],
            [ 'Amos',            'Am'  ],
            [ 'Obadiah',         'Ob'  ],
            [ 'Jonah',           'Jnh' ],
            [ 'Micah',           'Mi'  ],
            [ 'Nahum',           'Na'  ],
            [ 'Habakkuk',        'Hab' ],
            [ 'Zephaniah',       'Zp'  ],
            [ 'Haggai',          'Hg'  ],
            [ 'Zechariah',       'Zec' ],
            [ 'Malachi',         'Ml'  ],
        ],
    ) }, '"Special" Bible data set' ) or note $@;

    is( $obj->bible, 'Special', '"Special" Bible is set' );

    my @books;
    ok(
        lives { @books = $obj->books },
        'books lives',
    ) or note $@;

    is( scalar @books, 39, 'Special book count' );
    is( $books[0], 'Genesis', 'Special Genesis location' );
    is( $books[1], 'Exodus', 'Special Exodus location' );
    is( $books[-1], 'Malachi', 'Special Revelation location' );
}
