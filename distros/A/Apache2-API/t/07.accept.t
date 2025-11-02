#!/usr/bin/env perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use Test::More;
    use Module::Generic::Global ':const';
    use vars qw( $DEBUG );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'Apache2::API::Headers::Accept' ) || BAIL_OUT( 'Unable to load Apache2::API::Headers::Accept' );
};

use strict;
use warnings;

my $accept = Apache2::API::Headers::Accept->new( 'text/html, application/json;q=0.5', debug => $DEBUG );
isa_ok( $accept, 'Apache2::API::Headers::Accept' );

# To generate this list:
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$accept, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Apache2/API/Headers/AcceptCommon.pm ./lib/Apache2/API/Headers/Accept.pm
can_ok( $accept, 'header' );
can_ok( $accept, 'match' );
can_ok( $accept, 'preferences' );
can_ok( $accept, 'media_types' );

sub is_match
{
    my( $hdr, $supported, $expect, $name ) = @_;
    my $ac = Apache2::API::Headers::Accept->new( $hdr, debug => $DEBUG );
    my $got = $ac->match( $supported );
    is( $got, $expect, $name );
}

is( $accept->header, 'text/html, application/json;q=0.5', 'Header stored correctly' );

# Test preferences
my $prefs = $accept->preferences;
is_deeply( $prefs, ['text/html', 'application/json'], 'Preferences sorted by q descending' );

# Exact match beats broader ranges
is_match(
    'text/html, application/json;q=0.5',
    [ 'application/json', 'text/html' ],
    'text/html',
    'Exact match preferred by order + q'
);

# q-values: higher q wins
is_match(
    'text/html;q=0.5, application/json;q=0.9',
    [ 'text/html', 'application/json' ],
    'application/json',
    'Higher q wins'
);

# Test type wildcard
# type/* wins over */* and specificity considered
is_match(
    'text/*;q=0.7, */*;q=0.2, application/json;q=0.9',
    [ 'image/png', 'application/json', 'text/html' ],
    'application/json',
    'Specific type beats ranges via q'
);

# Test wildcard
# */* returns first supported
is_match(
    '*/*;q=0.3',
    [ 'application/json', 'text/html' ],
    'application/json',
    'Wildcard */* returns first supported'
);

is_match(
    '*/*;q=0.5',
    ['text/plain', 'image/jpeg'],
    'text/plain',
    'Wildcard */* returns first supported (bis)',
);

# Test no header
# Empty/undefined header => first supported
is_match(
    '',
    [ 'application/json', 'text/html' ],
    'application/json',
    'Empty header means all acceptable'
);

# Test specificity
is_match(
    'text/html;q=0.9,text/*;q=0.9',
    ['text/plain', 'text/html'],
    'text/html',
    'More specific wins at same q',
);

# No supported items => '' (not undef)
{
    my $ac = Apache2::API::Headers::Accept->new( 'text/html' );
    is( scalar( $ac->match( [] ) ), '', 'Empty supported => empty string' );
}

# Wrong type => undef + error
{
    my $ac = Apache2::API::Headers::Accept->new( 'text/html' );
    my $got = $ac->match( { 'not' => 'an array' } );
    ok( !defined $got, 'Wrong type returns undef' );
    ok( defined $ac->error, 'Error is set' );
}

