
BEGIN {
    my @options = (
        '+ignore' => 'Data/Dumper',
        '+select' => 'DBIx::PreQL',
    );
    require Devel::Cover
        &&  Devel::Cover->import( @options )
        if  $ENV{COVER};
}

use strict;
use warnings;
use Data::Dumper;

use Test::More;

use_ok( 'DBIx::PreQL' );

my $q_string = <<'END_SQL';

*  SELECT
*    always,
A    apple,
&    banana, !banana!
C    canteloupe,

*  FROM
*    tbl_fruit
*  WHERE
*    AND always = ?always_1? AND ?always_2?
A    AND apple = ?apple?
&    AND banana = ?banana?
&    OR  banana is NULL !banana!
C    AND canteloupe = ?canteloupe?
&    AND apple < ?apple2? !banana!

END_SQL

my $q_lines = [ split "\n", $q_string ];

my $q_chunks = [
<<'END_SQL',

*  SELECT
*    always,
A    apple,
&    banana, !banana!

END_SQL
<<'END_SQL',

C    canteloupe,

*  FROM
*    tbl_fruit
*  WHERE
*    AND always = ?always_1? AND ?always_2?
A    AND apple = ?apple?
&    AND banana = ?banana?

&    OR  banana is NULL !banana!
C    AND canteloupe = ?canteloupe?
&    AND apple < ?apple2? !banana!

END_SQL
];

my $pq = join "\n",
   'SELECT',
   '  always,',
   '  apple,',
   '  banana,',
   '  canteloupe',
   'FROM',
   '  tbl_fruit',
   'WHERE',
   '      always = ? AND ?',
   '  AND apple = ?',
   '  AND banana = ?',
   '  OR  banana is NULL',
   '  AND canteloupe = ?',
   '  AND apple < ?',
;
my @pp = qw< always_1 always_2 apple banana canteloupe apple2 >;

for my $q ( $q_string, $q_lines, $q_chunks ) {
    my( $query, @params ) = DBIx::PreQL->build_query(
        query       => $q,
        wanted      => ['A','C'],
        data        => {
            apple       => 1,
            apple2      => 1,
            banana      => 1,
            canteloupe  => 1,
            always_1    => 1,
            always_2    => 1,
        },
        keep_keys   => 1,
    );

    is( $query, $pq, 'Generated same query' );
    is_deeply( \@params, \@pp, 'Generated same keys' );
}

{   # Parse no arg

    my $e;
    eval {  DBIx::PreQL::_parse_query(); 1 } or do { $e = $@ };
    ok( $e, '_parse_query dies without arguments' );
}

#{   # Parse null string
#
#    my $e;
#    eval {  DBIx::PreQL::_parse_query(''); 1 } or do { $e = $@ };
#    ok( $e, '_parse_query dies with zero length argument' );
#}
#
#{   # Wanted Array
#
#    my $f = DBIx::PreQL::_parse_wanted( [qw( a b c )] );
#
#    ok( $f->($_), "Wanted array accepts $_" ) for qw( a b c );
#    ok( !$f->($_), "Wanted array rejects $_" ) for qw( X Y Z );
#}

{   # Wanted sub

    my $tf = sub { 1 };
    my $f =  DBIx::PreQL::_parse_wanted( $tf );

    is( $f, $tf, 'Wanted code returns same code ref' );
}

{   # Wanted undef

    my $w = DBIx::PreQL::_parse_wanted(undef);
    is( $w, undef, 'Wanted undef returns undef' );
}

{   # Wanted bad

    my $e;
    eval {
        DBIx::PreQL::_parse_wanted( \'blah blah' );
        1
    } or do {
        $e = $@;
    };
    ok( $e, 'Wanted code dies with bad reference' );
}

{   # Data good

    my $d = { foo => 1, bar => 2 };
    is( $d , DBIx::PreQL::_parse_data( $d ), 'Happy data is happy' );
}

#{   # Data undef
#
#    is( undef, DBIx::PreQL::_parse_data( undef ), 'Happy data is happy' );
#}

{   # Data bad

    for ( [], 'true_string' ) {
        my $e;
        eval {  DBIx::PreQL::_parse_data( $_ ); 1 } or do { $e = $@ };
        ok( $e, 'Data must be a hash ref or nothing' );
    }
}

{   # Starred only

    my $q = join "\n",
        'SELECT',
        '  always',
        'FROM',
        '  tbl_fruit',
        'WHERE',
        '      always = ? AND ?';

    my $p = [ 'always_1', 'always_2' ];
    my $data  = { always_1 => 'potato', always_2 => 'carrot'};

    my( $query, @param ) = DBIx::PreQL->build_query(
        data  => $data,
        query => $q_string,
        wanted  => [],
    );

    is( $query, $q, 'Generate starred items only' );
    is( scalar @param, scalar @$p, 'Param list correct size' );
    is( $param[$_], $data->{ $p->[$_] }, "Param $_ correct" ) for 0..$#$p;

    ( $query, @param ) = DBIx::PreQL->build_query(
        data        => $data,
        query       => $q_string,
        wanted      => [],
        keep_keys   => 1,
    );

    is( $query, $q, 'Generate starred items only' );
    is( scalar @param, scalar @$p, 'Param list correct size' );
    is( $param[$_], $p->[$_], "Param $_ correct" ) for 0..$#$p;
}

