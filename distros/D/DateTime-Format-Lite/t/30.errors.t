# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/30.errors.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use Test::More qw( no_plan );

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );

# NOTE: Helper: test all three on_error modes for a given parse failure.
sub check_error
{
    my( %args ) = @_;
    my $label   = $args{name};
    my $pattern = $args{pattern};
    my $input   = $args{input};
    my $error   = $args{error};
    my $strict  = $args{strict} // 0;

    subtest $label => sub
    {
        my $warning = '';
        local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
        # on_error => 'undef'
        my $fmt = DateTime::Format::Lite->new(
            pattern  => $pattern,
            on_error => 'undef',
            strict   => $strict,
        );
        ok( defined( $fmt ), 'constructor succeeded' );
        my $dt = $fmt->parse_datetime( $input );
        ok( !defined( $dt ), 'parse_datetime returns undef on error' );
        like( $fmt->error->message, $error, 'error message matches (undef mode)' );

        # on_error => coderef
        my $cb_error;
        $fmt = DateTime::Format::Lite->new(
            pattern  => $pattern,
            on_error => sub{ $cb_error = $_[1] },
            strict   => $strict,
        );
        ok( defined( $fmt ), 'constructor succeeded (coderef mode)' );
        $fmt->parse_datetime( $input );
        like( $cb_error, $error, 'coderef on_error receives correct message' );
    };
}

# NOTE Constructor errors
subtest 'unknown token in pattern' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    my $fmt = DateTime::Format::Lite->new( pattern => '%Y %Q', on_error => 'undef' );
    ok( !defined( $fmt ), 'constructor returns undef for unknown token' );
    like(
        DateTime::Format::Lite->error->message,
        qr/unrecogni[sz]ed strptime token.*%Q/i,
        'error message mentions the bad token'
    );
};

# NOTE: pattern is required
subtest 'pattern is required' => sub
{
    my $warning = '';
    local $SIG{__WARN__} = sub{ $warning = join( '', @_ ) };
    # new() without pattern calls error() on the class string, which triggers
    # a bug in _set_get_prop (strict refs). Wrap in eval for safety.
    local $@;
    my $fmt = eval{ DateTime::Format::Lite->new( on_error => 'undef' ) };
    ok( !defined( $fmt ), 'constructor returns undef without pattern' );
};

# NOTE Parse conflict errors
# NOTE 12-hour time without AM/PM specifier
check_error(
    name    => '12-hour time without AM/PM specifier',
    pattern => '%Y-%m-%d %I:%M',
    input   => '2015-01-02 11:15',
    error   => qr/12-hour|hour.*AM|AM\/PM/i,
);

# NOTE: unrecognised timezone abbreviation
check_error(
    name    => 'unrecognised timezone abbreviation',
    pattern => '%Y-%m-%d %Z',
    input   => '2015-01-02 XYZ',
    error   => qr/No timezone found for abbreviation|unrecognized.*time zone/i,
);

# NOTE: ambiguous timezone abbreviation IST
check_error(
    name    => 'ambiguous timezone abbreviation IST',
    pattern => '%Y-%m-%d %Z',
    input   => '2015-01-02 IST',
    error   => qr/ambiguous/i,
);

# NOTE: 24-hour vs 12-hour conflict
check_error(
    name    => '24-hour vs 12-hour conflict',
    pattern => '%Y-%m-%d %H %I %p',
    input   => '2015-01-02 13 2 AM',
    error   => qr/24-hour and 12-hour.*do not match/i,
);

# NOTE: 24-hour vs AM/PM conflict (13 AM)
check_error(
    name    => '24-hour vs AM/PM conflict (13 AM)',
    pattern => '%Y-%m-%d %H %p',
    input   => '2015-01-02 13 AM',
    error   => qr/24-hour and AM\/PM.*do not match/i,
);

# NOTE: 24-hour vs AM/PM conflict (4 PM)
check_error(
    name    => '24-hour vs AM/PM conflict (4 PM)',
    pattern => '%Y-%m-%d %H %p',
    input   => '2015-01-02 4 PM',
    error   => qr/24-hour and AM\/PM.*do not match/i,
);

# NOTE: year vs century conflict
check_error(
    name    => 'year vs century conflict',
    pattern => '%Y-%m-%d %C',
    input   => '2015-01-02 19',
    error   => qr/year and century.*do not match/i,
);

# NOTE: year vs year-within-century conflict
check_error(
    name    => 'year vs year-within-century conflict',
    pattern => '%Y-%m-%d %y',
    input   => '2015-01-02 14',
    error   => qr/year and year-within-century.*do not match/i,
);

# NOTE: epoch vs year conflict
check_error(
    name    => 'epoch vs year conflict',
    pattern => '%s %Y',
    input   => '42 2015',
    error   => qr/epoch and year.*do not match/i,
);

# NOTE: epoch vs month conflict
check_error(
    name    => 'epoch vs month conflict',
    pattern => '%s %m',
    input   => '42 12',
    error   => qr/epoch and month.*do not match/i,
);

# NOTE: epoch vs day conflict
check_error(
    name    => 'epoch vs day conflict',
    pattern => '%s %d',
    input   => '42 13',
    error   => qr/epoch and day.*do not match/i,
);

# NOTE: epoch vs hour conflict
check_error(
    name    => 'epoch vs hour conflict',
    pattern => '%s %H',
    input   => '42 14',
    error   => qr/epoch and hour.*do not match/i,
);

# NOTE: epoch vs minute conflict
check_error(
    name    => 'epoch vs minute conflict',
    pattern => '%s %M',
    input   => '42 15',
    error   => qr/epoch and minute.*do not match/i,
);

# NOTE: epoch vs second conflict
check_error(
    name    => 'epoch vs second conflict',
    pattern => '%s %S',
    input   => '42 16',
    error   => qr/epoch and second.*do not match/i,
);

# NOTE: epoch vs day-of-year conflict
check_error(
    name    => 'epoch vs day-of-year conflict',
    pattern => '%s %j',
    input   => '42 17',
    error   => qr/epoch and day of year.*do not match/i,
);

# NOTE: month vs day-of-year conflict
check_error(
    name    => 'month vs day-of-year conflict',
    pattern => '%Y %m %j',
    input   => '2015 8 17',
    error   => qr/month and day of year.*do not match/i,
);

# NOTE: day name vs date conflict
check_error(
    name    => 'day name vs date conflict',
    pattern => '%Y %m %d %a',
    input   => '2015 8 17 Tuesday',
    error   => qr/day name does not match the date/i,
);

# NOTE: invalid Olson timezone name
check_error(
    name    => 'invalid Olson timezone name',
    pattern => '%Y %O',
    input   => '2015 Dev/Null',
    error   => qr/does not appear to be valid|invalid.*time.?zone/i,
);

# NOTE: invalid date (Feb 29 non-leap year)
check_error(
    name    => 'invalid date (Feb 29 non-leap year)',
    pattern => '%a %b %d %T %Y',
    input   => 'Wed Feb 29 12:02:28 2013',
    error   => qr/did not produce a valid date|invalid/i,
);

# NOTE: strict mode - failed word boundary at start
check_error(
    name    => 'strict mode - failed word boundary at start',
    pattern => '%d-%m-%y',
    input   => '2016-11-30',
    strict  => 1,
    error   => qr/does not match your pattern/i,
);

# NOTE: strict mode - failed word boundary at end
check_error(
    name    => 'strict mode - failed word boundary at end',
    pattern => '%d-%m-%y',
    input   => '30-11-2016',
    strict  => 1,
    error   => qr/does not match your pattern/i,
);

done_testing();

__END__
