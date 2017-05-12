package Business::FedEx::RateRequest;

use 5.008008;
use strict;
use warnings;

require Exporter;

use LWP::UserAgent;
use XML::Simple;
use Data::Dumper; 

 use Time::Piece;
 
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Business::FedEx::RateRequest ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '1.00';

# FedEx Shipping notes
our %ship_note;
$ship_note{'FEDEX SAMEDAY'} = 'Fastest Delivery time based on flight availability';
$ship_note{'FIRST_OVERNIGHT'} = 'Overnight Delivery by 8:00 or 8:30 am';										
$ship_note{'PRIORITY_OVERNIGHT'} = 'Overnight Delivery by 10:30 am';
$ship_note{'STANDARD_OVERNIGHT'} = 'Overnight Delivery by 3:00 pm';															
$ship_note{'FEDEX_2_DAY'} = '2 Business Days Delivery by 4:30 pm';
$ship_note{'FEDEX_EXPRESS_SAVER'} = '3 Business Days Delivery by 4:30 pm';	
$ship_note{'FEDEX_GROUND'} = '1-5 Business Days Delivery day based on distance to destination';	
$ship_note{'FEDEX_HOME_DELIVERY'} = '1-5 Business Days Delivery day based on distance to destination';				

$ship_note{'INTERNATIONAL_NEXT_FLIGHT'} = 'Fastest Delivery time based on flight availability';
$ship_note{'INTERNATIONAL_FIRST'}   = '2 Business Days Delivery by 8:00 or 8:30 am to select European cities';
$ship_note{'INTERNATIONAL_PRIORITY'}= '1-3 Business Days Delivery time based on country';
$ship_note{'INTERNATIONAL_ECONOMY'} = '2-5 Business Days Delivery time based on country';
$ship_note{'INTERNATIONAL_GROUND'}	= '3-7 Business Days Delivery to Canada and Puerto Rico';

# Preloaded methods go here.

sub new {

    my $name = shift;
    my $class = ref($name) || $name;

    my %args = @_;

    my $self  = {
                 uri => $args{'uri'},
                 account  => $args{'account'},
                 meter    =>  $args{'meter'},
                 key      =>  $args{'key'},
                 password =>  $args{'password'},
                 err_msg =>    "",
                };

    my @rqd_lst = qw/uri meter account key password/; 
    foreach my $param (@rqd_lst) { unless ( $args{$param} ) { $self->{'err_msg'}="$param required"; return 0; } }

    $self->{UA} = LWP::UserAgent->new(agent => 'perlworks');
    if ( $args{'timeout'} ) { $self->{UA}->timeout($args{'timeout'}); }
        
    #$self->{REQ} = HTTP::Request->new(POST=>$self->{uri}); # Create a request

    bless ($self, $class);
}