{   # Select AC

    my $q = join "\n",
        'SELECT',
        '  always,',
        '  apple,',
        '  canteloupe',
        'FROM',
        '  tbl_fruit',
        'WHERE',
        '      always = ? AND ?',
        '  AND apple = ?',
        '  AND canteloupe = ?';

    my $p = [qw/ always_1 always_2 apple canteloupe /];
    my $data  = {
        always_1 => 'potato',
        always_2 => 'carrot',
        apple    => 'yellow',
        canteloupe => 'melon',
    };

    my( $query, @param ) = DBIx::PreQL->build_query(
        data  => $data,
        query => $q_string,
        wanted  => sub { return 1 if $_[0] eq 'A' or $_[0] eq 'C' },
    );

    is( $query, $q, 'Generate *, A, C items' );
    is( scalar @param, scalar @$p, 'Param list correct size' );
    is( $param[$_], $data->{ $p->[$_] }, "Param $_ correct" )
        for 0..$#$p;

    ( $query, @param ) = DBIx::PreQL->build_query(
        data        => $data,
        query       => $q_string,
        wanted      => sub { return 1 if $_[0] eq 'A' or $_[0] eq 'C' },
        keep_keys   => 1,
    );

    is( $query, $q, 'Generate *, A, C items' );
    is( scalar @param, scalar @$p, 'Param list correct size' );
    is( $param[$_], $p->[$_], "Param $_ correct" ) for 0..$#$p;
}

#{   # Wanted called with correct args
#
#    # tag data line params deps
#    my @wanted_args = (
#        [ A => { A => 1, B => 2 }, 'Boogers ? ', ['A'], ['B'] ],
#        [ B => { A => 1, B => 2 }, 'Beegers ? ', ['B'], ['A'] ],
#    );
#
#    my( $query, @param ) = DBIx::PreQL->build_query(
#        data   => { A => 1, B => 2 },
#        query  => [ '*  Feeble', 'A   Boogers ?A? !B!', 'B   Beegers ?B? !A!' ],
#        wanted => sub {
#            is_deeply( [@_], shift @wanted_args, 'Wanted called with correct args' );
#        },
#    );
#}

{   # gotany tags

    my $query = <<EQ;
    &     Text with a ?placeholder?
    |     Text with an !ifgot!
    |     Text with a ?placeholder? and an !ifgot!
    |     Text with !ifgot! and !ifgot2!
EQ

    my( $q, @p ) = DBIx::PreQL->build_query(
        query => $query,
        data  => { ifgot => 'def', placeholder => 'ph' },
    );

    is(
        $q,
        join( "\n", 'Text with a ?', 'Text with an',
            'Text with a ? and an', 'Text with and' ),
        'ANY tags with !! and ??',
    );
    is_deeply( \@p, [ 'ph', 'ph' ] );

    ( $q, @p ) = DBIx::PreQL->build_query(
        query => $query,
        data  => { placeholder => 'ph' },
    );

    is( $q, join( "\n", 'Text with a ?' ), 'ANY tags with ?? only' );
    is_deeply( \@p, [ 'ph' ] );

    my $e = undef;
#    eval {
#        ( $q, @p ) = DBIx::PreQL->build_query(
#            query => $query,
#            data  => { ifgot => 'def' },
#        );
#        1
#    } or do {
#        $e = $@;
#    };
#
#    like( $e, qr/undefined named place-holder/ );

    $e = undef;
    eval {
        ( $q, @p ) = DBIx::PreQL->build_query(
            query => '| Just some text',
            data  => { ifgot => 'def' },
        );
        1
    } or do {
        $e = $@;
    };

    like( $e, qr/No dependency markers/i );
}

