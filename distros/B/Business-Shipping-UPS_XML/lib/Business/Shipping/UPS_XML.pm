#!/usr/bin/perl
################################################################################
#
#  Script Name : UPS_XML.pm
#  Version     : 1
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Description: A custom self contained module to calculate UPS rates using the
#               newer XML method.  This module properly calulates rates between
#               and within other non-US countries including Canada.
#               
#  Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.
#
#  $Header: /home/cvs/interchange_upsxml/lib/Business/Shipping/UPS_XML.pm,v 1.1 2004/06/27 13:59:11 dlhinkley Exp $
#
#  $Log: UPS_XML.pm,v $
#  Revision 1.1  2004/06/27 13:59:11  dlhinkley
#  Rename module
#
#  Revision 1.6  2004/06/27 13:53:20  dlhinkley
#  Rename module to UPS_XML
#
#  Revision 1.5  2004/06/16 00:52:45  dlhinkley
#  Clean up docs and add capability of multiple quantity of packages
#
#  Revision 1.4  2004/06/15 14:56:34  dlhinkley
#  Added sending dimensions for multiple packages
#
#  Revision 1.3  2004/06/10 02:03:16  dlhinkley
#  Fixed bugs from breaking up code and putting in CPAN format
#
#  Revision 1.2  2004/06/01 02:48:25  dlhinkley
#  Changes to make work
#
#  Revision 1.5  2004/05/21 21:28:36  dlhinkley
#  Add Currency
#
#  Revision 1.4  2004/04/20 01:28:00  dlhinkley
#  Added option for dimensions
#
#  Revision 1.3  2004/03/14 18:50:31  dlhinkley
#  Working version
#
#
################################################################################

package Business::Shipping::UPS_XML;
use strict;

use vars qw($VERSION);

$VERSION = "0.07";

use Net::SSLeay qw(post_https make_form make_headers);

use Business::Shipping::UPS_XML::Parser;

sub new {

   my $type  = shift;
   my ($userid,$userid_pass,$access_key,$origin_country) = @_;
   my $self  = {};
   $self->{'_userid'} = $userid;
   $self->{'_userid_pass'} = $userid_pass;
   $self->{'_access_key'} = $access_key;
   $self->{'_from_country'} = $origin_country;
   $self->{'package_type'} = '02';
   $self->{'residential'} = "1";
   $self->{'package_count'} = 0;

   bless $self, $type;
}
	
