package Test::Bible::Reference;
use strict;
use warnings;
use parent 'Test::Class';
use Test::Most;
use Test::Moose;

use constant TEST_PACKAGE_NAME => 'Bible::Reference';

sub instantiation : Test( startup => 4 ) {
    use_ok TEST_PACKAGE_NAME;
    require_ok TEST_PACKAGE_NAME;
    my $obj;
    lives_ok( sub { $obj = TEST_PACKAGE_NAME->new }, 'new' );
    isa_ok( $obj, TEST_PACKAGE_NAME );
    shift->{obj} = $obj;
}

sub attributes_and_classes : Test(8) {
    my $obj = shift->{obj};
    has_attribute_ok( $obj, $_, qq{attribute "$_" exists} ) for ( qw(
        acronyms sorting bible
        require_verse_match require_book_ucfirst
    ) );
    can_ok( $obj, $_ ) for ( qw( _in in ) );
    throws_ok( sub { $obj->_in }, qr/Attribute _in is private/, '_in() is private' );
}

sub bible_type : Test(6) {
    my $obj = shift->{obj};

    is( $obj->bible, 'Protestant', 'default bible() set ok');
    is( $obj->bible('c'), 'Catholic', 'can set "Catholic" with bible("c")' );
    is( $obj->bible, 'Catholic', 'bible type set to "Catholic"');
    is( $obj->bible('ogh'), 'Orthodox', 'can set "Orthodox" with bible("ogh")' );
    is( $obj->bible, 'Orthodox', 'bible type set to "Orthodox"');

    throws_ok(
        sub { $obj->bible('barf') },
        qr/^Could not determine a valid Bible type from input/,
        'fails to set bible("barf")',
    );
}

sub in_and_clear : Test(10) {
    my $obj = shift->{obj};

    lives_ok(
        sub { $obj->clear },
        'clear lives',
    );

    is_deeply( $obj->in, [], 'in() is empty' );

    lives_ok(
        sub { $obj->in('Text with I Pet 3:16 and Rom 12:13-14,17 references in it.') },
        'in("text") lives',
    );

    is_deeply( $obj->in, [
        [
            'Text with ',
            [ '1 Peter', [ [ 3, [16] ] ] ],
            ' and ',
            [ 'Romans', [ [ 12, [ 13, 14, 17 ] ] ] ],
            ' references in it.',
        ],
    ], 'in() is set correctly' );

    lives_ok(
        sub { $obj->in('Moobje text with Roms 12:16, 13:14-15 in it.') },
        'in("text 2") lives',
    );

    is_deeply( $obj->in, [
        [
            'Text with ',
            [ '1 Peter', [ [ 3, [16] ] ] ],
            ' and ',
            [ 'Romans', [ [ 12, [ 13, 14, 17 ] ] ] ],
            ' references in it.',
        ],
        [ 'Moobje text with ', [ 'Romans', [ [ 12, [16] ], [ 13, [ 14, 15 ] ], ], ], ' in it.' ],
    ], 'in() is set correctly' );

    lives_ok(
        sub {
            $obj->in(
                'Even more text with Jam 1:5 in it.',
                'And one last bit of text with 1 Cor 12:8-12 in it.',
            );
        },
        'in( "text 3", "text 4" ) lives',
    );

    is_deeply( $obj->in, [
        [
            'Text with ',
            [ '1 Peter', [ [ 3, [16] ] ] ],
            ' and ',
            [ 'Romans', [ [ 12, [ 13, 14, 17 ] ] ] ],
            ' references in it.',
        ],
        [ 'Moobje text with ', [ 'Romans', [ [ 12, [16] ], [ 13, [ 14, 15 ] ], ], ], ' in it.' ],
        [ 'Even more text with ', [ 'James', [ [ 1, [5] ] ] ], ' in it.' ],
        [ 'And one last bit of text with ', [ '1 Corinthians', [ [ 12, [ 8, 9, 10, 11, 12 ] ] ] ], ' in it.' ],
    ], 'in() is set correctly' );

    lives_ok(
        sub { $obj->clear },
        'clear lives',
    );

    is_deeply( $obj->in, [], 'in() is empty' );
}

sub require_settings : Test(4) {
    my $obj = shift->{obj};

    $obj->clear->require_book_ucfirst(1);
    is_deeply( $obj->in('header romans 12:13 footer')->in, [
        ['header romans 12:13 footer'],
    ], '"romans 12:13" and require_book_ucfirst(0)' );

    $obj->clear->require_book_ucfirst(0);
    is_deeply( $obj->in('header romans 12:13 footer')->in, [
        [ 'header ', [ 'Romans', [[ 12, [13]]]], ' footer' ],
    ], '"romans 12:13" and require_book_ucfirst(1)' );

    $obj->clear->require_verse_match(1);
    is_deeply( $obj->in('header romans 12 footer')->in, [
        ['header romans 12 footer'],
    ], '"romans 12" and require_verse_match(1)' );

    $obj->clear->require_verse_match(0);
    is_deeply( $obj->in('header romans 12 footer')->in, [
        [ 'header ', [ 'Romans', [[12]]], ' footer' ],
    ], '"romans 12" and require_verse_match(0)' );
}

