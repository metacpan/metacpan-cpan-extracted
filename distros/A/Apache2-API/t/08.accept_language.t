#!/usr/bin/env perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use Test::More;
    use vars qw( $DEBUG );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use ok( 'Apache2::API::Headers::AcceptLanguage' ) || BAIL_OUT( 'Unable to load Apache2::API::Headers::AcceptLanguage' );
};

use strict;
use warnings;

my $al = Apache2::API::Headers::AcceptLanguage->new( 'en-GB, fr-FR;q=0.8', debug => $DEBUG );
isa_ok( $al, 'Apache2::API::Headers::AcceptLanguage' );

# To generate this list:
# perl -lnE '/^sub (?!init|[A-Z]|_)/ and say "can_ok( \$al, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Apache2/API/Headers/AcceptCommon.pm ./lib/Apache2/API/Headers/AcceptLanguage.pm
can_ok( $al, 'header' );
can_ok( $al, 'match' );
can_ok( $al, 'preferences' );
can_ok( $al, 'languages' );
can_ok( $al, 'locales' );

sub is_match
{
    my( $hdr, $offers, $expect, $name ) = @_;
    my $al = Apache2::API::Headers::AcceptLanguage->new( $hdr, debug => $DEBUG );
    my $got = $al->match( $offers );
    is( $got, $expect, $name );
}

is( $al->header, 'en-GB, fr-FR;q=0.8', 'Header stored correctly' );

# Test preferences (locales)
my $prefs = $al->preferences;
is_deeply( $prefs, ['en-GB', 'fr-FR'], 'Preferences sorted by q descending' );

# Test aliases
is_deeply( $al->languages, $prefs, 'languages alias' );
is_deeply( $al->locales, $prefs, 'locales alias' );


# Exact tag match
is_match(
    'en-GB, fr-FR;q=0.8',
    [ 'fr-FR', 'en-GB' ],
    'en-GB',
    'Exact locale match'
);

# Primary language partial match
is_match(
    'en;q=0.5, fr-FR;q=0.9',
    [ 'en-GB', 'fr-FR' ],
    'fr-FR',
    'Higher q exact vs partial language match'
);

# Primary language matches more specific server locale
is_match(
    'en;q=0.9, fr;q=0.8',
    [ 'fr-FR', 'en-GB' ],
    'en-GB',
    'Primary language matches server locale'
);

# Wildcard => first supported
is_match(
    '*;q=0.2',
    [ 'ja-JP', 'fr-FR' ],
    'ja-JP',
    'Wildcard * selects first supported'
);

# Test partial match (language only)
is_match(
    'fr;q=0.9,en-GB;q=0.8',
    ['fr-FR', 'en'],
    'fr-FR',
    'Partial match on language'
);

# Test specificity: full over partial at same q
is_match(
    'fr-FR;q=0.9,fr;q=0.9',
    ['fr-FR', 'fr-BE'],
    'fr-FR',
    'Full match preferred',
);

# Empty header => first supported
is_match(
    '',
    [ 'ja-JP', 'fr-FR' ],
    'ja-JP',
    'Empty Accept-Language -> first supported'
);

# Test error handling
$al = Apache2::API::Headers::AcceptLanguage->new('en', debug => $DEBUG);
my $rv = $al->match('not array');
ok( !defined( $rv ), 'Non-array supported: error' );
like( $al->error->message, qr/not an array reference/, 'Error message correct' );

subtest 'edge cases' => sub
{
    # Duplicate locales keep best q
    is_match(
        'fr-FR;q=0.2, fr-FR;q=0.9, en;q=0.8',
        [ 'en', 'fr-FR' ],
        'fr-FR',
        'Duplicate locale uses highest q',
    );

    # q=0 excludes a tag
    is_match(
        'ja;q=0, en;q=0.5',
        [ 'ja-JP', 'en-GB' ],
        'en-GB',
        'q=0 excludes language',
    );
    
    # Partial language vs different lang at higher q: higher q wins elsewhere
    is_match(
        'en;q=0.4, fr;q=0.9',
        [ 'en-GB', 'fr-FR' ],
        'fr-FR',
        'Higher q on different language wins over partial match',
    );
    
    # Non-empty supported required
    is_match(
        'en;q=1',
        [],
        '',
        'Empty supported -> empty string',
    );

    # Test no header
    is_match(
        '',
        ['en'],
        'en',
        'No header: first supported',
    );

    # Test multiple same locale different q
    $al = Apache2::API::Headers::AcceptLanguage->new('en;q=0.5,en;q=0.9', debug => $DEBUG);
    is_deeply( $al->preferences, ['en'], 'Keeps highest q for duplicate' );

    # Test invalid locale
    $al = Apache2::API::Headers::AcceptLanguage->new('invalid;q=1', debug => $DEBUG);
    ok( !$al->preferences->[0], 'Invalid locale ignored' );

    # Test empty supported
    is( $al->match([]), '', 'Empty supported: empty string' );

    # Test 0.01 style priority
    local $Apache2::API::Headers::AcceptLanguage::MATCH_PRIORITY_0_01_STYLE = 1;
    $al = Apache2::API::Headers::AcceptLanguage->new('en;q=0.5,fr;q=0.5', debug => $DEBUG);
    is( $al->match(['fr', 'en']), 'fr', '0.01 style: supported order' );

    # Test complex locale
    $al = Apache2::API::Headers::AcceptLanguage->new('ja-Kana-t-it;q=0.9', debug => $DEBUG);
    is( $al->preferences->[0], 'ja-Kana-t-it', 'Complex locale parsed' );
};

subtest 'preferences consistency' => sub
{
    $al = Apache2::API::Headers::AcceptLanguage->new( 'fr-FR;q=0.5, en-GB;q=0.8, fr;q=0.7', debug => $DEBUG );
    my $prefs = $al->preferences;
    isa_ok( $prefs, 'ARRAY', 'AcceptLanguage::preferences returns arrayref (first call)' );
    my $prefs2 = $al->preferences;
    isa_ok( $prefs2, 'ARRAY', 'AcceptLanguage::preferences returns arrayref (cached path)' );
    is_deeply( $prefs2, $prefs, 'AcceptLanguage::preferences cached == initial' );
};


done_testing();

__END__

