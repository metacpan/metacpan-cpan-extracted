package Business::UPS;

use LWP::UserAgent;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require 5.003;

require Exporter;

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw(
	     getUPS
	     UPStrack
);

#	Copyright 2003 Justin Wheeler <upsmodule@datademons.com>
#	Copyright 1998 Mark Solomon <msolomon@seva.net> (See GNU GPL)
#	Started 01/07/1998 Mark Solomon 

$VERSION = '2.01';

sub getUPS {

    my ($product, $origin, $dest, $weight, $country , $rate_chart, $length,
	$width, $height, $oversized, $cod) = @_;

    $country ||= 'US';

    my $ups_cgi = 'http://www.ups.com/using/services/rave/qcostcgi.cgi';
    my $workString = "?";
    $workString .= "accept_UPS_license_agreement=yes&";
    $workString .= "10_action=3&";
    $workString .= "13_product=" . $product . "&";
    $workString .= "15_origPostal=" . $origin . "&";
    $workString .= "19_destPostal=" . $dest . "&";
    $workString .= "23_weight=" . $weight;
    $workString .= "&22_destCountry=" . $country if $country;
    $workString .= "&25_length=" . $length if $length;
    $workString .= "&26_width=" . $width if $width;
    $workString .= "&27_height=" . $height if $height;
    $workString .= "&29_oversized=1" if $oversized;
    $workString .= "&47_rate_chart=" . $rate_chart if $rate_chart;
    $workString .= "&30_cod=1" if $cod;
    $workString = "${ups_cgi}${workString}";

    my $lwp = LWP::UserAgent->new();
    my $result = $lwp->get($workString);

    Error("Failed fetching data.") unless $result->is_success;
    
    my @ret = split('%', $result->content);
    
    if (! $ret[5]) {
	# Error
	return (undef,undef,$ret[1]);
    }
    else {
	# Good results
	my $total_shipping = $ret[10];
	my $ups_zone = $ret[6];
	return ($total_shipping,$ups_zone,undef);
    }
}

