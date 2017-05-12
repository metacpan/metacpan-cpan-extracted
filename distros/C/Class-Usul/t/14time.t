use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use Math::BigInt;

Math::BigInt->config()->{lib} eq 'Math::BigInt::GMP'
   and plan skip_all => 'Math::BigInt::GMP installed RT#33816';

use Class::Usul::Time qw( str2date_time str2time str2time_piece time2str );

is time2str( undef, 0, 'UTC' ), '1970-01-01 00:00:00', 'stamp';

my $dt = str2date_time( '11/9/2007 14:12', 'GMT' );

isa_ok $dt, 'DateTime';

is "${dt}", '2007-09-11T14:12:00', 'str2date_time';

is str2time( '2007-07-30 01:05:32', 'BST' ), '1185753932', 'str2time/1';

is str2time( '30/7/2007 01:05:32', 'BST' ), '1185753932', 'str2time/2';

is str2time( '30/7/2007', 'BST' ), '1185750000', 'str2time/3';

is str2time( '2007.07.30', 'BST' ), '1185750000', 'str2time/4';

is str2time( '1970/01/01', 'GMT' ), '0', 'str2time/epoch';

my $tp = str2time_piece( '2007-07-30 01:05:32', 'GMT' );

isa_ok $tp, 'Time::Piece';

is $tp, 'Mon Jul 30 01:05:32 2007', 'str2time_piece';

is time2str( '%Y-%m-%d', 0, 'UTC' ), '1970-01-01', 'time2str/1';

is time2str( '%Y-%m-%d %H:%M:%S', 1185753932, 'BST' ),
   '2007-07-30 01:05:32', 'time2str/2';

$dt = str2date_time( '1963-08-22 00:00', 'GMT' );

is $dt->dmy( '/' ), '22/08/1963', 'ISO and local formats';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
