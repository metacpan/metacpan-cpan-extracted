#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $TEST_ID );
    use utf8;
    use version;
    use Test::More;
    # 2024-12-31T11:47:47
    use Test::Time time => 1735645667;
    use DateTime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
};

BEGIN
{
    use_ok( 'DateTime::Format::RelativeTime' ) || BAIL_OUT( 'Unable to load DateTime::Format::RelativeTime' );
};

use strict;
use warnings;
use utf8;


my $tests =
[
    {
        locale => 'en',
        options => {},
        args => [0, 'second'],
        expects => 'in 0 seconds',
        expects_parts => [
            { type => "literal", value => 'in ' },
            { type => "integer", value => 0, unit => 'second' },
            { type => "literal", value => ' seconds' },
        ],
    },
    {
        locale => 'en',
        options => { numeric => 'auto' },
        args => [0, 'second'],
        expects => 'now',
        expects_parts => [
            { type => "literal", value => 'now' },
        ],
    },
    {
        locale => 'en',
        options => { numeric => 'auto' },
        # Using 1 DateTime object
        args => [
            DateTime->new(
                year => 2024,
                month => 2,
                day => 1,
            )
        ],
        expects => 'in 3 quarters',
        expects_parts => [
            { type => "literal", value => 'in ' },
            { type => "integer", value => 3, unit => 'quarter' },
            { type => "literal", value => ' quarters' },
        ],
    },
    {
        locale => 'en',
        options => { numeric => 'auto' },
        # Using 2 DateTime objects
        args => [
            DateTime->new(
                year => 2024,
                month => 12,
                day => 1,
            ),
            DateTime->new(
                year => 2024,
                month => 2,
                day => 1,
            ),
        ],
        expects => '3 quarters ago',
        expects_parts => [
            { type => "integer", value => 3, unit => 'quarter' },
            { type => "literal", value => ' quarters ago' },
        ],
    },
    # Test with Spanish locale
    {
        locale => 'es',
        options => { numeric => 'auto' },
        args => [1, 'day'],
        expects => 'mañana',
        expects_parts => [
            { type => "literal", value => 'mañana' },
        ],
    },
    
    # Test with French locale
    {
        locale => 'fr',
        options => { numeric => 'auto' },
        args => [-1, 'day'],
        expects => 'hier',
        expects_parts => [
            { type => "literal", value => 'hier' },
        ],
    },

    # Test with Japanese locale for year difference
    {
        locale => 'ja',
        options => { numeric => 'auto' },
        args => [
            DateTime->new(
                year => 2023,
                month => 12,
                day => 31,
            )
        ],
        expects => '来年',
        expects_parts => [
            { type => "literal", value => '来年' },
        ],
    },

    # Test with German locale for week difference
    {
        locale => 'de',
        options => { numeric => 'auto' },
        args => [
            DateTime->new(
                year => 2024,
                month => 12,
                day => 24,
            )
        ],
        # Assuming the week starts on Monday and 'now' is Tue, Dec 31
        expects => 'nächste Woche',
        expects_parts => [
            { type => "literal", value => 'nächste Woche' },
        ],
    },

    # Test with Russian locale for hour difference
    {
        locale => 'ru',
        options => { numeric => 'auto' },
        args => [2, 'hour'],
        expects => 'через 2 часа',
        expects_parts => [
            { type => "literal", value => 'через ' },
            { type => "integer", value => 2, unit => 'hour' },
            { type => "literal", value => ' часа' },
        ],
    },

    # Test with Arabic locale for minute difference
    {
        locale => 'ar',
        options => { numeric => 'auto' },
        args => [-3, 'minute'],
        expects => 'قبل 3 دقائق',
        expects_parts => [
            { type => "literal", value => "قبل " },
            { type => "integer", value => '٣', unit => "minute" },
            { type => "literal", value => " دقائق" },
        ],
    },

    # Test with a locale that uses different plural forms (Polish for example)
    {
        locale => 'pl',
        options => { numeric => 'auto' },
        args => [5, 'day'],
        expects => 'za 5 dni',
        expects_parts => [
            { type => "literal", value => 'za ' },
            { type => "integer", value => 5, unit => 'day' },
            { type => "literal", value => ' dni' },
        ],
    },

    # Test for edge case where the day changes but it's less than a full day
    {
        locale => 'en',
        options => { numeric => 'auto' },
        args => [
            DateTime->new(
                year => 2024,
                month => 12,
                day => 31,
                hour => 10,
                minute => 47,
                second => 47,
            )
        ],
        expects => 'in 1 hour',
        expects_parts => [
            { type => "literal", value => 'in ' },
            { type => "integer", value => 1, unit => 'hour' },
            { type => "literal", value => ' hour' },
        ],
    },

    # Test with Hindi (India) - Devanagari numerals and dot for decimal
    {
        locale => 'hi-IN',
        options => { numeric => 'auto', numberingSystem => 'deva' },
        args => [-3.5, 'minute'],
        expects => '3.5 मिनट पहले',
        expects_parts => [
            { type => "integer", value => '३', unit => "minute" },
            { type => "decimal", value => ".", unit => "minute" },
            { type => "fraction", value => '५', unit => "minute" },
            { type => "literal", value => " मिनट पहले" },
        ],
    },

    # Test with Bengali (Bangladesh) - Bengali numerals, dot for decimal
    {
        locale => 'bn-BD',
        options => { numeric => 'auto', numberingSystem => 'beng' },
        args => [2.75, 'hour'],
        expects => '২.৭৫ ঘণ্টা পর',
        expects_parts => [
            { type => "integer", value => '২', unit => "hour" },
            { type => "decimal", value => ".", unit => "hour" },
            { type => "fraction", value => '৭৫', unit => "hour" },
            { type => "literal", value => " ঘন্টায়" },
        ],
    },
    # Test with Persian (Iran) - Persian digits, comma for decimal
    {
        locale => 'fa-IR',
        options => { numeric => 'auto', numberingSystem => 'arabext' },
        args => [-1.25, 'day'],
        expects => '۱٫۲۵ روز پیش',
        expects_parts => [
            { type => "integer", value => '۱', unit => "day" },
            { type => "decimal", value => "٫", unit => "day" },
            { type => "fraction", value => '۲۵', unit => "day" },
            { type => "literal", value => " روز پیش" },
        ],
    },
    
    # Test with Tamil (India) - Tamil numerals, dot for decimal
    {
        locale => 'ta-IN',
        # The numbering system 'taml' is algorithmic, so we need to use 'tamldec'
        options => { numeric => 'auto', numberingSystem => 'tamldec' },
        args => [4.3, 'week'],
        expects => '4.3 வாரங்கள் முன்னதாக',
        expects_parts => [
            { type => "integer", value => '௪', unit => "week" },
            { type => "decimal", value => ".", unit => "week" },
            { type => "fraction", value => '௩', unit => "week" },
            { type => "literal", value => " வாரங்களில்" },
        ],
    },
];

