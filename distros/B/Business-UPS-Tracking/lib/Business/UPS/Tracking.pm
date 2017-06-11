# ============================================================================
package Business::UPS::Tracking;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
with qw(Business::UPS::Tracking::Role::Base);

no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Business::UPS::Tracking::Exception;
use LWP::UserAgent;
use Business::UPS::Tracking::Utils;
use Business::UPS::Tracking::Request;

our $VERSION = "1.13";
our $AUTHORITY = 'cpan:MAROS';
our $CHECKSUM = $ENV{TRACKING_CHECKSUM} // 1 ;

=encoding utf8

=head1 NAME

Business::UPS::Tracking - Interface to the UPS tracking webservice

=head1 SYNOPSIS

  use Business::UPS::Tracking;
  
  my $tracking = Business::UPS::Tracking->new(
    AccessLicenseNumber => '1CFFED5A5E91B17',
    UserId              => 'myupsuser',
    Password            => 'secret',
  );
  
  eval {
    my $response = $tracking->request(
      TrackingNumber  => '1Z12345E1392654435',
    )->run();
    
    foreach my $shipment ($response->shipment) {
        say 'Service code is '.$shipment->ServiceCode;
        foreach my $package ($shipment->Package) {
            say 'Status is '.$package->CurrentStatus;
        }
    }
  };
  
  if (my $e = Exception::Class->caught) {
    given ($e) {
      when ($_->isa('Business::UPS::Tracking::X::HTTP')) {
        say 'HTTP ERROR:'.$e->full_message;
      }
      when ($_->isa('Business::UPS::Tracking::X::UPS')) {
        say 'UPS ERROR:'.$e->full_message.' ('.$e->code.')';
      }
      default {
        say 'SOME ERROR:'.$e;
      }
    }
  }

=head1 DESCRIPTION

=head2 Class structure

                   .-----------------------------------.
                   |     Business::UPS::Tracking       |
                   '-----------------------------------'
                                   ^
                                HAS ONE
                                   |
                   .-----------------------------------.
                   |         B::U::T::Request          |
                   '-----------------------------------'
                                   ^
                                HAS ONE
                                   |
                   .-----------------------------------.
                   |         B::U::T::Response         |
                   '-----------------------------------'
                                   |
                                HAS MANY
                                   v
                   .-----------------------------------.
                   |         B::U::T::Shipment         |
                   '-----------------------------------'
                       ^                           ^
                      ISA                         ISA
                       |                           |
 .---------------------------------. .-----------------------------------.
 |    B::U::T::Shipment::Freight   | |  B::U::T::Shipment::Smallpackage  |
 |---------------------------------| |-----------------------------------|
 | Freight shipment type           | | Small package shipment type       |
 | Not yet implemented             | '-----------------------------------'
 '---------------------------------'               |
                                                HAS MANY
                                                   v
                                     .-----------------------------------.
                                     |     B::U::T::Element::Package     |
                                     '-----------------------------------'
                                                   |
                                                HAS MANY
                                                   v
                                     .-----------------------------------.
                                     |    B::U::T::Element::Activity     |
                                     '-----------------------------------'

=head2 Exception Handling

If anythis goes wrong Business::UPS::Tracking throws an exception. Exceptions
are always L<Exception::Class> objects which contain structured information
about the error. Please refer to the synopsis or to the L<Exception::Class>
documentation for documentation how to catch and rethrow exeptions.

The following exception classes are defined:

=head3 Business::UPS::Tracking::X

Basic exception class. All other exception classes inherit from this class.

=head3 Business::UPS::Tracking::X::HTTP

HTTP error. The object provides additional parameters:

=over

=item * http_response : L<HTTP::Response> object

=item * request : L<Business::UPS::Tracking::Request> object

=back

=head3 Business::UPS::Tracking::X::UPS

UPS error message.The object provides additional parameters:

=over

=item * code : UPS error code

=item * severity : Error severity 'hard' or 'soft'

=item * context : L<XML::LibXML::Node> object containing the whole error response.

=item * request : L<Business::UPS::Tracking::Request> object

=back

=head3 Business::UPS::Tracking::X::XML

XML parser or schema error.

=head2 Accessor / method naming

The naming of the methods and accessors tries to stick close to the names
used by the UPS webservice. All accessors containg uppercase letters access
xml data. Lowercase-only accessors and methods are used for utility
functions.

