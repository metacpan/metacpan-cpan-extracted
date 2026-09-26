#!perl
##----------------------------------------------------------------------------
## SQL API Abstraction - t/010_sqlite_datetime_parser.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use lib './lib';
    use Test::More;
    select(($|=1,select(STDERR),$|=1)[1]);
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    eval { require DBD::SQLite; 1 } || plan( skip_all => 'DBD::SQLite is not installed' );
}

BEGIN
{
    use_ok( 'DB::Object::SQLite' ) or BAIL_OUT( 'Cannot load DB::Object::SQLite' );
};

my $dbo = DB::Object::SQLite->new;
ok( $dbo, 'Created SQLite object for timestamp parser tests' );

my @cases = (
    [ '2019-06-20 02:03:14',        2019, 6, 20, 2, 3, 14 ],
    [ '2019/06/20 02:03:14',        2019, 6, 20, 2, 3, 14 ],
    [ '2019-06-20T02:03:14',        2019, 6, 20, 2, 3, 14 ],
    [ '2019-06-20 02:03:14.123456', 2019, 6, 20, 2, 3, 14 ],
    [ '2019-06-20 02:03:14+09',     2019, 6, 20, 2, 3, 14 ],
    [ '2019-06-20 02:03:14+0900',   2019, 6, 20, 2, 3, 14 ],
    [ '2019-06-20',                 2019, 6, 20, 0, 0, 0 ],
    [ '2019/06/20',                 2019, 6, 20, 0, 0, 0 ],
);

foreach my $case ( @cases )
{
    my( $input, $year, $month, $day, $hour, $minute, $second ) = @$case;
    my $dt = $dbo->_parse_timestamp( $input );
    ok( $dt && $dt->isa( 'DateTime::Lite' ), "Parsed legacy SQLite timestamp '$input'" );
    next if( !$dt );
    is( $dt->year,   $year,   "$input year" );
    is( $dt->month,  $month,  "$input month" );
    is( $dt->day,    $day,    "$input day" );
    is( $dt->hour,   $hour,   "$input hour" );
    is( $dt->minute, $minute, "$input minute" );
    is( int( $dt->second ), $second, "$input second" );
}

my $fractional = $dbo->_parse_timestamp( '2019-06-20 02:03:14.123456' );
ok( $fractional, 'Fractional timestamp parsed' );
if( $fractional )
{
    cmp_ok( $fractional->nanosecond, '>', 0, 'Fractional seconds are preserved by Module::Generic parser' );
}

is( $dbo->_parse_timestamp( '2019-06-20 trailing text' ), '', 'Trailing text is rejected instead of partially parsed' );

done_testing();

__END__
