package Business::UPS;

use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON::PP qw(decode_json encode_json);
use Exporter 'import';
use 5.014;

our @EXPORT = qw/ getUPS UPStrack /;

#	Copyright 2003 Justin Wheeler <upsmodule@datademons.com>
#	Copyright 1998 Mark Solomon <msolomon@seva.net> (See GNU GPL)
#	Started 01/07/1998 Mark Solomon

our $VERSION = '2.04';

sub getUPS {

    warnings::warnif( 'deprecated',
        'getUPS() is deprecated: the UPS rate quoting endpoint (qcostcgi.cgi) '
        . 'has been retired by UPS. This function will be removed in a future '
        . 'release. See Business::UPS documentation for alternatives.' );

    my (
        $product, $origin, $dest,      $weight, $country, $rate_chart, $length,
        $width,   $height, $oversized, $cod
    ) = @_;

    $country ||= 'US';

    my $ups_cgi    = 'https://www.ups.com/using/services/rave/qcostcgi.cgi';
    my $workString = "?";
    $workString .= "accept_UPS_license_agreement=yes&";
    $workString .= "10_action=3&";
    $workString .= "13_product=" . $product . "&";
    $workString .= "15_origPostal=" . $origin . "&";
    $workString .= "19_destPostal=" . $dest . "&";
    $workString .= "23_weight=" . $weight;
    $workString .= "&22_destCountry=" . $country   if $country;
    $workString .= "&25_length=" . $length         if $length;
    $workString .= "&26_width=" . $width           if $width;
    $workString .= "&27_height=" . $height         if $height;
    $workString .= "&29_oversized=1"               if $oversized;
    $workString .= "&47_rate_chart=" . $rate_chart if $rate_chart;
    $workString .= "&30_cod=1"                     if $cod;
    $workString = "${ups_cgi}${workString}";

    my $lwp    = LWP::UserAgent->new(
        agent   => "Business-UPS/$VERSION",
        timeout => 30,
    );
    my $result = $lwp->get($workString);

    croak("Failed fetching data.") unless $result->is_success;

    my @ret = split( '%', $result->content );

    if ( !$ret[5] ) {

        # Error
        return ( undef, undef, $ret[1] );
    }
    else {
        # Good results
        my $total_shipping = $ret[10];
        my $ups_zone       = $ret[6];
        return ( $total_shipping, $ups_zone, undef );
    }
}

sub UPStrack {
    my $tracking_number = shift;
    my %retValue;

    $tracking_number || croak("No tracking number provided to UPStrack()");

    my $ups_url = 'https://www.ups.com/track/api/Track/GetStatus?loc=en_US';
    my $payload = encode_json( {
        Locale         => 'en_US',
        TrackingNumber => [$tracking_number],
    } );

    my $lwp = LWP::UserAgent->new(
        agent   => "Business-UPS/$VERSION",
        timeout => 30,
    );
    my $result = $lwp->post(
        $ups_url,
        'Content-Type' => 'application/json',
        Content        => $payload,
    );

    croak("Cannot get tracking data from UPS") unless $result->is_success();

    my $json;
    eval { $json = decode_json( $result->content() ) };
    croak("Cannot parse JSON response from UPS: $@") if $@;

    my $details = $json->{trackDetails};
    croak("No tracking details returned from UPS") unless $details && ref($details) eq 'ARRAY' && @$details;

    my $track = $details->[0];

    $retValue{'Current Status'} = $track->{packageStatus} if $track->{packageStatus};
    $retValue{'Service Type'}   = $track->{service}        if $track->{service};

    if ( my $w = $track->{weight} ) {
        if ( $w->{weight} ) {
            my $unit = $w->{unitOfMeasurement} || '';
            $retValue{'Weight'} = length($unit) ? "$w->{weight} $unit" : $w->{weight};
        }
    }

    if ( my $addr = $track->{shipToAddress} ) {
        my @parts = grep { $_ } @{$addr}{qw(city state country)};
        $retValue{'Shipped To'} = join( ', ', @parts ) if @parts;
    }

    my $delivery_date = $track->{scheduledDeliveryDate} || $track->{deliveredDate};
    $retValue{'Delivery Date'} = $delivery_date if $delivery_date;
    $retValue{'Signed By'}     = $track->{receivedBy}  if $track->{receivedBy};
    $retValue{'Location'}      = $track->{leftAt}      if $track->{leftAt};

    my %scanning;
    my $count = 0;

    if ( my $activities = $track->{shipmentProgressActivities} ) {
        for my $act (@$activities) {
            $count++;
            $scanning{$count}{'date'}     = $act->{date}         if $act->{date};
            $scanning{$count}{'time'}     = $act->{time}         if $act->{time};
            $scanning{$count}{'location'} = $act->{location}     if $act->{location};
            $scanning{$count}{'activity'} = $act->{activityScan} if $act->{activityScan};
        }
    }

    $retValue{'Scanning'}       = \%scanning;
    $retValue{'Activity Count'} = $count;
    $retValue{'Notice'}         = "UPS authorizes you to use UPS tracking systems solely to track shipments tendered by or for you to UPS for delivery and for no other purpose. Any other use of UPS tracking systems and information is strictly prohibited.";

    return %retValue;
}