# - - - - - - - - - - - - - - -
sub get_rates
{
   my $self = shift @_;
   my %args = @_;

   # As of Jan 2014 Fedex without warning changed the return xml document. The elements with versionized name spaces were changed to generic tags.
   # so what was <v9:RateReplyDetails> is now <RateReplyDetails>  Sheessssh why would they change something like this.... 
   
   my $ver_prefix = '';  # Added a version namespace prefix in case they add it back in at a latter date.  
   	
   my @rqd_lst = qw/src_zip dst_zip weight/;    
   foreach my $param (@rqd_lst) { unless ( $args{$param} ) { $self->{'err_msg'}="$param required"; return 0; } }

   unless ( $args{'src_country'}    ) { $args{'src_country'} = 'US' }  
   unless ( $args{'dst_country'}    ) { $args{'dst_country'} = 'US' } 
   unless ( $args{'dst_residential'}) { $args{'dst_residential'} = 'false' } 
   unless ( $args{'weight_units'}   ) { $args{'weight_units'} = 'LB'} 
   unless ( $args{'size_units'}     ) { $args{'size_units'} = 'IN' } 
   unless ( $args{'length'}         ) { $args{'length'} = '5' } 
   unless ( $args{'width'}          ) { $args{'width'}  = '5' } 
   unless ( $args{'height'}         ) { $args{'height'} = '5' } 
   unless ( $args{'dropoff_type'}   ) { $args{'dropoff_type'} = 'REGULAR_PICKUP' }
   unless ( $args{'insured_value'}  ) { $args{'insured_value'} = '0' }
   
   my $datetime = localtime;
   $args{'timestamp'} = $datetime->datetime;
      
   my $xml_snd_doc = $self->gen_xml_v9(\%args); 
   #my $xml_snd_doc = $self->gen_xml_v10(\%args); 

   #-#print $xml_snd_doc; exit; # debug line 

   my $response = $self->{UA}->post($self->{'uri'}, Content_Type=>'text/xml', Content=>$xml_snd_doc);

   unless ($response->is_success) 
   {
	  $self->{'err_msg'} = "Error Request: " . $response->status_line;
      return 0; 
   }
  
   # Must be success let's parse 

   my $rtn = $response->as_string;
   $rtn =~ /(.*)\n\n(.*)/s;
   
   my $hdr = $1;  # Don't use for anything right now
   my $xml_rtn_doc = $2; # The object of this all.... 

   my $xml_obj  = new XML::Simple;    

   my $data = $xml_obj->XMLin($xml_rtn_doc); # Time consuming operation. could use a regexp to speed up if necessary. 
        
   #-#print $response->as_string; exit; # Debug line 

   my $rate_lst_ref = $data->{"${ver_prefix}RateReplyDetails"};
     
   my @rtn_lst; # This will be returned

   unless ( defined $rate_lst_ref ) 
   { 
       $self->{'err_msg'} = $data->{faultstring} || 'No rate data returned';
       return 0;
   } # Kyle's catch 

   # If only one rate service 
   if ( ref $rate_lst_ref eq 'HASH' ) { $rate_lst_ref = [ $rate_lst_ref ] }
         
   my $i = 0; 
   foreach my $detail_ref ( @{$rate_lst_ref} )
   {
      my $ah_ref = $detail_ref->{"${ver_prefix}RatedShipmentDetails"};
      my $ship_cost; 
      
      if ( ref($ah_ref) eq 'ARRAY' ) 
      {
			$ship_cost = $ah_ref->[0]->{"${ver_prefix}ShipmentRateDetail"}->{"${ver_prefix}TotalNetCharge"}->{"${ver_prefix}Amount"};
      }
      else
	  {
	        $ship_cost = $ah_ref->{"${ver_prefix}ShipmentRateDetail"}->{"${ver_prefix}TotalNetCharge"}->{"${ver_prefix}Amount"};
      }

  	  my $ServiceType = $detail_ref->{"${ver_prefix}ServiceType"};

      # Tags
      my $tag = lc($ServiceType);
      $tag =~ s/_/ /g;
      $tag =~ s/\b(\w)/\U$1/g;

	  # Notes
      my $note = $ship_note{"$ServiceType"};

      $rtn_lst[$i] = {'ServiceType'=>$ServiceType, 'ship_cost'=>$ship_cost, 'ship_tag'=>$tag, 'ship_note'=>$note};
      $i++;  
   }
   
   return wantarray ? @rtn_lst : \@rtn_lst;
 }