my $expand = sub
{
    my $all = shift( @_ );
    my @rv = ();
    foreach my $ref ( @$all )
    {
        push( @rv, '{ ' . join( ', ', map{ $_ . ' => ' . '"' . $ref->{ $_ } . '"' } sort( keys( %$ref ) ) ) . ' }' );
    }
    return( @rv );
};

my $failed = [];
for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    if( defined( $TEST_ID ) )
    {
        next unless( $i == $TEST_ID );
        last if( $i > $TEST_ID );
    }
    my $test = $tests->[$i];
    my @keys = sort( keys( %{$test->{options}} ) );
    local $" = ', ';
    my $argv_str = join( ', ', map{ "$_ => '" . $test->{options}->{ $_ } . "'" } @keys );
    subtest 'DateTime::Format::RelativeTime->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{ ${argv_str} \} )->format_to_parts( @{$test->{args}} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::RelativeTime->new( $test->{locale}, $test->{options} );
        SKIP:
        {
            isa_ok( $fmt => 'DateTime::Format::RelativeTime' );
            if( !defined( $fmt ) )
            {
                diag( "Error instantiating the DateTime::Format::RelativeTime object: ", DateTime::Format::RelativeTime->error );
                skip( "Unable to instantiate a new DateTime::Format::RelativeTime object.", 1 );
            }

            my $ref = $fmt->format_to_parts( @{$test->{args}} );
            if( !defined( $ref ) )
            {
                diag( "Error formatting relative time with arguments '", join( "', '", @{$test->{args}} ), "': ", $fmt->error );
                diag( "Error formatting relative time with arguments '", join( "', '", @{$test->{args}} ), "': ", $fmt->error );
                fail( "Error relative time with arguments '" . join( "', '", @{$test->{args}} ) . "': " . $fmt->error );
                next;
            }
            if( !is_deeply( $ref => $test->{expects_parts}, "\$fmt->format_to_parts( @{$test->{args}} ) -> [" . join( ', ', $expand->( $test->{expects_parts} ) ) . "]" ) )
            {
                push( @$failed, { test => $i, actual_parts => $ref, %$test } );
            }
        };
    };
}


done_testing();

__END__
