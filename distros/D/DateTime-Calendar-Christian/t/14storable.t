package main;

use 5.008004;

use strict;
use warnings;

use DateTime;
use DateTime::Calendar::Christian;
use Storable qw{ freeze thaw };
use Test::More 0.88;	# Because of done_testing();

my $rd = DateTime->new(		# UK
    year	=> 1752,
    month	=> 9,
    day		=> 14,
);

foreach my $test (
    [],
    [ 1751, 12, 31 ],
    [ 1752,  1,  1 ],
    [ 1752,  1, 31 ],
    [ 1752,  2, 28 ],
    [ 1752,  2, 29 ],
    [ 1752,  3,  1 ],
    [ 1752,  9,  2 ],
    [ 1752,  9, 14 ],
    [ 1752, 12, 31 ],
    [ 1753,  1,  1 ],
) {
    my ( $year, $month, $day ) = @{ $test };

    my ( $date, @arg ) = defined $year ? (
	sprintf( '%04d-%02d-%02d', $year, $month, $day ),
	year	=> $year,
	month	=> $month,
	day	=> $day,
    ) : ( 'no date' );

    my $dt = DateTime::Calendar::Christian->new(
	@arg,
	reform_date	=> $rd,
    );

    my $frozen = freeze( $dt );

    my $dt2 = thaw( $frozen );

    is_deeply $dt2, $dt, "Freeze/thaw of $date";
}


done_testing;

1;

# ex: set textwidth=72 :