sub query_ups {

   my $self  = shift;
   my ($xml) = @_;

   my ($page, $response, %reply_headers) = post_https('www.ups.com', '443', '/ups.app/xml/Rate', 

			           make_headers(
						   
					                'content-type' => 'application/x-www-form-urlencoded',
									),
						   
                       $xml
                       );

    return ($page,$response);
}
sub set_dimensions {
	
   my $self  = shift;
   my ( $width, $height, $length, $unit_of_measure, $weight) = @_;

   $self->{'package_count'}++;

   $self->{'length'}->[ $self->{'package_count'} ]		= $length;
   $self->{'width'}->[ $self->{'package_count'} ]			= $width;
   $self->{'height'}->[ $self->{'package_count'} ]		= $height;
   $self->{'unit_of_measure'}->[ $self->{'package_count'} ] = $unit_of_measure;
   $self->{'weight'}->[ $self->{'package_count'} ] = $weight;
}
sub clr_dimensions {
	
   my $self  = shift;

   $self->{'length'} = undef;
   $self->{'width'}  = undef;
   $self->{'height'} = undef;
   $self->{'unit_of_measure'} = undef;
   $self->{'package_count'} = 0;
}
sub getUPS {
	
   my $self  = shift;
	my ( $service_code, $from_zip, $to_zip, $to_country, $weight) = @_;

    my $access_key = $self->{'_access_key'};
    my $userid = $self->{'_userid'};
    my $userid_pass = $self->{'_userid_pass'};
	my $from_country = $self->{'_from_country'};
	my $package_type = $self->{'package_type'};
	my $residential = $self->{'residential'};
	$self->{'single_weight'} = $weight;
	my $error = "";
	my $maxcost;
	my $response;
	my $zone;
	my $x;
	my $currency;
	$self->{'send_xml'} = undef;
	$self->{'rcv_xml'} = undef;




	my $xml = "<?xml version=\"1.0\"?>
<AccessRequest xml:lang=\"en-US\">
   <AccessLicenseNumber>$access_key</AccessLicenseNumber>
   <UserId>$userid</UserId>
   <Password>$userid_pass</Password>
</AccessRequest>
<?xml version=\"1.0\"?>
<RatingServiceSelectionRequest xml:lang=\"en-US\">
  <Request>
    <TransactionReference>
      <CustomerContext>Rating and Service</CustomerContext>
      <XpciVersion>1.0001</XpciVersion>
    </TransactionReference>
    <RequestAction>Rate</RequestAction> 
    <RequestOption>Rate</RequestOption> 
  </Request>
  <PickupType>
  <Code>01</Code>
  </PickupType>
  <Shipment>
    <Shipper>
      <Address>
        <StateProvinceCode></StateProvinceCode>
        <PostalCode>$from_zip</PostalCode>
        <CountryCode>$from_country</CountryCode>
      </Address>
    </Shipper>
    <ShipTo>
      <Address>
        <StateProvinceCode></StateProvinceCode>
        <PostalCode>$to_zip</PostalCode>
        <CountryCode>$to_country</CountryCode>
        <ResidentialAddressIndicator>$residential</ResidentialAddressIndicator>
      </Address>
    </ShipTo>
    <Service>
      <Code>$service_code</Code>
    </Service>
	  " . $self->_packages() . "
    <ShipmentServiceOptions/>
  </Shipment>
</RatingServiceSelectionRequest>";

    #print "$xml\n";
	$self->{'send_xml'} = $xml;
    ($xml,$response) = $self->query_ups($xml);
	$self->{'rcv_xml'} = $xml;


     #print "$response\n\n";

    $x = new Business::Shipping::UPS_XML::Parser($xml);
    $x->parse();

	my ($method,$return,$status) = split(/ /,$response);

	# Check for error
	#
	if ( $return ne "200" ) {

	    $error = "HTML $return '$response'";
	}
	elsif ( $x->{'RatingServiceSelectionResponse'}->{'Response'}->{'ResponseStatusDescription'} eq 'Failure' ) {

         $error = "UPS XML Error: " . $x->{'RatingServiceSelectionResponse'}->{'Response'}->{'Error'}->{'ErrorDescription'};
	}
	else {

		 $maxcost  = $x->{'RatingServiceSelectionResponse'}->{'RatedShipment'}->{'TotalCharges'}->{'MonetaryValue'};
		 $currency = $x->{'RatingServiceSelectionResponse'}->{'RatedShipment'}->{'TotalCharges'}->{'CurrencyCode'};
	}

    $self->clr_dimensions();

	return ($maxcost, $zone, $error,$currency);
}
sub _packages {
	
   my $self  = shift;
   my $xml;
   my $l;

   # Do packages with dimensions
   #
   if ( $self->{'package_count'} > 0 ) {


      for ($l = 1; $l <= $self->{'package_count'}; $l++) {

        $xml .= "
    <Package>
      <PackagingType>
        <Code>" . $self->{'package_type'} . "</Code>
        <Description>Package</Description>
      </PackagingType>";

        if ( $self->{'length'}->[ $l ] && $self->{'width'}->[ $l ] && $self->{'height'}->[ $l ] ) {

	      $xml .= "
	  <Dimensions>
         <UnitOfMeasurement>
           <Code>" . $self->{'unit_of_measure'}->[ $l ] . "</Code>
         </UnitOfMeasurement>
         <Length>" . $self->{'length'}->[ $l ] . "</Length>
         <Width>" . $self->{'width'}->[ $l ] . "</Width>
         <Height>" . $self->{'height'}->[ $l ] . "</Height>
      </Dimensions>";
        }

	    $xml .= "
      <Description>Rate Shopping</Description>";

        if (  $self->{'weight'}->[ $l ]  ) {

	      $xml .= "
      <PackageWeight>
        <Weight>". $self->{'weight'}->[ $l ]  . "</Weight>
      </PackageWeight>";
        }

        $xml .= "
    </Package>
		";

      }
   
   }
   else {  # A single package no dimensions

        $xml .= "
    <Package>
      <PackagingType>
        <Code>" . $self->{'package_type'} . "</Code>
        <Description>Package</Description>
      </PackagingType>";

	    $xml .= "
      <Description>Rate Shopping</Description>";

        if ( $self->{'single_weight'} > 0 ) {

	      $xml .= "
      <PackageWeight>
        <Weight>". $self->{'single_weight'} . "</Weight>
      </PackageWeight>";
        }

        $xml .= "
    </Package>
		";

   }

   return $xml;
}
sub send_xml {

   my $self  = shift;

   return $self->{'send_xml'};
}
sub rcv_xml {

   my $self  = shift;

   return $self->{'rcv_xml'};
}
#########################################################################################33
# End of class