sub books : Test(5) {
    my $obj = shift->{obj};
    my @books;

    $obj->bible('Protestant');
    lives_ok(
        sub { @books = $obj->books },
        'books lives',
    );
    ok(
        @books == 66 &&
        $books[0] eq 'Genesis' &&
        $books[1] eq 'Exodus' &&
        $books[-1] eq 'Revelation',
        'books data OK',
    );

    $obj->bible('Catholic');
    @books = $obj->books;
    ok(
        @books == 73 &&
        $books[0] eq 'Genesis' &&
        $books[1] eq 'Exodus' &&
        $books[-1] eq 'Revelation',
        'books data OK',
    );

    $obj->bible('Orthodox');
    @books = $obj->books;
    ok(
        @books == 78 &&
        $books[0] eq 'Genesis' &&
        $books[1] eq 'Exodus' &&
        $books[-1] eq 'Revelation',
        'books data OK',
    );

    $obj->bible('Vulgate');
    @books = $obj->books;
    ok(
        @books == 76 &&
        $books[0] eq 'Genesis' &&
        $books[1] eq 'Exodus' &&
        $books[-1] eq 'Revelation',
        'books data OK',
    );
}

sub as_hash : Test(3) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_hash }, 'as_hash lives' );

    is_deeply(
        $refs,
        {
            '2 Timothy'     => { 4 => [ 3 ] },
            '2 Peter'       => { 3 => [ 3 ] },
            'Acts'          => { 5 => [], 7 => [], 6 => [], 20 => [ 29, 32, 35 ], 9 => [] },
            '1 Timothy'     => { 4 => [ 1 ] },
            'Luke'          => { 4 => [ 5 .. 10 ], 3 => [ 15 .. 18 ] },
            '1 Corinthians' => { 6 => [ 17 .. 19 ], 5 => [ 15 .. 17, 19 ] },
            '1 Peter'       => { 3 => [ 16 ] },
            'John'          => {
                3 => [ 14, 16 .. 21 ],
                4 => [ 2, 18 .. 20 ], 2 => [ 17, 18 ],
            },
            'Romans' => {
                1  => [ 15 ],
                3  => [],
                4  => [ 15 .. 19, 21, 35 ],
                5  => [ 46, 48 ],
                2  => [ 2 .. 15 ],
                11 => [ 13 ],
                12 => [ 13, 14, 17 ],
            },
        },
        'as_hash data',
    );

    $obj->acronyms(1);
    $refs = $obj->as_hash;

    is_deeply(
        $refs,
        {
            '2Ti' => { 4 => [ 3 ] },
            '2Pt' => { 3 => [ 3 ] },
            'Ac'  => { 5 => [], 7 => [], 6 => [], 20 => [ 29, 32, 35 ], 9 => [] },
            '1Ti' => { 4 => [ 1 ] },
            'Lk'  => { 4 => [ 5 .. 10 ], 3 => [ 15 .. 18 ] },
            '1Co' => { 6 => [ 17 .. 19 ], 5 => [ 15 .. 17, 19 ] },
            '1Pt' => { 3 => [ 16 ] },
            'Joh' => {
                3 => [ 14, 16 .. 21 ],
                4 => [ 2, 18 .. 20 ], 2 => [ 17, 18 ],
            },
            'Ro' => {
                1  => [ 15 ],
                3  => [],
                4  => [ 15 .. 19, 21, 35 ],
                5  => [ 46, 48 ],
                2  => [ 2 .. 15 ],
                11 => [ 13 ],
                12 => [ 13, 14, 17 ],
            },
        },
        'as_hash data',
    );

    $obj->acronyms(0);
}

