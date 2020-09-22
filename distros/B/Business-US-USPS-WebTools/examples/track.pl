#!perl
use v5.10;

use Data::Dumper;

use Business::US::USPS::WebTools::TrackConfirm;

my $tracker = Business::US::USPS::WebTools::TrackConfirm->new( {
	UserID   => $ENV{USPS_WEBTOOLS_USERID},
	Password => $ENV{USPS_WEBTOOLS_PASSWORD},
#	Testing  => 1,
	} );

say "ARGV is @ARGV";

my $tracking_number = $tracker->is_valid_tracking_number( $ARGV[0] );
say "Tracking number is $tracking_number";

my $data = $tracker->track( TrackID => $ARGV[0] );
say $tracker->response;
say Dumper( $data );
