use Test::More tests => 19;

use Business::ISMN;

my $GOOD_ISMN          = 'M706208053';
my $GOOD_ISMN_STRING   = 'M-706208-05-3';
my $GOOD_EAN           = '9790706208053';
my $COUNTRY_STRING     = 'LT';
my $PUBLISHER_CODE     = '706208';
my $BAD_CHECKSUM_ISMN  = 'M706208057';
my $BAD_PUBLISHER_ISMN = 'M456922572';
my $NULL_ISMN          = undef;
my $NO_GOOD_CHAR_ISMN  = 'abcdefghij';
my $SHORT_ISMN         = 'M156592';

# test to see if we can construct an object?
my $ismn = Business::ISMN->new( $GOOD_ISMN );
isa_ok( $ismn, 'Business::ISMN' );
is( $ismn->is_valid,       Business::ISMN::GOOD_ISMN, "$GOOD_ISMN is valid" );
is( $ismn->country,        $COUNTRY_STRING,   "$GOOD_ISMN has publisher string");
is( $ismn->publisher_code, $PUBLISHER_CODE,   "$GOOD_ISMN has right publisher");
is( $ismn->as_string,      $GOOD_ISMN_STRING, "$GOOD_ISMN stringifies correctly");
is( $ismn->as_string([]),  $GOOD_ISMN,        "$GOOD_ISMN stringifies correctly");

# and bad checksums?
$ismn = Business::ISMN->new( $BAD_CHECKSUM_ISMN );
isa_ok( $ismn, 'Business::ISMN' );
is( $ismn->is_valid, Business::ISMN::BAD_CHECKSUM,
	"$BAD_CHECKSUM_ISMN is invalid" );

#after this we should have a good ISMN
$ismn->fix_checksum;
is( $ismn->is_valid, Business::ISMN::GOOD_ISMN,
	"$BAD_CHECKSUM_ISMN had checksum fixed" );

# bad publisher code?
$ismn = Business::ISMN->new( $BAD_PUBLISHER_ISMN );
isa_ok( $ismn, 'Business::ISMN' );
is( $ismn->is_valid, Business::ISMN::INVALID_PUBLISHER_CODE,
	"$BAD_PUBLISHER_ISMN is invalid" );

# convert to EAN?
$ismn = Business::ISMN->new( $GOOD_ISMN );
is( $ismn->as_ean, $GOOD_EAN, "$GOOD_ISMN converted to EAN" );

# do exportable functions do the right thing?
{
my $SHORT_ISMN = $GOOD_ISMN;
chop $SHORT_ISMN;

my $valid = Business::ISMN::is_valid_checksum( $SHORT_ISMN );
is( $valid, Business::ISMN::BAD_ISMN, "Catch short ISMN string" );
}

is( Business::ISMN::is_valid_checksum( $GOOD_ISMN ),
	Business::ISMN::GOOD_ISMN, 'is_valid_checksum with good ISMN' );
is( Business::ISMN::is_valid_checksum( $BAD_CHECKSUM_ISMN ),
	Business::ISMN::BAD_CHECKSUM, 'is_valid_checksum with bad checksum ISMN' );
is( Business::ISMN::is_valid_checksum( $NULL_ISMN ),
	Business::ISMN::BAD_ISMN, 'is_valid_checksum with bad ISMN' );
is( Business::ISMN::is_valid_checksum( $NO_GOOD_CHAR_ISMN ),
	Business::ISMN::BAD_ISMN, 'is_valid_checksum with no good char ISMN' );
is( Business::ISMN::is_valid_checksum( $SHORT_ISMN ),
	Business::ISMN::BAD_ISMN, 'is_valid_checksum with short ISMN' );


SKIP:
	{
	my $file = "ismns.txt";
	open FILE, $file or
		skip( "Could not read $file: $!", 1, 'Need $file');

	print STDERR "\nChecking ISMNs... (this may take a bit)\n";

	my $bad = 0;
	while( <FILE> )
		{
		chomp;
		next unless /\S+/;
		my $ismn = Business::ISMN->new( $_ );

		my $result = $ismn->is_valid;
		$bad++ unless $result eq Business::ISMN::GOOD_ISMN;
		print STDERR "$_ is not valid? [$result]\n"
			unless $result eq Business::ISMN::GOOD_ISMN;
		}

	close FILE;

	ok( $bad == 0, "Match ISMNs" );
	}