sub UPStrack {
    my $tracking_number = shift;
    my %retValue;
    
    $tracking_number || Error("No number to track in UPStrack()");

    my $lwp = LWP::UserAgent->new();
    my $result = $lwp->get("http://wwwapps.ups.com/tracking/tracking.cgi?tracknum=$tracking_number");
    Error("Cannot get data from UPS") unless $result->is_success();

    my $tracking_data = $result->content();
    my %post_data;
    my ($url, $data);

    if (($url, $data) = $tracking_data =~ /<form action="?(.+?)"? method="?post"?>(.+)<\/form>/ims and $1 =~ /WebTracking\/processRequest/)
    {
    	while ($data =~ s/<input type="?hidden"? name="?(.+?)"? value="?(.+?)"?>//ims)
	{
		$post_data{$1} = $2;
	}
    }
    else
    {
    	Error("Cannot parse output from UPS!");
    }

    my ($imagename) = $tracking_data =~ /<input type="?image"? .+? name="?(.+?)"?>/;

    $post_data{"${imagename}.x"} = 0;
    $post_data{"${imagename}.y"} = 0;
    
    my $result2 = $lwp->post($url, \%post_data, Referer => "http://wwwaaps.ups.com/tracking/tracking.cgi?tracknum=$tracking_number");

    Error("Failed fetching tracking data from UPS!") unless $result2->is_success;
    
    my $raw_data = $result2->content();
    
    $raw_data =~ tr/\r//d;
    $raw_data =~ s/<.*?>//gims;
    $raw_data =~ s/&nbsp;/ /gi;
    $raw_data =~ s/^\s+//gms;
    $raw_data =~ s/\s+$//gms;
    $raw_data =~ s/\s{2,}/ /gms;
    
    my @raw_data = split(/\n/, $raw_data);
    my %scanning;
    my $progress;
    my $count = 0;
    my $reference;

    for (my $q = 0; $q < @raw_data; $q++)
    {
    	# flip thru the text in the page line-by-line
        if ($progress == 1)
	{
	    # progress will == 1 when we've found the line that says 'package progress'
	    # which means from here on in, we're tracking the package.

	    if ($raw_data[$q] =~ /Tracking results provided by UPS: (.+)/)
	    {
	    	$progress = 0;
		$retValue{'Last Updated'} = $1 . ' ' . $raw_data[$q+1];
	    }
	    elsif ($raw_data[$q] =~ /\w+\s+\d+,\s+\d+/)
	    {
	        # would match jun 10, 2003
	        $reference = $raw_data[$q];
	    }
	    elsif ($raw_data[$q] =~ /\d+:\d+\s+\w\.\w\./)
	    {
	    	# matches 2:10 a.m.
	        $scanning{++$count}{'time'} = $raw_data[$q];
		
		$scanning{$count}{'date'} ||= $reference;
	    }
	    elsif ($raw_data[$q] =~ /,$/)
	    {
	        # if it ends in a comma, then it's an unfinished location e.g.:
		# austin,
		# tx,
		# us
		
	    	$scanning{$count}{'location'} .= ' ' . $raw_data[$q];
	    }
	    else
	    {
	        # if all else fails, it's either the last line of the
		# location, or it's the description.  we check that by
		# seeing if the current location ends in a comma.
		
		next unless $scanning{$count}{'date'};

	    	if ($scanning{$count}{'location'} =~ /,$/)
		{
			$scanning{$count}{'location'} .= ' ' . $raw_data[$q];
		}
		else
		{
			$scanning{$count}{'activity'} = $raw_data[$q];
		}
	    }
	}
	else
	{
	    # html tables make life easy. :)
	    
    	    $retValue{'Current Status'} = $raw_data[$q+1] if uc($raw_data[$q]) eq 'STATUS:';
	    
	    $retValue{'Shipped To'}     = $raw_data[$q+1] if uc($raw_data[$q]) eq 'SHIPPED TO:';
	    $retValue{'Shipped To'}    .= ' ' . $raw_data[$q+2] if $raw_data[$q+1] =~ /,$/ and uc($raw_data[$q]) eq 'SHIPPED TO:';
	    $retValue{'Shipped To'}    .= ' ' . $raw_data[$q+3] if $raw_data[$q+2] =~ /,$/ and uc($raw_data[$q]) eq 'SHIPPED TO:';
	
	    $retValue{'Delivered To'}	= $raw_data[$q+1] if uc($raw_data[$q]) eq 'DELIVERED TO:';
	    $retValue{'Delivered To'}  .= ' ' . $raw_data[$q+2] if $raw_data[$q+1] =~ /,$/ and uc($raw_data[$q]) eq 'DELIVERED TO:';
	    $retValue{'Delivered To'}  .= ' ' . $raw_data[$q+3] if $raw_data[$q+2] =~ /,$/ and uc($raw_data[$q]) eq 'DELIVERED TO:';
    
	    $retValue{'Shipped On'}     = $raw_data[$q+1] if uc($raw_data[$q]) eq 'SHIPPED OR BILLED ON:';
	    $retValue{'Service Type'}   = $raw_data[$q+1] if uc($raw_data[$q]) eq 'SERVICE TYPE:';
	    $retValue{'Weight'}         = $raw_data[$q+1] if uc($raw_data[$q]) eq 'WEIGHT:';
	    $retValue{'Delivery Date'}  = $raw_data[$q+1] if uc($raw_data[$q]) eq 'DELIVERED ON:';
	    $retValue{'Signed By'}	= $raw_data[$q+1] if uc($raw_data[$q]) eq 'SIGNED BY:';
	    $retValue{'Location'}	= $raw_data[$q+1] if uc($raw_data[$q]) eq 'LOCATION:';

	    $progress = 1 if uc($raw_data[$q]) eq 'PACKAGE PROGRESS:';
	}
    }

    $retValue{'Scanning'} = \%scanning;
    $retValue{'Activity Count'} = $count;
    $retValue{'Notice'} = "UPS authorizes you to use UPS tracking systems solely to track shipments tendered by or for you to UPS for delivery and for no other purpose. Any other use of UPS tracking systems and information is strictly prohibited.";
    
    return %retValue;
}

sub Error {
    my $error = shift;
    print STDERR "$error\n";
    exit(1);
}


END {}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

Business::UPS - A UPS Interface Module

=head1 SYNOPSIS

  use Business::UPS;

  my ($shipping,$ups_zone,$error) = getUPS(qw/GNDCOM 23606 23607 50/);
  $error and die "ERROR: $error\n";
  print "Shipping is \$$shipping\n";
  print "UPS Zone is $ups_zone\n";

  %track = UPStrack("z10192ixj29j39");
  $track{error} and die "ERROR: $track{error}";

  # 'Delivered' or 'In-transit'
  print "This package is $track{Current Status}\n"; 

=head1 DESCRIPTION

A way of sending four arguments to a module to get shipping charges 
that can be used in, say, a CGI.

=head1 REQUIREMENTS

I've tried to keep this package to a minimum, so you'll need:

=over 4

=item *

Perl 5.003 or higher

=item *

LWP::UserAgent Module

=back 4


=head1 ARGUMENTS for getUPS()

Call the subroutine with the following values:

  1. Product code (see product-codes.txt)
  2. Origin Zip Code
  3. Destination Zip Code
  4. Weight of Package

and optionally:

  5.  Country Code, (see country-codes.txt)
  6.  Rate Chart (drop-off, pick-up, etc - see below)
  6.  Length,
  7.  Width,
  8.  Height,
  9.  Oversized (defined if oversized), and
  10. COD (defined if C.O.D.)

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

The tracking number.

  use Business::UPS;
  %t = UPStrack("1ZX29W290250xxxxxx");
  print "This package is $track{'Current Status'}\n";

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
	
The hash that's returned is like the following:

  'Last Updated' 	=> 'Jun 10 2003 12:28 P.M.'
  'Shipped On'		=> 'June 9, 2003'
  'Signed By'		=> 'SIGNATURE'
  'Shipped To'		=> 'LOS ANGELES,CA,US'
  'Scanning'		=> HASH(0x146e0c) (more later...)
  'Activity Count'	=> 5
  'Weight'		=> '16.00 Lbs'
  'Current Status'	=> 'Delivered'
  'Location'		=> 'RESIDENTIAL'
  'Service Type'	=> 'STANDARD'

Notice the key 'Scanning' is a reference to a hash.
(Which is a reference to another hash.)

Scanning will contain a hash with keys 1 .. (Activity Count)
Each of those values is another hash, holding a reference to
an activity that's happened to an item.  (See example for
details)

  %hash{Scanning}{1}{'location'} = 'MESQUITE,TX,US';
  %hash{Scanning}{1}{'date'} = 'Jun 10, 2003';
  %hash{Scanning}{1}{'time'} = '12:55 A.M.';
  %hash{Scanning}{1}{'activity'} = 'ARRIVAL SCAN';
  %hash{Scanning}{2}{'location'} = 'MESQUITE,TX,US';
  .
  .
  .
  %hash{Scanning}{x}{'activity'} = 'DELIVERED';