{   # gotall tags

    my $query = <<EQ;
    &     Text with a ?placeholder?
    &     Text with an !ifgot!
    &     Text with a ?placeholder? and an !ifgot!
EQ

    my( $q, @p ) = DBIx::PreQL->build_query(
        query => $query,
        data  => { ifgot => 'def', placeholder => 'ph' },
    );

    is(
        $q,
        join( "\n", 'Text with a ?', 'Text with an', 'Text with a ? and an' ),
        'Ifall tags with !! and ??',
    );
    is_deeply( \@p, [ 'ph', 'ph' ] );

    ( $q, @p ) = DBIx::PreQL->build_query(
        query => $query,
        data  => { placeholder => 'ph' },
    );

    is( $q, join( "\n", 'Text with a ?' ), 'Ifall tags with ??' );
    is_deeply( \@p, [ 'ph' ] );

    ( $q, @p ) = DBIx::PreQL->build_query(
        query => $query,
        data  => { ifgot => 'def' },
    );

    is( $q, join( "\n", 'Text with an' ), 'Ifall tags with !!' );
    is_deeply( \@p, [ ] );

#    ( $q, @p ) = DBIx::PreQL->build_query(
#        query => $query,
#        data  => { ifgot => undef },
#    );

#    is( $q, join( "\n",  'Text with an' ), 'Ifall tags with !undef!' );
#    is_deeply( \@p, [ ] );

    my $e = undef;
    eval {
        ( $q, @p ) = DBIx::PreQL->build_query(
            query => '& Just some text',
            data  => { ifgot => 'def' },
        );
        1
    } or do {
        $e = $@;
    };

    like( $e, qr/No parameters nor dependency markers/i );
}

{  # always tags

    my $query = <<EQ;
    *     Just some text
    *     Text with a ?placeholder?
    *     Text with an ?ifgot?
    *     Text with a ?placeholder? and an ?ifgot?
EQ

    my( $q, @p ) = DBIx::PreQL->build_query(
        query => $query,
        data  => { ifgot => 'def', placeholder => 'ph' },
    );

    is(
        $q,
        join( "\n", 'Just some text', 'Text with a ?',
            'Text with an ?', 'Text with a ? and an ?' ),
        'Always tags with ??',
    );
    is_deeply( \@p, [ 'ph', 'def', 'ph', 'def' ] );

    my $e;
#    eval {
#        ( $q, @p ) = DBIx::PreQL->build_query(
#            query => $query,
#            data  => { placeholder => 'ph' },
#        );
#        1
#    } or do {
#        $e = $@;
#    };

#    like( $e, qr/dependency/, 'Missing dep marker causes exception.' );
#    like( $e, qr/ifgot/,      'Missing dep marker causes exception.' );

    $e = undef;
    eval {
        ( $q, @p ) = DBIx::PreQL->build_query(
            query => $query,
            data  => { ifgot => 'def' },
        );
        1
    } or do {
        $e = $@;
    };

    like( $e, qr/named place-holder/,
        'Missing named place-holder causes exception.' );
}

{  # custom tags

    my $query = <<EQ;
    A     Just some text
    A     Text with a ?placeholder?
    A     Text with an ?ifgot?
    A     Text with a ?placeholder? and an ?ifgot?
EQ

    my( $q, @p ) = DBIx::PreQL->build_query(
        query  => $query,
        data   => { ifgot => 'def', placeholder => 'ph' },
        wanted => sub { 1 },
    );

    is(
        $q,
        join( "\n", 'Just some text', 'Text with a ?',
            'Text with an ?', 'Text with a ? and an ?' ),
        'Custom tags with !! and ??',
    );
    is_deeply( \@p, [ 'ph', 'def', 'ph', 'def' ] );

    ( $q, @p ) = DBIx::PreQL->build_query(
        query  => $query,
        data   => { ifgot => 'def', placeholder => 'ph' },
        wanted => sub { 0 },
    );

    is( $q, '', 'Keep nothing' );
    is_deeply( \@p, [ ] );

    my $e;
#    eval {
#        ( $q, @p ) = DBIx::PreQL->build_query(
#            query => $query,
#            data  => { placeholder => 'ph' },
#            wanted => sub { 1 },
#        );
#        1
#    } or do {
#        $e = $@;
#    };

#    like( $e, qr/dependency/, 'Missing dep marker causes exception.' );
#    like( $e, qr/ifgot/,      'Missing dep marker causes exception.' );

    $e = undef;
    eval {
        ( $q, @p ) = DBIx::PreQL->build_query(
            query => $query,
            data  => { ifgot => 'def' },
            wanted => sub { 1 },
        );
        1
    } or do {
        $e = $@;
    };

    like( $e, qr/named place-holder/,
        'Missing named place-holder causes exception.' );

    $e = undef;
    eval {
        ( $q, @p ) = DBIx::PreQL->build_query(
            query => $query,
            data  => { ifgot => 'def' },
        );
        1
    } or do {
        $e = $@;
    };

    like( $e, qr/wanted/, 'Missing wanted causes exception.' );
}

{   # WHERE removal

    my $sql = <<EOT;
    *  SELECT * FROM table WHERE
    |  booger >= 0 !booger!
    &  AND foo=?foo?
    &  AND bar=?bar?
EOT

    my( $q, @p ) = DBIx::PreQL->build_query(
        query => $sql,
        data  => { foo => 'def' },
    );

    is(
        $q,
        join( "\n", 'SELECT * FROM table WHERE', '    foo=?' ),
        "AND collapse",
    );
}

done_testing();