# - - - - - - - - - - - - - - -
sub gen_xml_v10
{
   my $self = shift; 
	my $args = shift;

	my $rqst = qq(
<?xml version="1.0" encoding="utf-8"?>
<v10:RateRequest xmlns:v10="http://fedex.com/ws/rate/v10">
<v10:WebAuthenticationDetail>
<v10:UserCredential>
<v10:Key>$self->{'key'}</v10:Key>
<v10:Password>$self->{'password'}</v10:Password>
</v10:UserCredential>
</v10:WebAuthenticationDetail>
<v10:ClientDetail>
<v10:AccountNumber>$self->{'account'}</v10:AccountNumber>
<v10:MeterNumber>$self->{'meter'}</v10:MeterNumber>
</v10:ClientDetail>
<v10:TransactionDetail>
<v10:CustomerTransactionId>Rate a Single Package V10</v10:CustomerTransactionId>
</v10:TransactionDetail>
<v10:Version>
<v10:ServiceId>crs</v10:ServiceId>
<v10:Major>10</v10:Major>
<v10:Intermediate>0</v10:Intermediate>
<v10:Minor>0</v10:Minor>
</v10:Version>
<v10:ReturnTransitAndCommit>1</v10:ReturnTransitAndCommit>
<v10:CarrierCodes>FDXE</v10:CarrierCodes>
<v10:RequestedShipment>
<v10:ShipTimestamp>$args->{'timestamp'}</v10:ShipTimestamp>
<v10:DropoffType>$args->{'dropoff_type'}</v10:DropoffType>
<v10:PackagingType>YOUR_PACKAGING</v10:PackagingType>
<v10:Shipper>
<v10:AccountNumber>$self->{'account'}</v10:AccountNumber>
<v10:Tins>
<v10:TinType>PERSONAL_STATE</v10:TinType>
<v10:Number>1057</v10:Number>
<v10:Usage>ShipperTinsUsage</v10:Usage>
</v10:Tins>
<v10:Contact>
<v10:ContactId>SY32030</v10:ContactId>
<v10:PersonName>Sunil Yadav</v10:PersonName>
<v10:CompanyName>Syntel Inc</v10:CompanyName>
<v10:PhoneNumber>9545871684</v10:PhoneNumber>
<v10:PhoneExtension>020</v10:PhoneExtension>
<v10:EMailAddress>sunil_yadav3\@syntelinc.com</v10:EMailAddress>
</v10:Contact>
<v10:Address>
<v10:StreetLines>SHIPPER ADDRESS LINE 1</v10:StreetLines>
<v10:StreetLines>SHIPPER ADDRESS LINE 2</v10:StreetLines>
<v10:City>COLORADO SPRINGS</v10:City>
<v10:StateOrProvinceCode>CO</v10:StateOrProvinceCode>
<v10:PostalCode>$args->{'src_zip'}</v10:PostalCode>
<v10:UrbanizationCode>CO</v10:UrbanizationCode>
<v10:CountryCode>$args->{'src_country'}</v10:CountryCode>
<v10:Residential>0</v10:Residential>
</v10:Address>
</v10:Shipper>
<v10:Recipient>
<v10:Contact>
<v10:PersonName>Receipient</v10:PersonName>
<v10:CompanyName>Receiver Org</v10:CompanyName>
<v10:PhoneNumber>9982145555</v10:PhoneNumber>
<v10:PhoneExtension>011</v10:PhoneExtension>
<v10:EMailAddress>receiver\@yahoo.com</v10:EMailAddress>
</v10:Contact>
<v10:Address>
<v10:StreetLines>RECIPIENT ADDRESS LINE 1</v10:StreetLines>
<v10:StreetLines>RECIPIENT ADDRESS LINE 2</v10:StreetLines>
<v10:City>DENVER</v10:City>
<v10:StateOrProvinceCode>CO</v10:StateOrProvinceCode>
<v10:PostalCode>$args->{'dst_zip'}</v10:PostalCode>
<v10:UrbanizationCode>CO</v10:UrbanizationCode>
<v10:CountryCode>$args->{'dst_country'}</v10:CountryCode>
<v10:Residential>0</v10:Residential>
</v10:Address>
</v10:Recipient>
<v10:RecipientLocationNumber>DEN001</v10:RecipientLocationNumber>
<v10:Origin>
<v10:Contact>
<v10:ContactId>SY32030</v10:ContactId>
<v10:PersonName>Sunil Yadav</v10:PersonName>
<v10:CompanyName>Syntel Inc</v10:CompanyName>
<v10:PhoneNumber>9545871684</v10:PhoneNumber>
<v10:PhoneExtension>020</v10:PhoneExtension>
<v10:EMailAddress>sunil_yadav3\@syntelinc.com</v10:EMailAddress>
</v10:Contact>
<v10:Address>
<v10:StreetLines>SHIPPER ADDRESS LINE 1</v10:StreetLines>
<v10:StreetLines>SHIPPER ADDRESS LINE 2</v10:StreetLines>
<v10:City>COLORADO SPRINGS</v10:City>
<v10:StateOrProvinceCode>CO</v10:StateOrProvinceCode>
<v10:PostalCode>80915</v10:PostalCode>
<v10:UrbanizationCode>CO</v10:UrbanizationCode>
<v10:CountryCode>US</v10:CountryCode>
<v10:Residential>0</v10:Residential>
</v10:Address>
</v10:Origin>
<v10:ShippingChargesPayment>
<v10:PaymentType>SENDER</v10:PaymentType>
<v10:Payor>
<v10:AccountNumber></v10:AccountNumber>
<v10:CountryCode>US</v10:CountryCode>
</v10:Payor>
</v10:ShippingChargesPayment>
<v10:RateRequestTypes>ACCOUNT</v10:RateRequestTypes>
<v10:PackageCount>1</v10:PackageCount>
<v10:RequestedPackageLineItems>
<v10:SequenceNumber>1</v10:SequenceNumber>
<v10:GroupNumber>1</v10:GroupNumber>
<v10:GroupPackageCount>1</v10:GroupPackageCount>
<v10:Weight>
<v10:Units>$args->{'weight_units'}</v10:Units>
<v10:Value>$args->{'weight'}</v10:Value>
</v10:Weight>
<v10:Dimensions>
<v10:Length>$args->{'length'}</v10:Length>
<v10:Width>$args->{'width'}</v10:Width>
<v10:Height>$args->{'height'}</v10:Height>
<v10:Units>$args->{'size_units'}</v10:Units>
</v10:Dimensions>
<v10:PhysicalPackaging>BAG</v10:PhysicalPackaging>
<v10:ContentRecords>
<v10:PartNumber>PRTNMBR007</v10:PartNumber>
<v10:ItemNumber>ITMNMBR007</v10:ItemNumber>
<v10:ReceivedQuantity>10</v10:ReceivedQuantity>
<v10:Description>ContentDescription</v10:Description>
</v10:ContentRecords>
</v10:RequestedPackageLineItems>
</v10:RequestedShipment>
</v10:RateRequest>    
);

  #$rqst =~ s/\n//g;
  return $rqst;
}

