package CyberSource;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

bootstrap CyberSource $VERSION;

1;
__END__

=head1 NAME

CyberSource - Perl extension for ICS2 E-Commerce API library

=head1 SYNOPSIS

  use CyberSource;
 
  %arg =  (
        "merchant_id"           => "YourMerchanID",
        "ics_applications"      => "ics_score,ics_auth,ics_bill",
        "customer_firstname"    => "John",
        "customer_lastname"     => "Doe",
        "customer_email"        => "nobody\@cybersource.com",
        "customer_phone"        => "408-556-9100",
        "bill_address1"         => "1295 Charleston Rd.",
        "bill_city"             => "Mountain View",
        "bill_state"            => "CA",
        "bill_zip"              => "94043-1307",
        "bill_country"          => "US",
        "customer_cc_number"    => "4111111111111111",
        "customer_cc_expmo"     => "12",
        "customer_cc_expyr"     => "2004",
        "merchant_ref_number"   => "12",
        "currency"              => "USD",
        "offer0"                => "offerid:0^amount:4.59",
        );

  %values = CyberSource::ics_send( \%arg );
 

=head1 DESCRIPTION

CyberSource is one of the leading E-Commerce service providers.
This library implements a generic routine to send requests
to the CyberSource and obtain results using ICS2 API library.

=head2 EXPORT

ics_send	routine to send the request and return results using hash.

=head1 AUTHOR

Pavel Smirnov <huge@ax.ru>

=head1 SEE ALSO

www.cybersource.com	CyberSource E-Commerce services.

=cut
