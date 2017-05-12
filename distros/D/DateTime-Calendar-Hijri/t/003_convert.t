use strict;
BEGIN { $^W = 1 }

use Test::More tests => 2004;
use DateTime::Calendar::Hijri;

# "calendar conversion consistency stress test"
#
# The correctness of the conversion itself is not tested, as the correct
# results are often unknown (and I would have to use the module itself
# to get the correct answers).

for (0..500) {
    my $rd = $_*2000;
    my $testdate = DateTime::Calendar::_Test->new( $rd, 60, 1e8 );
    my $hijridate = DateTime::Calendar::Hijri->from_object(
                                                object => $testdate );
    isa_ok( $hijridate, 'DateTime::Calendar::Hijri' );

    my ($rd2, $secs, $nano) = $hijridate->utc_rd_values;
    is( $rd2, $rd, "correct rd $rd" );
    is( $secs, 60, "correct secs" );
    is( $nano, 1e8, "correct nanosecs" );
}

# Package for testing calendar conversions

sub DateTime::Calendar::_Test::new {
    my $class = shift;
    my %p;
    @p{qw/rd rd_secs rd_nano/} = @_;
    bless \%p, $class;
}

sub DateTime::Calendar::_Test::utc_rd_values {
    my $self = shift;
    return $self->{rd}, $self->{rd_secs}, $self->{rd_nano};
}
