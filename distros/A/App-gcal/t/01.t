#!perl

use strict;
use warnings;

use Test::More tests => 18;
use FindBin qw($Bin);

BEGIN { use_ok('App::gcal'); }
require_ok('App::gcal');

my $err_from_ics = App::gcal::_process_file("$Bin/../dist.ini");
isa_ok( $err_from_ics, 'Class::ReturnValue' );
like( $err_from_ics->error_message, qr/error parsing/ );

my $testfile_simple = "$Bin/resources/simple.ics";    # version 2, one event
my $cal_from_ics = App::gcal::_process_file($testfile_simple);
isa_ok( $cal_from_ics, 'Data::ICal' );

my $gcal_event =
  App::gcal::_create_new_gcal_event( @{ $cal_from_ics->entries }[0] );
isa_ok( $gcal_event, 'Net::Google::Calendar::Entry' );
is( $gcal_event->title,
    'Journey Details: Cambridge (CBG) to Harlow Mill (HWM)' );
is( $gcal_event->location, 'Cambridge Rail Station, UK' );

# test quick add
my $quick_add_text =
  'Mar 31 1976 at 12:34. Lunch with Bob';    # from ICal::QuickAdd tests
my $iqa = App::gcal::_process_text($quick_add_text);
isa_ok( $iqa, 'Data::ICal' );

is( @{ $iqa->entries }[0]->property('summary')->[0]->value, 'Lunch with Bob' );
my $time = DateTime::Format::ICal->parse_datetime(
    @{ $iqa->entries }[0]->property('dtstart')->[0]->value );
is( $time->datetime, '1976-03-31T12:34:00' );
is( $time->datetime, '1976-03-31T12:34:00' );

$gcal_event = App::gcal::_create_new_gcal_event( @{ $iqa->entries }[0] );
isa_ok( $gcal_event, 'Net::Google::Calendar::Entry' );
is( $gcal_event->title, 'Lunch with Bob' );

$quick_add_text = '';
$iqa            = App::gcal::_process_text($quick_add_text);
isa_ok( $iqa, 'Class::ReturnValue' );
like( $err_from_ics->error_message, qr/error parsing/ );

$quick_add_text = 'foo';
$iqa            = App::gcal::_process_text($quick_add_text);
isa_ok( $iqa, 'Class::ReturnValue' );
like( $err_from_ics->error_message, qr/error parsing/ );