# - - - - - - - - - - - - - - -
sub gen_xml_v9
{
   my $self = shift; 
	my $args = shift;

	my $rqst = <<END;
<?xml version="1.0" encoding="utf-8"?>
<RateRequest xmlns="http://fedex.com/ws/rate/v9">
  <WebAuthenticationDetail>
    <UserCredential>
      <Key>$self->{'key'}</Key>
      <Password>$self->{'password'}</Password> 	
    </UserCredential>
  </WebAuthenticationDetail>
  <ClientDetail>
    <AccountNumber>$self->{'account'}</AccountNumber>
    <MeterNumber>$self->{'meter'}</MeterNumber>
  </ClientDetail>
  <TransactionDetail>
    <CustomerTransactionId>Perlworks</CustomerTransactionId>
  </TransactionDetail>
  <Version>
    <ServiceId>crs</ServiceId>
    <Major>9</Major>
    <Intermediate>0</Intermediate>
    <Minor>0</Minor>
  </Version>
  <RequestedShipment>
    <ShipTimestamp>$args->{'timestamp'}</ShipTimestamp>
    <DropoffType>$args->{'dropoff_type'}</DropoffType>
    <PackagingType>YOUR_PACKAGING</PackagingType>
    <TotalInsuredValue>
        <Currency>USD</Currency>
        <Amount>$args->{'insured_value'}</Amount>
    </TotalInsuredValue>
    <Shipper>
      <AccountNumber>$self->{'account'}</AccountNumber>
      <Address>
        <PostalCode>$args->{'src_zip'}</PostalCode>
        <CountryCode>$args->{'src_country'}</CountryCode>
      </Address>
    </Shipper>
    <Recipient>
      <Address>
        <PostalCode>$args->{'dst_zip'}</PostalCode>
        <CountryCode>$args->{'dst_country'}</CountryCode>
        <Residential>$args->{'dst_residential'}</Residential>
      </Address>
    </Recipient>
    <ShippingChargesPayment>
      <PaymentType>SENDER</PaymentType>
      <Payor>
        <AccountNumber>$self->{'account'}</AccountNumber>
        <CountryCode>USD</CountryCode>
      </Payor>
    </ShippingChargesPayment>
    <RateRequestTypes>ACCOUNT</RateRequestTypes>
    <PackageCount>1</PackageCount>
    <PackageDetail>INDIVIDUAL_PACKAGES</PackageDetail>
    <RequestedPackageLineItems>
      <SequenceNumber>1</SequenceNumber>
      <Weight>
        <Units>$args->{'weight_units'}</Units>
        <Value>$args->{'weight'}</Value>
      </Weight>
      <Dimensions>
        <Length>$args->{'length'}</Length>
        <Width>$args->{'width'}</Width>
        <Height>$args->{'height'}</Height>
        <Units>$args->{'size_units'}</Units>
      </Dimensions>
    </RequestedPackageLineItems>
  </RequestedShipment>
</RateRequest>
END

  #$rqst =~ s/\n//g;
  return $rqst;
}

