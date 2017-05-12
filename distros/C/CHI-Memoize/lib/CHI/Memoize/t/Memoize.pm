package CHI::Memoize::t::Memoize;
$CHI::Memoize::t::Memoize::VERSION = '0.07';
use Test::Class::Most parent => 'Test::Class';
use File::Temp qw(tempdir);
use CHI::Memoize qw(memoize memoized unmemoize NO_MEMOIZE);

my $unique_id = 0;
sub unique_id { ++$unique_id }

sub func { join( ",", unique_id(), @_ ) }

# memoize('func');
#
sub test_basic : Tests {
    isnt( func(), func(), "different values" );
    my $orig = \&func;
    memoize('func');
    is( func(), func(), "same values" );
    my $info  = memoized('func');
    my $cache = $info->cache;
    isa_ok( $info,  'CHI::Memoize::Info' );
    isa_ok( $cache, 'CHI::Driver::Memory' );
    is( scalar( $cache->get_keys ), 1, "1 key" );
    is( $info->orig,                $orig );
    is( $info->wrapper,             \&func );

    cmp_deeply( func(), re(qr/\d+/), 'no args' );
    cmp_deeply( func( 'a', 'b' ), re(qr/\d+,a,b/), 'two args' );

    unmemoize('func');
    isnt( func(), func(), "different values" );
    ok( !memoized('func'), 'not memoized' );
    is( scalar( $cache->get_keys ), 0, "0 keys" );
}

# memoize('Some::Package::func');
#

sub test_full_name : Tests {
    my $full_name = join( "::", __PACKAGE__, 'func' );
    my $orig = \&func;
    memoize($full_name);
    is( func(), func(), "same values" );
    my $info = memoized('func');
    is( $info->orig,    $orig );
    is( $info->wrapper, \&func );
    unmemoize($full_name);
    ok( !memoized($full_name) );
}

# $anon = memoize($anon);
#
sub test_anon : Tests {
    my $func = sub { unique_id() };
    isnt( $func->(), $func->(), "different values" );
    my $memo_func = memoize($func);
    is( $memo_func->(), $memo_func->(), "same values" );
    my $info = memoized($func);
    isa_ok( $info,        'CHI::Memoize::Info' );
    isa_ok( $info->cache, 'CHI::Driver::Memory' );
    is( scalar( $info->cache->get_keys ), 1, "1 key" );
    is( $info->orig,                      $func );
    is( $info->wrapper,                   $memo_func );
}

# memoize('func', key => sub { $_[0] });
# memoize('func', key => sub { $_[1], $_[2] });
#
sub test_dynamic_key : Tests {
    memoize( 'func', key => sub { $_[0] } );
    is( func(), func(), "empty=empty" );
    is( func( 1, 2, 3 ), func( 1, 5 ), "123=15" );
    isnt( func( 1, 2, 3 ), func( 2, 2, 3 ), "123=223" );
    unmemoize('func');

    memoize( 'func', key => sub { $_[1], $_[2] } );
    is( func( 1, 2, 3 ), func( 1, 2, 3 ), "123=123" );
    is( func( 1, 2, 3 ), func( 5, 2, 3 ), "123=523" );
    is( func(1), func(5), "1=5" );
    isnt( func( 1, 2, 3 ), func( 1, 2, 4 ), "123!=124" );
    my $info   = memoized('func');
    my @keys   = $info->cache->get_keys;
    my $prefix = join( ",", map { qq{"$_"} } ( $info->key_prefix, 'S' ) );
    cmp_deeply( \@keys, bag( "[$prefix,null,null]", "[$prefix,2,4]", "[$prefix,2,3]" ) );
    unmemoize('func');
}

# memoized_function({a => 5, b => 6, c => { d => 7, e => 8 }});
# memoized_function({b => 6, c => { e => 8, d => 7 }, a => 5});
# memoize('func', key => sub { %@_ });
#
sub test_normalization : Tests {
    memoize('func');
    is(
        func( { a => 5, b => 6, c => { d => 7, e => 8 } } ),
        func( { b => 6, c => { e => 8, d => 7 }, a => 5 } )
    );
    isnt(
        func( a => 5, b => 6, c => { d => 7, e => 8 } ),
        func( b => 6, c => { e => 8, d => 7 }, a => 5 )
    );
    unmemoize('func');

    memoize( 'func', key => sub { return {@_} } );
    is(
        func( a => 5, b => 6, c => { d => 7, e => 8 } ),
        func( b => 6, c => { e => 8, d => 7 }, a => 5 )
    );
    unmemoize('func');
}