NOTE: The items generally go in reverse chronological order.

=back

=head1 EXAMPLE

=over 4

=item getUPS()

To retreive the shipping of a 'Ground Commercial' Package 
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

  %t = UPStrack("z10192ixj29j39");
  $t{error} and die "ERROR: $t{error}";
	
  print "This package is $t{'Current Status'}\n"; # 'Delivered' or 
						  # 'In-transit'
  print "More info:\n";
  foreach $key (keys %t) {
    print "KEY: $key = $t{$key}\n";
  }

  %activities = %{$t{'Scanning'}};

  print "Package activity:\n";
  for (my $num = $t{'Activity Count'}; $num > 0; $num--)
  {
  	print "-- ITEM $num --\n";
	foreach $newkey (keys %{$activities{$num}})
	{
		print "$newkey: $activities{$num}{$newkey}\n";
	}
  }

=back

=head1 BUGS

Probably lots.  Contact me if you find them.

=head1 AUTHOR

Justin Wheeler <upsmodule@datademons.com>

mailto:upsmodule@datademons.com

This software was originally written by Mark Solomon <mailto:msoloman@seva.net> (http://www.seva.net/~msolomon/)

NOTE: UPS is a registered trademark of United Parcel Service.  Due to UPS licensing, using this software is not
be endorsed by UPS, and may not be allowed.  Use at your own risk.

=head1 SEE ALSO

perl(1).

=cut