sub err_msg
{
  my $self = shift @_; 
  return $self->{err_msg}; 
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::FedEx::RateRequest - Perl extension for getting available rates from Fedex using their Web Services API. 

=head1 SYNOPSIS

	use Business::FedEx::RateRequest;

	use Data::Dumper;

	# Get your account/meter/key/password numbers from Fedex 
	my %rate_args; 
	$rate_args{'account'}  = '_your_account_number_'; 
	$rate_args{'meter'}    = '_your_meter_number_';  
	$rate_args{'key'}      = '_your_key_';
	$rate_args{'password'} = '_your_password_';

	$rate_args{'uri'}      = 'https://gatewaybeta.fedex.com:443/xml/rate';

	my $Rate = new Business::FedEx::RateRequest(%rate_args);

	my %ship_args;
	$ship_args{'src_zip'} = '83835'; 
	$ship_args{'dst_zip'} = '55411'; 
	$ship_args{'weight'} = 5; 
    
    # Optional args
	$ship_args{'dst_residential'} = 'true'; # defualt is commercial 
	$ship_args{'insured_value'} = 50; 
    
	my $rtn = $Rate->get_rates(%ship_args);

	if ( $rtn )	{ print Dumper $rtn }
	else        { print $Rate->err_msg() }  

Should return something like

	$VAR1 = [
          {
            'ship_cost' => '112.93',
            'ServiceType' => 'FIRST_OVERNIGHT'
          },
          {
            'ship_cost' => '48.91',
            'ServiceType' => 'PRIORITY_OVERNIGHT'
          },
          {
            'ship_cost' => '75.04',
            'ServiceType' => 'STANDARD_OVERNIGHT'
          },
          {
            'ship_cost' => '42.84',
            'ServiceType' => 'FEDEX_2_DAY'
          },
          {
            'ship_cost' => '28.81',
            'ServiceType' => 'FEDEX_EXPRESS_SAVER'
          },
          {
            'ship_cost' => '7.74',
            'ServiceType' => 'FEDEX_GROUND'
          }
        ];


=head1 DESCRIPTION

This object uses a simple XML/POST instead of the slower and more complex Soap based method to obtain 
available rates between two zip codes for a given package weight and size.  At the time of this writing 
FedEx evidently encourages the use of Soap to get available rates and provides source code examples for 
Java, PHP, C# but no Perl. FedEx doesn't provide non-Soap XML examples that I could find. Took me a 
while to develop the XML request but it returns results faster than the PHP Soap method.

The XML returned is voluminous, over 30k bytes to return a few rates, but is smaller 
than the comparable Soap results.

The URI's are not published anywhere I could find but I was successful in using  

Test:		https://gatewaybeta.fedex.com:443/xml/rate 
Production:	https://gateway.fedex.com:443/xml

Early Beta modules and notes may be available at:  

http://perlworks.com/cpan

If you use this module and have comments or suggestions please let me know.  

=head1 METHODS

=over 4

=item $obj->new(%hash)

The new method is the constructor.  

The input hash must include the following:

   uri 		=> FedEx URI (test or production)      	  
   account 	=> FedEx Account    
   meter 	=> FedEx Meter Number     	  
   key 		=> FedEx Key        
   password => FedEx Password   

=item $obj->get_rates(%hash)

The input must include the following 

  	src_zip => Source Zip Code 
	dst_zip => Source Zip Code
	weight  => Package weight in lbs

However the following are optionally and can be overrided. The defaults are as noted
  
   unless ( $args{'src_country'}    ){ $args{'src_country'} = 'US' }  
   unless ( $args{'dst_country'}    ){ $args{'dst_country'} = 'US' } 
   unless ( $args{'dst_residential'}){ $args{'dst_residential'} = 'false' } 
   unless ( $args{'weight_units'}   ){ $args{'weight_units'} = 'LB'} 
   unless ( $args{'size_units'}     ){ $args{'size_units'} = 'IN' } 
   unless ( $args{'length'}         ){ $args{'length'} = '5' } 
   unless ( $args{'width'}          ){ $args{'width'}  = '5' } 
   unless ( $args{'height'}         ){ $args{'height'} = '5' } 
   unless ( $args{'dropoff_type'}   ){ $args{'dropoff_type'} = ' PICKUP' }
   unless ( $args{'insured_value'}  ){ $args{'insured_value'} = '0' }
   
Valid weight_units values are LB, KG.
Valid size_units are IN, CM.
Valid dropoff_types are REGULAR_PICKUP, BUSINESS_SERVICE_CENTER, DROP_BOX, REQUEST_COURIER, STATION.

=item $obj->err_msg()

=back

Returns last posted error message. Usually checked after a 
false return from one of the methods above. 

=head1 EXPORT

None by default.

=head1 SEE ALSO

Business::FedEx::DirectConnect may work but I could not find the URI to use with this 
method and I found out that the Ship Manager API is depreciated and will be turned 
off in 2012 

=head1 DEPENDENCIES 

LWP::UserAgent, XML::Simple;

=head1 AUTHOR

Steve Troxel, E<lt>troxel @ REMOVEMEperlworks.com E<gt>
with contributions and bug fixes from Kyle Albritton. 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steven Troxel 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