# memoize('func', key => sub { NOCACHE });
#
sub test_undef_or_empty_key : Tests {
    memoize( 'func', key => sub { defined( $_[0] ) && $_[0] eq 'nocache' ? NO_MEMOIZE : @_ } );
    is( func(),      func(),      "no args" );
    is( func('foo'), func('foo'), "regular arg" );
    isnt( func( 'nocache', 'a', 'b' ), func( 'nocache', 'a', 'b' ), "nocache" );
    cmp_deeply( func( 'nocache', 'a', 'b' ), re(qr/\d+,nocache,a,b/), 'two args' );
    unmemoize('func');
}

# memoize('func', expires_in => '2 sec');
#
sub test_expires_in : Tests {
    memoize( 'func', expires_in => '2 sec' );

    my @vals;
    push( @vals, func(), func() );
    push( @vals, func(), func() );
    sleep(2);
    push( @vals, func(), func() );
    push( @vals, func(), func() );
    foreach my $pair ( [ 0, 1 ], [ 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 0, 2 ], [ 4, 6 ] ) {
        my ( $x, $y ) = @$pair;
        is( $vals[$x], $vals[$y], "$x=$y" );
    }
    isnt( $vals[0], $vals[4], "0!=4" );

    unmemoize('func');
}

# memoize('func', expire_if => $cond);
#
sub test_expire_if : Tests {
    my $cond = 0;
    memoize( 'func', expire_if => sub { $cond } );

    my @vals;
    push( @vals, func(), func() );
    $cond = 1;
    push( @vals, func(), func() );
    $cond = 0;
    push( @vals, func(), func() );
    foreach my $pair ( [ 0, 1 ], [ 3, 4 ], [ 4, 5 ] ) {
        my ( $x, $y ) = @$pair;
        is( $vals[$x], $vals[$y], "$x=$y" );
    }
    foreach my $pair ( [ 2, 3 ], [ 1, 2 ] ) {
        my ( $x, $y ) = @$pair;
        isnt( $vals[$x], $vals[$y], "$x!=$y" );
    }

    unmemoize('func');
}

# memoize('func', driver => 'File');
# memoize('func', cache => $cache );
#
sub test_file_driver : Tests {
    foreach my $iter ( 0, 1 ) {
        my $root_dir = tempdir( 'memoize-XXXX', TMPDIR => 1, CLEANUP => 1 );
        my @options = (
            $iter == 0
            ? ( driver => 'File', root_dir => $root_dir )
            : ( cache => CHI->new( driver => 'File', root_dir => $root_dir ) )
        );
        memoize( 'func', @options );
        is( func(), func(), "same values" );
        my $cache = memoized('func')->cache;
        isa_ok( $cache, 'CHI::Driver::File' );
        is( $cache->root_dir, $root_dir );
        is( scalar( $cache->get_keys ), 1, "1 key" );
        my $val = func();
        $cache->clear();
        isnt( func(), $val, "after clear" );
        unmemoize('func');
        isnt( func(), func(), "different values" );
        is( scalar( $cache->get_keys ), 0, "0 keys" );
    }
}

# memoize('func') vs memoize('func', driver => 'RawMemory');
#
sub test_cloned_versus_raw : Tests {
    my $base = sub { [ unique_id(), unique_id() ] };

    {
        my $func = memoize($base);
        my $ref1 = $func->();
        my $ref2 = $func->();
        cmp_deeply( $ref1, $ref2, "same contents" );
        isnt( $ref1, $ref2, "different refs" );
        push( @$ref1, 'foo' );
        my $ref3 = $func->();
        cmp_deeply( $ref3, $ref2, "memoized value unaffected by changes to result" );
        unmemoize($base);
    }

    {
        my $func = memoize( $base, driver => 'RawMemory' );
        my $ref1 = $func->();
        my $ref2 = $func->();
        cmp_deeply( $ref1, $ref2, "same contents" );
        is( $ref1, $ref2, "same refs" );
        push( @$ref1, 'foo' );
        my $ref3 = $func->();
        cmp_deeply( $ref3, $ref1, "memoized value affected by changes to result" );
        unmemoize($base);
    }
}

1;