1;

__END__

=for markdown [![testsuite](https://github.com/cpan-authors/Business-UPS/actions/workflows/testsuite.yml/badge.svg)](https://github.com/cpan-authors/Business-UPS/actions/workflows/testsuite.yml)

=head1 NAME

Business::UPS - A UPS Interface Module

=head1 SYNOPSIS

  use Business::UPS;

  my ($shipping,$ups_zone,$error) = getUPS(qw/GNDCOM 23606 23607 50/);
  $error and die "ERROR: $error\n";
  print "Shipping is \$$shipping\n";
  print "UPS Zone is $ups_zone\n";

  my %track = eval { UPStrack("1Z12345E0205271688") };
  die "ERROR: $@" if $@;

  # 'Delivered' or 'In Transit'
  print "This package is $track{'Current Status'}\n";

=head1 DESCRIPTION

A way of sending four arguments to a module to get shipping charges
that can be used in, say, a CGI.

B<NOTE:> The C<getUPS()> function is B<deprecated>. The UPS rate quoting
endpoint (C<qcostcgi.cgi>) it relied on has been permanently retired by UPS.
Calls to C<getUPS()> will emit a deprecation warning and will always fail
with an HTTP error. This function will be removed in a future release.

For rate quoting, consider using L<Business::Shipping> or the
L<UPS Rating API|https://developer.ups.com/api/reference?loc=en_US#tag/Rating_other>
directly.

=head1 REQUIREMENTS

I've tried to keep this package to a minimum, so you'll need:

=over 4

=item *

Perl 5.014 or higher

=item *

LWP::UserAgent

=item *

JSON::PP (core since Perl 5.14)

=back


=head1 ARGUMENTS for getUPS() (DEPRECATED)

B<This function is deprecated.> The UPS endpoint it uses no longer exists.
See L</DESCRIPTION> for alternatives.

Call the subroutine with the following values:

  1. Product code (see product-codes.txt)
  2. Origin Zip Code
  3. Destination Zip Code
  4. Weight of Package

and optionally:

  5.  Country Code, (see country-codes.txt)
  6.  Rate Chart (drop-off, pick-up, etc - see below)
  7.  Length,
  8.  Width,
  9.  Height,
  10. Oversized (defined if oversized), and
  11. COD (defined if C.O.D.)

=over 4

=item 1

Product Codes:

  1DM		Next Day Air Early AM
  1DML		Next Day Air Early AM Letter
  1DA		Next Day Air
  1DAL		Next Day Air Letter
  1DP		Next Day Air Saver
  1DPL		Next Day Air Saver Letter
  2DM		2nd Day Air A.M.
  2DA		2nd Day Air
  2DML		2nd Day Air A.M. Letter
  2DAL		2nd Day Air Letter
  3DS		3 Day Select
  GNDCOM	Ground Commercial
  GNDRES	Ground Residential
  XPR		Worldwide Express
  XDM		Worldwide Express Plus
  XPRL		Worldwide Express Letter
  XDML		Worldwide Express Plus Letter
  XPD		Worldwide Expedited


In an HTML "option" input it might look like this:

  <OPTION VALUE="1DM">Next Day Air Early AM
  <OPTION VALUE="1DML">Next Day Air Early AM Letter
  <OPTION SELECTED VALUE="1DA">Next Day Air
  <OPTION VALUE="1DAL">Next Day Air Letter
  <OPTION VALUE="1DP">Next Day Air Saver
  <OPTION VALUE="1DPL">Next Day Air Saver Letter
  <OPTION VALUE="2DM">2nd Day Air A.M.
  <OPTION VALUE="2DA">2nd Day Air
  <OPTION VALUE="2DML">2nd Day Air A.M. Letter
  <OPTION VALUE="2DAL">2nd Day Air Letter
  <OPTION VALUE="3DS">3 Day Select
  <OPTION VALUE="GNDCOM">Ground Commercial
  <OPTION VALUE="GNDRES">Ground Residential

=item 2

Origin Zip(tm) Code

Origin Zip Code as a number or string (NOT +4 Format)

=item 3

Destination Zip(tm) Code

Destination Zip Code as a number or string (NOT +4 Format)

=item 4

Weight

Weight of the package in pounds

=item 5

Country

Defaults to US

=item 6

Rate Chart

How does the package get to UPS:

Can be one of the following:

   Regular Daily Pickup
   On Call Air
   One Time Pickup
   Letter Center
   Customer Counter


=back

=head1 ARGUMENTS for UPStrack()

The tracking number. Dies on error (use eval to catch).

  use Business::UPS;
  my %t = eval { UPStrack("1ZX29W290250xxxxxx") };
  die "ERROR: $@" if $@;
  print "This package is $t{'Current Status'}\n";

=head1 RETURN VALUES

=over 4

=item getUPS()

	The raw LWP::UserAgent get returns a list with the following values:

	  ##  Desc		Typical Value
	  --  ---------------   -------------
	  0.  Name of server: 	UPSOnLine3
	  1.  Product code:	GNDCOM
	  2.  Orig Postal:	23606
	  3.  Country:		US
	  4.  Dest Postal:	23607
	  5.  Country:		US
	  6.  Shipping Zone:	002
	  7.  Weight (lbs):	50
	  8.  Sub-total Cost:	7.75
	  9.  Addt'l Chrgs:	0.00
	  10. Total Cost:	7.75

=item UPStrack()

The hash that's returned contains the following keys:

  'Current Status'  => 'Delivered'         # or 'In Transit'
  'Service Type'    => 'UPS Ground'
  'Weight'          => '5.00 LBS'
  'Shipped To'      => 'ANYTOWN, CA, US'
  'Delivery Date'   => 'Wednesday, 01/14/2026'
  'Signed By'       => 'SMITH'             # if delivered
  'Location'        => 'Front Door'        # if delivered
  'Activity Count'  => 3
  'Scanning'        => HASH(0x...)         # see below
  'Notice'          => 'UPS authorizes...'

Notice the key 'Scanning' is a reference to a hash.
(Which is a reference to another hash.)

Scanning will contain a hash with keys 1 .. (Activity Count)
Each of those values is another hash, holding a reference to
an activity that's happened to an item.  (See example for
details)

  $hash{Scanning}{1}{'location'} = 'ANYTOWN, CA, US';
  $hash{Scanning}{1}{'date'} = 'January 14, 2026';
  $hash{Scanning}{1}{'time'} = '11:57 A.M.';
  $hash{Scanning}{1}{'activity'} = 'Delivered';
  $hash{Scanning}{2}{'location'} = 'ANYTOWN, CA, US';
  ...

NOTE: The items generally go in reverse chronological order.

Dies on error (HTTP failure, invalid JSON, missing tracking data).
Use eval {} to catch errors.

=back

=head1 EXAMPLE

=over 4

=item getUPS()

To retrieve the shipping of a 'Ground Commercial' Package
weighing 25lbs. sent from 23001 to 24002 this package would 
be called like this:

  #!/usr/local/bin/perl
  use Business::UPS;

  my ($shipping,$ups_zone,$error) = getUPS(qw/GNDCOM 23001 23002 25/);
  $error and die "ERROR: $error\n";
  print "Shipping is \$$shipping\n";
  print "UPS Zone is $ups_zone\n";

=item UPStrack()

  #!/usr/local/bin/perl

  use Business::UPS;

  my %t = eval { UPStrack("1Z12345E0205271688") };
  die "ERROR: $@" if $@;

  print "This package is $t{'Current Status'}\n"; # 'Delivered' or
                                                  # 'In Transit'
  print "More info:\n";
  foreach my $key (keys %t) {
    print "KEY: $key = $t{$key}\n";
  }

  my %activities = %{$t{'Scanning'}};

  print "Package activity:\n";
  for (my $num = $t{'Activity Count'}; $num > 0; $num--)
  {
    print "-- ITEM $num --\n";
    foreach my $newkey (keys %{$activities{$num}})
    {
      print "$newkey: $activities{$num}{$newkey}\n";
    }
  }

=back

=head1 BUGS

Please report bugs via the GitHub issue tracker at
L<https://github.com/cpan-authors/Business-UPS/issues>.

=head1 AUTHOR

Justin Wheeler <upsmodule@datademons.com>

Originally written by Mark Solomon.

NOTE: UPS is a registered trademark of United Parcel Service.  Due to UPS licensing, using this software is not
be endorsed by UPS, and may not be allowed.  Use at your own risk.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See L<perlartistic> and L<perlgpl>.

=head1 SEE ALSO

perl(1).

=cut
