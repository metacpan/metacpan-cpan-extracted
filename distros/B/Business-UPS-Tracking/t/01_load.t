#!perl -T

use Test::More tests => 17;

use_ok( 'Business::UPS::Tracking' );
use_ok( 'Business::UPS::Tracking::Utils' );
use_ok( 'Business::UPS::Tracking::Response' );
use_ok( 'Business::UPS::Tracking::Request' );
use_ok( 'Business::UPS::Tracking::Shipment' );
use_ok( 'Business::UPS::Tracking::Shipment::Freight' );
use_ok( 'Business::UPS::Tracking::Shipment::SmallPackage' );
use_ok( 'Business::UPS::Tracking::Element::Activity' );
use_ok( 'Business::UPS::Tracking::Element::Address' );
use_ok( 'Business::UPS::Tracking::Element::Weight' );
use_ok( 'Business::UPS::Tracking::Element::ReferenceNumber' );
use_ok( 'Business::UPS::Tracking::Element::Package' );
use_ok( 'Business::UPS::Tracking::Element::Code' );
use_ok( 'Business::UPS::Tracking::Role::Builder' );
use_ok( 'Business::UPS::Tracking::Role::Base' );
use_ok( 'Business::UPS::Tracking::Role::Print' );
use_ok( 'Business::UPS::Tracking::Commandline' );