sub as_array : Test(3) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_array }, 'as_array lives' );

    is_deeply(
        $refs,
        [
            ['Luke',[[3,[15,16,17,18]],[4,[5,6,7,8,9,10]]]],
            ['John',[[2,[17,18]],[3,[14,16,17,18,19,20,21]],[4,[2,18,19,20]]]],
            ['Acts',[[5],[6],[7],[9],[20,[29,32,35]]]],
            ['Romans',[
                [1,[15]],
                [2,[2,3,4,5,6,7,8,9,10,11,12,13,14,15]],
                [3],[4,[15,16,17,18,19,21,35]],
                [5,[46,48]],[11,[13]],[12,[13,14,17]]]
            ],
            ['1 Corinthians',[[5,[15,16,17,19]],[6,[17,18,19]]]],
            ['1 Timothy',[[4,[1]]]],
            ['2 Timothy',[[4,[3]]]],
            ['1 Peter',[[3,[16]]]],
            ['2 Peter',[[3,[3]]]]
        ],
        'as_array data',
    );

    $obj->acronyms(1);
    $refs = $obj->as_array;

    is_deeply(
        $refs,
        [
            ['Lk',[[3,[15,16,17,18]],[4,[5,6,7,8,9,10]]]],
            ['Joh',[[2,[17,18]],[3,[14,16,17,18,19,20,21]],[4,[2,18,19,20]]]],
            ['Ac',[[5],[6],[7],[9],[20,[29,32,35]]]],
            ['Ro',[
                [1,[15]],
                [2,[2,3,4,5,6,7,8,9,10,11,12,13,14,15]],
                [3],[4,[15,16,17,18,19,21,35]],
                [5,[46,48]],[11,[13]],[12,[13,14,17]]]
            ],
            ['1Co',[[5,[15,16,17,19]],[6,[17,18,19]]]],
            ['1Ti',[[4,[1]]]],
            ['2Ti',[[4,[3]]]],
            ['1Pt',[[3,[16]]]],
            ['2Pt',[[3,[3]]]]
        ],
        'as_array data',
    );

    $obj->acronyms(0);
}

sub as_verses : Test(2) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_verses }, 'as_verses lives' );

    is_deeply(
        $refs,
        [
            'Luke 3:15', 'Luke 3:16', 'Luke 3:17', 'Luke 3:18', 'Luke 4:5',
            'Luke 4:6', 'Luke 4:7', 'Luke 4:8', 'Luke 4:9', 'Luke 4:10',
            'John 2:17', 'John 2:18', 'John 3:14', 'John 3:16', 'John 3:17',
            'John 3:18', 'John 3:19', 'John 3:20', 'John 3:21', 'John 4:2',
            'John 4:18', 'John 4:19', 'John 4:20', 'Acts 5', 'Acts 6', 'Acts 7',
            'Acts 9', 'Acts 20:29', 'Acts 20:32', 'Acts 20:35', 'Romans 1:15',
            'Romans 2:2', 'Romans 2:3', 'Romans 2:4', 'Romans 2:5', 'Romans 2:6',
            'Romans 2:7', 'Romans 2:8', 'Romans 2:9', 'Romans 2:10', 'Romans 2:11',
            'Romans 2:12', 'Romans 2:13', 'Romans 2:14', 'Romans 2:15', 'Romans 3',
            'Romans 4:15', 'Romans 4:16', 'Romans 4:17', 'Romans 4:18', 'Romans 4:19',
            'Romans 4:21', 'Romans 4:35', 'Romans 5:46', 'Romans 5:48',
            'Romans 11:13', 'Romans 12:13', 'Romans 12:14', 'Romans 12:17',
            '1 Corinthians 5:15', '1 Corinthians 5:16', '1 Corinthians 5:17',
            '1 Corinthians 5:19', '1 Corinthians 6:17', '1 Corinthians 6:18',
            '1 Corinthians 6:19', '1 Timothy 4:1', '2 Timothy 4:3',
            '1 Peter 3:16', '2 Peter 3:3',
        ],
        'as_verses data',
    );
}

sub as_runs : Test(2) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_runs }, 'as_runs lives' );

    is_deeply(
        $refs,
        [
            'Luke 3:15-18', 'Luke 4:5-10', 'John 2:17-18', 'John 3:14', 'John 3:16-21', 'John 4:2',
            'John 4:18-20', 'Acts 5', 'Acts 6', 'Acts 7', 'Acts 9', 'Acts 20:29', 'Acts 20:32', 'Acts 20:35',
            'Romans 1:15', 'Romans 2:2-15', 'Romans 3', 'Romans 4:15-19', 'Romans 4:21', 'Romans 4:35',
            'Romans 5:46', 'Romans 5:48', 'Romans 11:13', 'Romans 12:13-14', 'Romans 12:17',
            '1 Corinthians 5:15-17', '1 Corinthians 5:19', '1 Corinthians 6:17-19', '1 Timothy 4:1',
            '2 Timothy 4:3', '1 Peter 3:16', '2 Peter 3:3',
        ],
        'as_runs data',
    );
}

