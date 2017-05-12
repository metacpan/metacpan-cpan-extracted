package Business::3DSecure::Cardinal;

use strict;
use warnings;

use Business::3DSecure;
use Carp;
use Error qw( try );
use LWP::UserAgent;
use SOAP::Lite;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

require Exporter;

@ISA = qw( Exporter AutoLoader Business::3DSecure );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.06';

# constants
use constant TIMEOUT => '10';

# Transaction type map
use constant ACTIONS => ( 'cmpi_lookup', 'cmpi_authenticate' );

use constant RECOVERABLE_ERRORS => (
    350, 1001, 1002, 1051, 1055, 1060, 1085, 1120, 1130, 1140,
    1150, 1160, 1355, 1360, 1380, 1390, 1400, 1710, 1752, 1755,
    1789, 2001, 2003, 2006, 2007, 2009, 2010, 4000, 4020, 4240,
    4243, 4245, 4268, 4310, 4375, 4400, 4770, 4780, 4790, 4800,
    4810, 4820, 4930, 4951, 4963, 4965
);

use constant ERRORS => {
    6000 => "General Error Communicating with MAPS Server" ,
    6010 => "Failed to connect() to server via socket connection" ,
    6020 => "Failed Parse of Response XML Message Returned From the MPI Server - Socket Communication" ,
    6030 => "Failed Parse of Response XML Message Returned From the MPI Server - HTTP Communication" ,
    6040 => "Failed Parse of Response XML Message Returned From the MPI Server - HTTPS Communication" ,
    6050 => "Failed to initialize socket connection" ,
    6060 => "Error Communicating with MAPS Server, No Response Message Received - Socket Communication" ,
    6070 => "The URL to the MAPS Server does not use a recognized protocol (https required)" ,
    6080 => "Error Communicating with MAPS Server, Error Response - HTTP Communication" ,
    6090 => "Error Communicating with MAPS Server, Error Response - HTTPS Communication" ,
    6100 => "Unable to Verify Trusted Server" ,
    6110 => "Unable to Establish a SSL Context" ,
    6120 => "Unable to Establish a SSL Connection" ,
    6130 => "Error extract the underlying file descriptor" ,
    6140 => "Error establishing Network Connection" ,
    6150 => "Error during SSL Read of Reponse Data" ,
    6160 => "Unable to Establish a Socket Connection for SSL connectivity" ,
    6170 => "Unable to capture a Socket for SSL connectivity" ,
    9999 => "DOLLAR AMOUNT ERROR: TWO DECIMALS NEEDED",
};

# fields required for different transaction types
use constant REQUIRED_FIELDS => {
cmpi_lookup => [ qw{ MsgType Version ProcessorId MerchantId TransactionPwd TransactionType RawAmount PurchaseAmount PurchaseCurrency PAN PANExpr OrderNumber } ],
cmpi_authenticate => [ qw{ MsgType Version ProcessorId MerchantId TransactionId PAResPayload } ],
};

# optional fields for different transaction types
use constant OPTIONAL_FIELDS => {
cmpi_lookup => [ qw{ OrderDescription UserAgent BrowserHeader Recurring RecurringFrequency RecurringEnd Installment AcquirerPassword EMail IPAddress BillingFirstName BillingMiddleName BillingLastName BillingAddress1 BillingAddress2 BillingCity BillingState BillingPostalCode BillingCountryCode BillingPhone BillingAltPhone ShippingFirstName ShippingMiddleName ShippingLastName ShippingAddress1 ShippingAddress2 ShippingCity ShippingState ShippingPostalCode ShippingCountryCode ShippingPhone ShippingAltPhone Item_Name_X Item_Desc_X Item_Price_X Item_Quantity_X Item_SKU_X} ],
cmpi_authenticate    =>[qw{ NONE }],
};

use constant REMAP => {
  version     => 'Version',
  action      => 'MsgType',
  password    => 'TransactionPwd',
  trans_type  => 'TransactionType',
  vendor      => 'ProcessorId',
  brand       => 'MerchantId',
  amount      => 'PurchaseAmount',
  currency    => 'PurchaseCurrency',
  cc_num      => 'PAN',
  ordernum    => 'OrderNumber',
  auth_result => 'PAResPayload',
  auth_id     => 'TransactionId',
};

sub set_defaults
{
  my $self = shift;
  $self->build_subs( qw( cavv eci enrolled error_desc error_num authorized verified unparsed_response auth_request auth_id issuer_url ) );
}