=head2 UPS license

In order to use this module you need to obtain a "Tracking WebService"
license key. See L<http://www.ups.com/e_comm_access/gettools_index> for more
information.

=head1 METHODS

=head2 new

 my $tracking = Business::UPS::Tracking->new(%params);

Create a C<Business::UPS::Tracking> object. See L<ACCESSORS> for available
parameters.

=head2 access_request

UPS access request.

=head2 request

 my $request = $tracking->request(%request_params);

Returns a L<Business::UPS::Tracking::Request> object.

=head2 request_run

 my $response = $tracking->request_run(%request_params);

Generates a L<Business::UPS::Tracking::Request> object and imideately
executes it, returning a L<Business::UPS::Tracking::Response> object.

=head1 ACCESSORS

=head2 AccessLicenseNumber

UPS tracking service access license number

=head2 UserId

UPS account username

=head2 Password

UPS account password

=head2 config

Optionally you can retrieve all or some UPS webservice credentials from a
configuration file. This accessor holds the path to this file.
Defaults to C<~/.ups_tracking>

Example configuration file:

 <?xml version="1.0"?>
 <UPS_tracking_webservice_config>
    <AccessLicenseNumber>1CFFED5A5E91B17</AccessLicenseNumber>
    <UserId>myupsuser</UserId>
    <Password>secret</Password>
 </UPS_tracking_webservice_config>

=head2 retry_http

Number of retries if http errors occur

Defaults to 0

=head2 url

UPS Tracking webservice url.

Defaults to https://wwwcie.ups.com/ups.app/xml/Track

=head2 _ua

L<LWP::UserAgent> object.

Automatically generated

=cut

has 'retry_http' => (
    is          => 'rw',
    isa         => 'Int',
    default     => 0,
    documentation   => 'Number of retries if HTTP errors occur [Default 0]',
);
has 'url' => (
    is          => 'rw',
    default     => sub { 'https://wwwcie.ups.com/ups.app/xml/Track' },
    documentation   => 'UPS webservice url',
);
has '_ua' => (
    is          => 'rw',
    lazy        => 1,
    isa         => 'LWP::UserAgent',
    builder     => '_build_ua',
);


sub _build_ua {
    my ($self) = @_;

    my $ua = LWP::UserAgent->new(
        agent       => __PACKAGE__ . " ". $VERSION,
        timeout     => 50,
        env_proxy   => 1,
    );

    return $ua;
}

sub access_request {
    my ($self) = @_;

    my $license = Business::UPS::Tracking::Utils::escape_xml($self->AccessLicenseNumber);
    my $username = Business::UPS::Tracking::Utils::escape_xml($self->UserId);
    my $password = Business::UPS::Tracking::Utils::escape_xml($self->Password);

    return <<ACR
<?xml version="1.0"?>
<AccessRequest xml:lang='en-US'>
    <AccessLicenseNumber>$license</AccessLicenseNumber>
    <UserId>$username</UserId>
    <Password>$password</Password>
</AccessRequest>
ACR
}

sub request {
    my ( $self, %params ) = @_;
    return Business::UPS::Tracking::Request->new(
        %params,
        tracking => $self,
    );
}

sub request_run {
    my ( $self, %params ) = @_;
    return $self->request(%params)->run();
}

__PACKAGE__->meta->make_immutable;
no Moose;

=head1 SUPPORT

Please report any bugs or feature requests to
C<bug-buisness-ups-tracking@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Business::UPS::Tracking>.
I will be notified, and then you'll automatically be notified of progress on
your report as I make changes.

=head1 SEE ALSO

Download the UPS "OnLine® Tools Tracking Developer Guide" and get a
developer key at L<http://www.ups.com/e_comm_access/gettools_index?loc=en_US>.
Please check the "Developer Guide" for more detailed documentation on the
various fields.

The L<WebService::UPS::TrackRequest> provides an alternative simpler
implementation.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    http://www.k-1.com

=head1 COPYRIGHT

Business::UPS::Tracking is Copyright (c) 2012 Maroš Kollár
- L<http://www.k-1.com>

=head1 LICENCE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'Where is my "30 HP NorTrac Bulldozer" I ordered at Amazon recently? (http://www.amazon.com/30-HP-NorTrac-Bulldozer-Backhoe/dp/B000EIWSN0)';
