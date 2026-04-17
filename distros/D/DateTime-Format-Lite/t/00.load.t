# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use Test::More qw( no_plan );
};

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use_ok( 'DateTime::Format::Lite' ) or BAIL_OUT( 'Cannot load DateTime::Format::Lite' );
    use_ok( 'DateTime::Format::Lite::Exception' );
    use_ok( 'DateTime::Format::Lite::PP' );
};

can_ok( 'DateTime::Format::Lite', qw(
    new
    format_datetime
    format_duration
    parse_datetime
    parse_duration
    debug
    locale
    on_error
    pattern
    strict
    time_zone
    zone_map
) );

diag( "XS loaded: ", ( $DateTime::Format::Lite::IsPurePerl ? 'no (pure-Perl fallback)' : 'yes' ) );

done_testing();

__END__

