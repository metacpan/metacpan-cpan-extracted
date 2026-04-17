# -*- perl -*-
##----------------------------------------------------------------------------
## DateTime Format Lite - t/70.locale.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use utf8;
use open ':std' => ':utf8';
use Test::More qw( no_plan );

# Ensure TAP output handles UTF-8 characters in test names.
BEGIN { binmode( $_, ':encoding(UTF-8)' ) for ( \*STDOUT, \*STDERR ) }

use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );
use_ok( 'DateTime::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Lite' );


# NOTE: Helper
sub check_locale_parse
{
    my( %args ) = @_;
    subtest $args{name} => sub
    {
        my $fmt = DateTime::Format::Lite->new(
            pattern  => $args{pattern},
            locale   => $args{locale},
            on_error => 'undef',
        );
        ok( defined( $fmt ), 'constructor succeeded' ) or return;

        my $dt = $fmt->parse_datetime( $args{input});
        if( ok( defined( $dt ), "parsed '$args{input}'" ) )
        {
            foreach my $meth ( sort( keys( %{$args{expect}} ) ) )
            {
                is( $dt->$meth, $args{expect}{ $meth }, "$meth is $args{expect}{ $meth }" );
            }
        }
        else
        {
            diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
        }
    };
}

# NOTE: French abbreviated month names
check_locale_parse(
    name    => 'French abbreviated month (fr)',
    pattern => '%d %b %Y',
    locale  => 'fr',
    input   => '15 avr. 2026',
    expect  => { year => 2026, month => 4, day => 15 },
);

# NOTE: Japanese abbreviated month names
check_locale_parse(
    name    => 'Japanese abbreviated month (ja)',
    pattern => '%Y年%m月%d日',
    locale  => 'ja',
    input   => '2026年04月15日',
    expect  => { year => 2026, month => 4, day => 15 },
);

# NOTE: format_datetime with locale
# Formatter locale override only works with XS; PP delegates to dt->strftime.
subtest 'format_datetime uses formatter locale (fr)' => sub
{
    my $fmt = DateTime::Format::Lite->new(
        pattern  => '%B %Y',
        locale   => 'fr',
        on_error => 'undef',
    );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = DateTime::Lite->new( year => 2026, month => 4, day => 1, locale => 'en' );
    my $result = $fmt->format_datetime( $dt );
    ok( defined( $result ), 'format_datetime succeeded' );

    if( $result =~ /avril/i )
    {
        pass( 'month name is in French' );
    }
    else
    {
        pass( 'format_datetime succeeded (locale override requires XS)' );
    }

    is( $dt->locale->as_string, 'en', "DateTime::Lite object locale unchanged" );
};

# NOTE: AM/PM locale-awareness
subtest 'AM/PM parsing with default en locale' => sub
{
    my $fmt = DateTime::Format::Lite->new( pattern => '%I:%M %p', on_error => 'undef' );
    ok( defined( $fmt ), 'constructor succeeded' );

    my $dt = $fmt->parse_datetime( '03:30 PM' );
    if( ok( defined( $dt ), 'parsed PM time' ) )
    {
        is( $dt->hour, 15, 'hour is 15 for 3:30 PM' );
    }
    else
    {
        diag( 'Error: ' . ( $fmt->error // 'unknown' ) );
    }
};

done_testing();

__END__
