#! perl

use v5.26;
use Test2::V0;

use Config::XrmDatabase;
use Config::XrmDatabase::Util ':funcs';

*parse    = \&parse_resource_name;
*parse_fq = \&parse_fq_resource_name;

# xmh*Paned*activeForeground:     red
# *incorporate.Foreground:     blue
# xmh.toc*?.Foreground:     white
# xmh.toc*Command.activeForeground:     black

subtest 'name with operators' => sub {

    is( parse( 'a.b.c.d.e' ), [ 'a', 'b', 'c', 'd', 'e' ], 'only tight binding' );

    is( parse( 'a.b....c..d.e' ), [ 'a', 'b', 'c', 'd', 'e' ], 'duplicate tight binding' );

    is( parse( 'a*b*c*d*e' ), [ 'a', q{*}, 'b', q{*}, 'c', q{*}, 'd', q{*}, 'e' ], 'loose binding' );

    is(
        parse( 'a**b*c**d**e' ),
        [ 'a', q{*}, 'b', q{*}, 'c', q{*}, 'd', q{*}, 'e' ],
        'duplicate loose binding',
    );

    is(
        parse( 'a.**b.*c*.*d*.*e' ),
        [ 'a', q{*}, 'b', q{*}, 'c', q{*}, 'd', q{*}, 'e' ],
        q{mix '.' and '*' },
    );

    is( parse( '*a.b' ), [ q{*}, 'a', 'b' ], 'leading *' );

    is( parse( 'a*?b' ), [ 'a', q{*}, q{?}, 'b' ], q{*?} );

    is( parse( 'a?*b' ), [ 'a', q{?}, q{*}, 'b' ], q{?*} );

    subtest 'bad resource name' => sub {
        for my $name ( 'a.b.c..', 'a.b.c?', 'a.b.c*' ) {
            isa_ok( dies { parse( $name ) }, ['Config::XrmDatabase::Failure::key'], "'$name'", );
        }
    };

};

subtest 'fq name' => sub {

    subtest 'bad resource name' => sub {
        for my $name ( 'a.b.c..', 'a.b.c?', 'a.b.c*', '*a.b.c', '.a.b.c' ) {
            isa_ok( dies { parse_fq( $name ) }, ['Config::XrmDatabase::Failure::key'], "'$name'", );
        }
    };

    is( parse_fq( 'a.b' ), [ 'a', 'b' ], 'valid name' );
    is( parse_fq( 'a.b.c.d' ), [ 'a', 'b', 'c', 'd' ], 'valid name' );

};

done_testing;