sub as_chapters : Test(2) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_chapters }, 'as_chapters lives' );

    is_deeply(
        $refs,
        [
            'Luke 3:15-18',
            'Luke 4:5-10',
            'John 2:17-18',
            'John 3:14, 16-21',
            'John 4:2, 18-20',
            'Acts 5',
            'Acts 6',
            'Acts 7',
            'Acts 9',
            'Acts 20:29, 32, 35',
            'Romans 1:15',
            'Romans 2:2-15',
            'Romans 3',
            'Romans 4:15-19, 21, 35',
            'Romans 5:46, 48',
            'Romans 11:13',
            'Romans 12:13-14, 17',
            '1 Corinthians 5:15-17, 19',
            '1 Corinthians 6:17-19',
            '1 Timothy 4:1',
            '2 Timothy 4:3',
            '1 Peter 3:16',
            '2 Peter 3:3',
        ],
        'as_chapters data',
    );
}

sub as_books : Test(2) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_books }, 'as_books lives' );

    is_deeply(
        $refs,
        [
            'Luke 3:15-18, 4:5-10',
            'John 2:17-18, 3:14, 16-21, 4:2, 18-20',
            'Acts 5-7, 9, 20:29, 32, 35',
            'Romans 1:15, 2:2-15',
            'Romans 3, 4:15-19, 21, 35, 5:46, 48, 11:13, 12:13-14, 17',
            '1 Corinthians 5:15-17, 19, 6:17-19',
            '1 Timothy 4:1',
            '2 Timothy 4:3',
            '1 Peter 3:16',
            '2 Peter 3:3',
        ],
        'as_books data',
    );
}

sub refs : Test(2) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->refs }, 'refs lives' );

    is_deeply(
        $refs,
        'Luke 3:15-18, 4:5-10; John 2:17-18, 3:14, 16-21, 4:2, 18-20; Acts 5-7, ' .
            '9, 20:29, 32, 35; Romans 1:15, 2:2-15; Romans 3, 4:15-19, 21, 35, ' .
            '5:46, 48, 11:13, 12:13-14, 17; 1 Corinthians 5:15-17, 19, 6:17-19; ' .
            '1 Timothy 4:1; 2 Timothy 4:3; 1 Peter 3:16; 2 Peter 3:3',
        'refs data',
    );
}

sub as_text : Test(2) {
    my $obj = shift->{obj};
    $obj->clear->acronyms(0);

    $obj->in(
        'Text with I Pet 3:16 and Rom 12:13-14,17 references in it plus Romans 2, 3, 4 and Romans 11:13 refs',
        'Some text from Rom 4:15,16-19,21 and also 1 Corin 5:16, 6:17-19 and such',
        'John 4:19, 4:2, 3:16, 4:18, 20; John 2:17-18, Rom 2:2-14, 15; John 3:19-21, 18, 17, 14, Ac 5, 6, 7, 9',
        'Lk 3:15-17, 18; 4:5-10; Acts 20:29, 32, 35, 1 Tim 4:1, 2 Tim 4:3, 2 Pete 3:3',
        '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
        'Romans 1:15',
        '',
        'Nothing to see 42',
    );

    my $refs;
    lives_ok( sub { $refs = $obj->as_text }, 'as_text lives' );

    is_deeply(
        $refs,
        [
            'Text with 1 Peter 3:16 and Romans 12:13-14, 17 references in it plus Romans 2-4 and Romans 11:13 refs',
            'Some text from Romans 4:15-19, 21 and also 1 Corinthians 5:16, 6:17-19 and such',
            'John 3:16, 4:2, 18-20; John 2:17-18, Romans 2:2-15; John 3:14, 17-21, Acts 5-7, 9',
            'Luke 3:15-18, 4:5-10; Acts 20:29, 32, 35, 1 Timothy 4:1, 2 Timothy 4:3, 2 Peter 3:3',
            '1 Corinthians 5:15-17, 19; Romans 4:35, 5:46, 48',
            'Romans 1:15',
            '',
            'Nothing to see 42',
        ],
        'as_text data',
    );
}

sub set_bible_data : Test(7) {
    my $obj = shift->{obj};

    throws_ok( sub { $obj->set_bible_data }, qr/^First argument/, 'set_bible_data()' );
    throws_ok( sub { $obj->set_bible_data('Special') }, qr/^Second argument/, 'set_bible_data()' );
    throws_ok( sub { $obj->set_bible_data( 'Special' => [
        [ 'Genesis', 'Ge' ],
        [ \'Genesis', \'Ge' ],
    ] ) }, qr/^Second argument/, 'set_bible_data()' );

    lives_ok( sub { $obj->set_bible_data(
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
    ) }, '"Special" Bible data set' );

    is( $obj->bible, 'Special', '"Special" Bible is set' );

    my @books;
    lives_ok(
        sub { @books = $obj->books },
        'books lives',
    );
    ok(
        @books == 39 &&
        $books[0] eq 'Genesis' &&
        $books[1] eq 'Exodus' &&
        $books[-1] eq 'Malachi',
        'books data OK',
    );
}

1;
