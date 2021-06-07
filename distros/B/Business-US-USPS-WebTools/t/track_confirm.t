#!/usr/bin/perl


use Test::More;

my $class  = "Business::US::USPS::WebTools::TrackConfirm";
my $method = 'track';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
unless( $ENV{USPS_WEBTOOLS_USERID} and $ENV{USPS_WEBTOOLS_PASSWORD} )
	{
	plan skip_all =>
	"You must set the USPS_WEBTOOLS_USERID and USPS_WEBTOOLS_PASSWORD " .
	"environment variables to run these tests\n";
	}

my $is_testing = uc($ENV{USPS_WEBTOOLS_ENVIRONMENT}) eq 'TESTING';

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, $method );
	};

my $tracker;
subtest create_tracker => sub {
	$tracker = $class->new( {
		UserID   => $ENV{USPS_WEBTOOLS_USERID},
		Password => $ENV{USPS_WEBTOOLS_PASSWORD},
		Testing  => $is_testing,
		} );
	isa_ok( $tracker, $class );
	};

=pod

These don't work even though they are documented. Simply requesting the
URL provided in the docs returns an error. These tracking IDs are supposed
to have hard-coded responses in the server and they do not.

subtest test_request_1 => sub {
	my $array = $tracker->track( TrackID => 'EJ958083578US' );
	diag $tracker->url;
	isa_ok( $array, ref [] );
	is( scalar @$array, 3, 'There are three details' );
	diag $tracker->response;
#	is( $array->[0],
	};

subtest test_request_2 => sub {
	my $array = $tracker->track( TrackID => 'EJ958088694US' );
	diag $tracker->url;
	isa_ok( $array, ref [] );
	is( scalar @$array, 3, 'There are three details' );
	diag $tracker->response;
	};

=cut

done_testing();


__END__

Test Request #1
This test shows a multi-entry return that is arranged in reverse chronological order.  Note that a DOM parser may scramble the order of the XML which may cause programmatic confusion.

http://production.shippingapis.com/ShippingAPITest.dll?API=TrackV2
&XML=<TrackRequest USERID="xxxxxxxx">
<TrackID ID="EJ958083578US"></TrackID></TrackRequest>

<?xml version="1.0"?>
<TrackResponse><TrackInfo ID="EJ958083578US"><TrackSummary>
Your item was delivered at 8:10 am on June 1 in Wilmington DE 19801.
</TrackSummary><TrackDetail>
May 30 11:07 am NOTICE LEFT WILMINGTON DE 19801.
</TrackDetail><TrackDetail>
May 30 10:08 am ARRIVAL AT UNIT WILMINGTON DE 19850.
</TrackDetail><TrackDetail>
May 29 9:55 am ACCEPT OR PICKUP EDGEWATER NJ 07020.
</TrackDetail></TrackInfo></TrackResponse>

Test Request #2
http://production.shippingapis.com/ShippingAPITest.dll?API=TrackV2
&XML=<TrackRequest USERID="xxxxxxxx">
<TrackID ID="EJ958088694US"></TrackID></TrackRequest>

<?xml version="1.0"?>
<TrackResponse><TrackInfo ID="EJ958088694US"><TrackSummary>
Your item was delivered at 1:39 pm on June 1 in WOBURN MA 01815.
</TrackSummary><TrackDetail>
May 30 7:44 am NOTICE LEFT WOBURN MA 01815.
</TrackDetail><TrackDetail>
May 30 7:36 am ARRIVAL AT UNIT NORTH READING MA 01889.
</TrackDetail><TrackDetail>
May 29 6:00 pm ACCEPT OR PICKUP PORTSMOUTH NH 03801.
</TrackDetail></TrackInfo></TrackResponse>