1;
__END__

=head1 NAME

Business::Shipping::UPS_XML - UPS XML Rate Requester 

=head1 SYNOPSIS

    use Business::Shipping::UPS_XML;


	my $userid			= 'jsmith';
	my $userid_pass		= 'topsecret';
	my $access_key		= '1DC98F0EB3A13E45';
	my $origin_country	= 'CA';
	my $origin_zip		= 'L4J8J2';
	my $service_code	= '03';

    my $ups = new Business::Shipping::UPS_XML($userid,$userid_pass,$access_key,$origin_country);

    my $width	= 10;
    my $height	= 10;
    my $length	= 10;
    my $units	= 'IN';
    my $weight	= 2;

    $ups->set_dimensions( $width, $height, $length, $unit_of_measure, $weight);


    my $width	= 15;
    my $height	= 2;
    my $length	= 10;
    my $units	= 'IN';
    my $weight	= 2.3;

    $ups->set_dimensions( $width, $height, $length, $unit_of_measure, $weight);

	my $dest_country	= 'US';
	my $dest_zip		= '83711';

   ($maxcost, $zone, $error) = $ups->getUPS( $service_code, $origin_zip, $dest_zip, $dest_country);


=head1 DESCRIPTION

This module uses the XML version of the UPS Rates & Service Selection Tool to 
get UPS rates for a given package and delivery destination.  I wrote this 
after spending several hours trying to install various XML parsing modules 
and their dependancies.  This module has it's own built in parser so no
additional XML modules are needed.

One advantage to this module is it properly calculates shipments to, from and
withing Canada.  The old cgi UPS rate queries don't allow Canadian zip codes.

=head1 REQUIREMENTS

To use this module you need a online tools userid and password along with an 
access key.  See the UPS OnLine Tools section of www.ups.com for details.


=head1 COMMON METHODS

The methods described in this section are available for all 
C<Business::Shipping::UPS_XML> objects.

=over 4

=item new($userid,$userid_pass,$access_key,$origin_country)

The new method is the constructor.  The following input parameter are all 
required and must be provided in the following order:

    1.  Userid from ups.com web site.
	2.  Password from ups.com web site.
	3.  Access key from the ups.com web site.
	4.  The ISO abreviation for the country the shipment originates.

    my $ups = new UPS_XML('jsmith', 'topsecret', '1FC98F0EB3F13C45', 'CA');


=item $ups->set_dimensions( $width, $height, $length, $unit_of_measure, $weight )

Use this method if you need rates based on dimensions for one or more packages. 
To get rates for multiple packages, execute the method once for each package.

If you only need a rate based on the combined weight of one shipment, you don't
need this method.

    $ups->set_dimensions( 10, 5, 8, 'IN', 2.3 );
    $ups->set_dimensions( 4, 4, 5, 'IN', 1.1 );


=item $ups->getUPS( $service_code, $origin_zip, $dest_zip, $dest_country)

This method returns the rate for the provided service code, origin zip code, 
destination zip code, destination country and weight.  If you use the 
set_dimensions method, the weight provided here is ignored.

getUPS returns the rate, zone, error code and currency the rate is in.  After 
this method is executed, the dimensions provided by the set_dimensions method
are cleared.

This module understand the following service codes:

	UPS Express				01		
	UPS Next Day Air		01	
	UPS Expedited			02	
	UPS 2nd Day Air			02	
	UPS Ground				03 
	UPS Worldwide Express	07		
	UPS Worldwide Expedited	08	
	UPS Standard			11	
	UPS 3 Day Select		12		
	UPS Express Saver		13	
	UPS Next Day Air Saver	13	
	UPS Express Early AM	14	
	UPS Next Day Early AM	14
	UPS Worldwide Express Plus	54	
	UPS 2nd Day Air A.M.	59	
	UPS Express NAI	64	
	UPS Express Saver (US)	65	
	UPS Express Saver (Eur)	65	


   ($maxcost, $zone, $error, $currency) = $ups->getUPS( '03', 'L4J8J2', '83711', 'US', 3);



=back


=head1 AUTHOR

Duane Hinkley, <F<duane@dhwd.com>>

L<http://www.DownHomeWebDesign.com>

Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

If you have any questions, comments or suggestions please feel free 
to contact me.


=cut

1;