subtest 'edge cases' => sub
{
    # Parameters other than q are ignored for matching
    my $ac;
    $ac = Apache2::API::Headers::Accept->new( 'text/html; charset=UTF-8; q=0.8, application/json;version=2', debug => $DEBUG );
    is( $ac->match( [ 'application/json', 'text/html' ] ), 'application/json', 'Non-q params ignored; json (no q -> 1.0) wins' );

    # Duplicate media types use best q
    $ac = Apache2::API::Headers::Accept->new( 'text/html;q=0.3, text/html;q=0.8, application/json;q=0.7', debug => $DEBUG );
    is( $ac->match( [ 'text/html', 'application/json' ] ), 'text/html', 'Duplicate token keeps highest q' );

    # q=0 excludes a token
    $ac = Apache2::API::Headers::Accept->new( 'application/json;q=0, text/html;q=0.5', debug => $DEBUG );
    is( $ac->match( [ 'application/json', 'text/html' ] ), 'text/html', 'q=0 excludes token' );

    # type/* vs exact specificity
    $ac = Apache2::API::Headers::Accept->new( 'text/*;q=0.9, text/html;q=0.9', debug => $DEBUG );
    is( $ac->match( [ 'text/plain', 'text/html' ] ), 'text/html', 'Exact more specific than type/* at same q' );

    # */* with higher q than specific type
    $ac = Apache2::API::Headers::Accept->new( '*/*;q=1.0, text/html;q=0.9', debug => $DEBUG );
    is( $ac->match( [ 'text/html', 'application/json' ] ), 'text/html', 'Wildcard still chooses first supported (text/html first)' );

    # Test invalid header
    $ac = Apache2::API::Headers::Accept->new( 'invalid', debug => $DEBUG );
    ok( !$ac->preferences->[0], 'Invalid header: empty preferences' );

    # Test empty supported
    is( $ac->match([]), '', 'Empty supported: empty string' );

    # Test error handling
    $ac = Apache2::API::Headers::Accept->new( 'text/html', debug => $DEBUG );
    my $rv = $ac->match( 'not array' );
    ok( !defined( $rv ), 'Non-array supported: error');
    like( $ac->error->message, qr/not an array reference/, 'Error message correct' );

    # Test with parameters (ignored in matching)
    $ac = Apache2::API::Headers::Accept->new( 'text/html;level=1;q=0.9', debug => $DEBUG );
    is( $ac->match( ['text/html'] ), 'text/html', 'Parameters ignored in match' );

    # Test multiple same type different q
    $ac = Apache2::API::Headers::Accept->new( 'text/html;q=0.5,text/html;q=0.9', debug => $DEBUG );
    is_deeply( $ac->preferences, ['text/html'], 'Keeps highest q for duplicate' );

    {
        # Test 0.01 style priority
        local $Apache2::API::Headers::Accept::MATCH_PRIORITY_0_01_STYLE = 1;
        $ac = Apache2::API::Headers::Accept->new( 'text/html;q=0.5,application/json;q=0.5', debug => $DEBUG );
        is( $ac->match( ['application/json', 'text/html'] ), 'application/json', '0.01 style: supported order' );
    }

    # Wildcard and specific at the same q -> prefer the specific (modern mode)
    {
        local $Apache2::API::Headers::AcceptCommon::MATCH_PRIORITY_0_01_STYLE = 0;
        my $ac = Apache2::API::Headers::Accept->new( '*/*;q=0.9, application/json;q=0.9', debug => $DEBUG );
        is(
            $ac->match( [ 'image/png', 'text/html', 'application/json' ] ),
            'application/json',
            'Equal q: specific beats wildcard in modern mode'
        );
    }

    # Wildcard higher q than specific -> wildcard wins (first supported)
    {
        local $Apache2::API::Headers::AcceptCommon::MATCH_PRIORITY_0_01_STYLE = 0;
        my $ac = Apache2::API::Headers::Accept->new( '*/*;q=1.0, application/json;q=0.9', debug => $DEBUG );
        is(
            $ac->match( [ 'image/png', 'text/html', 'application/json' ] ),
            'image/png',
            'Higher q wildcard chooses first supported'
        );
    }
};

subtest 'preferences consistency' => sub
{
    my $ac = Apache2::API::Headers::Accept->new( 'text/plain;q=0.4, text/html;q=0.9, application/json', debug => $DEBUG );
    my $prefs = $ac->preferences;
    isa_ok( $prefs, 'ARRAY', 'Accept::preferences returns arrayref (first call)' );
    my $prefs2 = $ac->preferences;
    isa_ok( $prefs2, 'ARRAY', 'Accept::preferences returns arrayref (cached path)' );
    is_deeply( $prefs2, $prefs, 'Accept::preferences cached == initial' );
};

subtest 'mismatch priority mode' => sub
{
    # In legacy mode, at equal q, priority follows the OFFER list rather than header order.
    {
        local $Apache2::API::Headers::Accept::MATCH_PRIORITY_0_01_STYLE = 1;
        my $ac = Apache2::API::Headers::Accept->new( 'text/html;q=0.8, application/json;q=0.8', debug => $DEBUG );
        is(
            $ac->match( [ 'application/json', 'text/html' ] ),
            'application/json',
            'Legacy mode: equal q favors offer order (json first)'
        );
    }

    {
        local $Apache2::API::Headers::Accept::MATCH_PRIORITY_0_01_STYLE = 0;
        my $ac = Apache2::API::Headers::Accept->new( 'text/html;q=0.8, application/json;q=0.8', debug => $DEBUG );
        # In >= 0.02 mode, we iterate by client preference (sorted by q, stable on header order).
        is(
            $ac->match( [ 'application/json', 'text/html' ] ),
            'text/html',
            'Modern mode: equal q favors header order (text/html first in header)'
        );
    }

    # Legacy mode: equal q, prefer offer order BUT do not let wildcard preempt a specific match
    {
        local $Apache2::API::Headers::AcceptCommon::MATCH_PRIORITY_0_01_STYLE = 1;
        my $ac = Apache2::API::Headers::Accept->new( '*/*;q=0.8, application/json;q=0.8', debug => $DEBUG );
        is(
            $ac->match( [ 'application/json', 'text/html' ] ),
            'application/json',
            'Legacy mode: equal q with wildcard present still allows specific to win'
        );
    }
};

subtest 'threads' => sub
{
    SKIP:
    {
        if( !HAS_THREADS )
        {
            skip( 'Threads not available', 3 );
        }
        require threads;
        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                diag( "Thread $tid parsing 'Accept' header value" ) if( $DEBUG );
                my $accept = Apache2::API::Headers::Accept->new( 'text/html;q=0.9', debug => $DEBUG );
                if( !defined( $accept ) )
                {
                    diag( "Thread $tid failed to parse header: ", Apache2::API::Headers::Accept->error ) if( $DEBUG );
                    return(0);
                }
                return( is( $accept->match( ['text/html'] ), 'text/html', "Thread $_: match" ) ? 1 : 0 );
            });
        } 1..5;
        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join;
        }
        ok( $success, 'All threads tests passed successfully' );
    };
};

done_testing();

__END__
