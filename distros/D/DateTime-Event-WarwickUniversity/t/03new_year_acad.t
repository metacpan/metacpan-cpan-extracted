#
# Test the new_year_for_academic_year subroutine
#

use Test::More;
use Test::Exception;
use DateTime;
use blib;
use DateTime::Event::WarwickUniversity;

my %dates = (
	"2006-10-01 23:59:59"	=>	"2005-09-26",
	"2006-10-02 00:00:00"	=>	"2006-10-02",
	"2006-01-01 00:00:00"	=>	"2005-09-26",
	"2006-12-31 23:59:59"	=>	"2006-10-02",
	"2007-01-01 00:00:00"	=>	"2006-10-02",
	"2007-11-18 21:02:13"	=>	"2007-10-01",
);

plan tests => keys(%dates) * 5 + 4;

# Test existence
can_ok('DateTime::Event::WarwickUniversity', 'new_year_for_academic_year');

#
# Test input
#

throws_ok { DateTime::Event::WarwickUniversity->new_year_for_academic_year('2006') }
	qr/must be DateTime/, "Croak on non-DateTime objects";

my $dt_1960 = DateTime->new(year => 1960);
my $dt_3000 = DateTime->new(year => 3000);

throws_ok { DateTime::Event::WarwickUniversity->new_year_for_academic_year($dt_1960)}
	qr/outside supported range/, "Croak when input DateTime too old";

throws_ok { DateTime::Event::WarwickUniversity->new_year_for_academic_year($dt_3000)}
	qr/outside supported range/, "Croak when input DateTime too new";

#
# Test output
#

while( my($in, $expected) = each %dates ) {
	$in =~ /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/;
	my $dt_in = DateTime->new(
		year => $1,
		month => $2,
		day => $3,
		hour => $4,
		minute => $5,
		second => $6,
		time_zone => 'Europe/London',
	);

	$expected =~ /^(\d{4})-(\d\d)-(\d\d)$/;
	my $dt_expected = DateTime->new( year => $1, month => $2, day => $3, time_zone => 'Europe/London' );

	my $dt_out = DateTime::Event::WarwickUniversity
					->new_year_for_academic_year($dt_in);

  SKIP: {
	# defined
	ok( defined $dt_out,
		"Method returns something for $dt_in" )
		|| skip('dt_out undefined', 4);
	# class
	is( ref($dt_out), ref($dt_in),
		"Input class same as output class");
	# time zone
	is( $dt_out->time_zone, $dt_in->time_zone,
		"Input timezone same as output timezone" );
	# locale
	is( $dt_out->locale, $dt_in->locale,
		"Input locale same as output locale");
	# result
	ok( $dt_out == $dt_expected,
		"$dt_in: expected $dt_expected, got $dt_out");
  }
}

