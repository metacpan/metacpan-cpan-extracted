#!/opt/perl5.10/bin/perl
# generated with /opt/perl5.10/bin/generate_00-load_t.pl
use Test::More tests => 11;


BEGIN {
	use_ok( 'Business::DPD' );
}

diag( "Testing Business::DPD Business::DPD->VERSION, Perl $], $^X" );

use_ok( 'Business::DPD::DBIC' );
use_ok( 'Business::DPD::DBIC::Schema' );
use_ok( 'Business::DPD::DBIC::Schema::DpdCountry' );
use_ok( 'Business::DPD::DBIC::Schema::DpdDepot' );
use_ok( 'Business::DPD::DBIC::Schema::DpdMeta' );
use_ok( 'Business::DPD::DBIC::Schema::DpdRoute' );
use_ok( 'Business::DPD::Label' );
use_ok( 'Business::DPD::Render' );
use_ok( 'Business::DPD::Render::PDFReuse' );
use_ok( 'Business::DPD::Render::PDFReuse::SlimA6' );