sub submit
{
  my ( $self ) = @_;

  $self->{ _content }->{ action } = "cmpi_" . lc( $self->{ _content }->{ action } );

  my $action = $self->{ _content }->{ action };

  unless ( grep /$action/, ACTIONS )
  {
    Carp::croak( $self->{ processor } . " can't handle transaction type: " .  $action );
  }

  $self->map_fields();
  $self->remap_fields();
  $self->required_fields( @{ REQUIRED_FIELDS->{ $action } } );

  unless ( $self->{ _content }->{ amount_error } )
  {
    # get data ready to send
    my %post_data = $self->get_fields( @{ REQUIRED_FIELDS->{ $action } }, @{ OPTIONAL_FIELDS->{ $action } } );

    $self->{ _post_data } = \%post_data;

    my $xmlMsg  = "<CardinalMPI>";

    while( my ( $tagname, $tagvalue ) = each %post_data )
    {
      $tagvalue =~ s/&/&amp;/g;
      $tagvalue =~ s/</&lt;/g;
      $xmlMsg .= "<" . $tagname . ">" . $tagvalue . "</" . $tagname . ">";
    }

    $xmlMsg .= "</CardinalMPI>";

    my $ua = LWP::UserAgent->new();
    $ua->timeout( TIMEOUT ) ;
    $ua->cookie_jar( { } );

    my $response = $ua->post( $self->{ _content }->{ transaction_url }, [ 'cmpi_msg' => $xmlMsg ] );

    $self->is_success( 0 );

    # if post to Cardinal was successful
    if ( $response->is_success )
    {
      $self->unparsed_response( $response->content );

      my $som = SOAP::Deserializer->deserialize( $response->content );

      $self->{ _response }->{ $_->name } = $_->value foreach ( $som->dataof( "//CardinalMPI/*" ) );

      #if defined use the errors above otherwise load straigh in from server
      if ( defined ERRORS->{ $self->{ _response }->{ ErrorNo } } )
      {
        $self->error_num( $self->{ _response }->{ ErrorNo } ) ;
        $self->error_desc( ERRORS->{ $self->error_num } ) ;
      }
      else
      {
        $self->error_num( $self->{ _response }->{ ErrorNo } ) ;
        $self->error_desc( "ERROR NOT RECOGNIZED:" . $self->{ _response }->{ ErrorDesc } ) ;
      }

      if ( !$self->{ _response } )
      {
        $self->error_num( 6040 );
        $self->error_desc( ERRORS->{ 6040 } );
      }

      $self->eci( 0 );
      $self->is_success( 1 );

      if ( $action eq 'cmpi_lookup' )
      {
        $self->auth_request( $self->{ _response }->{ Payload } ) ;
        $self->auth_id( $self->{ _response }->{ TransactionId } ) ;
        $self->issuer_url( $self->{ _response }->{ ACSUrl } ) ;

        my $enrolled = uc $self->{ _response }->{ Enrolled } eq 'Y' ? 1 : 0;
        $self->enrolled( $enrolled );

      }
      elsif ( $action eq 'cmpi_authenticate' )
      {
        $self->cavv( $self->{ _response }->{ Cavv } );
        
        # possible success are Y U or A this SHOULD be made farther up, in client code
        my $authorized = uc $self->{ _response }->{  PAResStatus } eq 'N' ? 0 : 1;
        $self->authorized( $authorized );

        my $verified = uc $self->{ _response }->{ SignatureVerification } eq 'Y' ? 1 : 0;
        $self->verified( $verified );

        # EciFlag
        my $eci = $self->{ _response }->{ EciFlag } ne '02' ? 0 : 1;
        $self->eci( $eci );
      }
    }
    else
    {
      # post was unsuccessful
      $self->error_num( 6090 );
      $self->error_desc( ERRORS->{ 6090 } );
    }

  }
  else
  {
    # amount error 
    $self->error_num( 9999 );
    $self->error_desc( ERRORS->{ 9999 } );
  }
}

sub map_fields 
{
  my ( $self ) = @_;
  my %content = $self->content();

  if ( $content{ action } )
  {
    if ( defined $content{ amount } )
    {
      my @amount = split( '\.' , $content{ amount } );

      $content{ amount_error } = $content{ amount } if length $amount[ 1 ] != 2;
      $content{ RawAmount } = $content{ amount };
      $content{ RawAmount } =~ s/\.//;
    }

    if ( defined $content{ cc_expmonth } && defined $content{ cc_expyear } )
    {

      # it will only be 2 or 4
      if ( length( $content{ cc_expyear } ) == 4 )
      {
        $content{ cc_expyear } = substr $content{ cc_expyear }, 2, 4;
      }

      $content{ PANExpr } = $content{ cc_expyear } . $content{ cc_expmonth };
    }
  }

  # stuff it back into %content
  $self->content( %content );
}

sub remap_fields 
{
  my ( $self ) = @_;
  my %content = $self->content();

  foreach( keys  %{ ( REMAP ) } ) 
  {
    $content{ REMAP->{ $_ } } = $content{ $_ } ;
  }

  $self->content( %content );
}

sub get_fields 
{
  my ( $self, @fields ) = @_;

  my %content = $self->content();

  my %new = ();

  $new{ $_ } = $content{ $_ } foreach( grep defined $content{ $_ }, @fields );

  return %new;
}

sub is_recoverable_error
{
  my $self = shift;

  my $error_num = $self->error_num();
  return ( grep /$error_num/, RECOVERABLE_ERRORS ? 1 : 0 );
}

sub error
{
  my $self = shift;
  return $self->error_num() != 0;
} 

1;
__END__

=head1 NAME

Business::3DSecure::Cardinal - Perl extension for 3DSecure authentication using Cardinal 

=head1 SYNOPSIS

my $sc = new Business::3DSecure("Cardinal");

$sc->content();

$sc->submit();

$sc->is_success() 

=head1 DESCRIPTION

Business::3DSecure::Cardinal is a subclass of Business::3DSecure for authorizing Credit Cards through 3DSecure

Please note this is only tested for mastercard/maestro. 

Also note that in order to use this you will need to contact Cardinal Commerce and get a test account to get a transaction url

=head1 METHODS AND FUNCTIONS

=head2 set_defaults

Build subroutiness

=head2 submit

Submits Request 

action is one of lookup or authenticate

=head2 map_fields

Maps fields as necessary
 
=head2 remap_fields 

Remaps human names into the Cardinal specific field names

=head2 get_fields 

Gets all fields needed for submission

=head2 is_recoverable_error

If its a recoverable error, proceed

=head2 error

Detects if its an error


=head1 AUTHOR

Clayton Cottingham, C<< <clayton@wintermarket.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-3dsecure-cardinal at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-3DSecure-Cardinal>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::3DSecure::Cardinal

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-3DSecure-Cardinal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-3DSecure-Cardinal>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-3DSecure-Cardinal>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-3DSecure-Cardinal>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Clayton Cottingham of Winternarket Networks www.wintermarket.net , all rights reserved.
            

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
