# ============================================================================
package Business::UPS::Tracking::Response;
# ============================================================================
use utf8;
use 5.0100;

use Moose;

no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Business::UPS::Tracking::Utils;
use Business::UPS::Tracking::Shipment::Freight;
use Business::UPS::Tracking::Shipment::SmallPackage;

use XML::LibXML;
use DateTime;

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Response - A response from the UPS webservice 

=head1 SYNOPSIS

  my $response = $request->run();
  my $shipment = $response->shipment->[0];
  say $shipment->ScheduledDelivery;
  
=head1 DESCRIPTION

This class represents a UPS tracking response. This class glues a 
L<Business::UPS::Tracking::Request> object and a 
L<Business::UPS::Tracking::Shipment> object togheter. All methods and 
accessors available in L<Business::UPS::Tracking::Shipment> can also be
accessed via this class.

=head1 ACCESSORS

=head2 request

The request that lead to this response. 
L<Business::UPS::Tracking::Request> object.

=head2 xml

Parsed xml document. L<XML::LibXML::Document> object

=head2 shipment

Array reference of shipments in the response (
L<Business::UPS::Tracking::Shipment::SmallPackage> or 
L<Business::UPS::Tracking::Shipment::Freight> objects)

=head2 CustomerContext

Customer context as supplied in the request

=cut

has 'request' => (
    is       => 'ro',
    required => 1,
    isa      => 'Business::UPS::Tracking::Request',
);
has 'xml' => (
    is       => 'ro',
    required => 1,
    coerce   => 1,
    isa      => 'Business::UPS::Tracking::Type::XMLDocument',
);
has 'shipment' => (
    is       => 'rw',
    isa      => 'ArrayRef[Business::UPS::Tracking::Shipment]',
    #lazy     => 1,
    #builder  => '_build_shipment',
    #handles  => \&_handle_shipment,
);
has 'CustomerContext' => (
    is       => 'ro',
    isa      => 'Str',
    lazy_build   => 1,
);

sub BUILD {
    my ($self) = @_;

    my $xml = $self->xml;
    my $response_status
        = $xml->findvalue('/TrackResponse/Response/ResponseStatusCode');

    # LOGGER            
#    use Path::Class;
#    my $filename = $self->request->TrackingNumber || $self->request->ReferenceNumber;
#    my $file = Path::Class::File->new('t','xmlresponse',$filename); # Same thing
#    unless (-e $file->stringify) {
#        $xml->toFile($file->stringify,1);
#    }
    # LOGGER

    Business::UPS::Tracking::X::XML->throw(
        error   => '/TrackResponse/ResponseStatusCode missing',
        xml     => $xml->find('/TrackResponse/Response')->get_node(1)->toString,
    ) unless defined $response_status;

    # Check for error
    if ($response_status == 0) {
        Business::UPS::Tracking::X::UPS->throw(
            severity    => $xml->findvalue('/TrackResponse/Response/Error/ErrorSeverity'),
            code        => $xml->findvalue('/TrackResponse/Response/Error/ErrorCode'),
            message     => $xml->findvalue('/TrackResponse/Response/Error/ErrorDescription'),
            request     => $self->request,
            context     => $xml->findnodes('/TrackResponse/Response/Error')->get_node(1),
        );
    }
    
    my $shipment_return = [];
    my @shipments = $xml->findnodes('/TrackResponse/Shipment');
    
    foreach my $shipment_xml (@shipments) {
        my $shipment_type = $xml->findvalue('ShipmentType/Code');
        my $shipment_class;
        
        $shipment_type ||= '01';
        
        given ($shipment_type) {
            when ('01') {
                $shipment_class = 'Business::UPS::Tracking::Shipment::SmallPackage';
            }
            when ('02') {
                $shipment_class = 'Business::UPS::Tracking::Shipment::Freight';
            }
            default {
                Business::UPS::Tracking::X::XML->throw(
                    error   => "Unknown shipment type: $shipment_type",
                    xml     => $shipment_type,
                );
            }
        }
        
        push @$shipment_return, $shipment_class->new(
            xml => $shipment_xml,
        );
    }

    $self->shipment($shipment_return);
    
    return;
}

sub _build_CustomerContext {
    my ($self) = @_;
    
    return $self->xml->findvalue('/TrackResponse/Response/TransactionReference/CustomerContext')
}

#sub _handle_shipment {
#    my ($meta,$metaclass) = @_;
#
#    my @classes = ($metaclass->subclasses,$metaclass); 
#    
#    my @name;
#    foreach my $class (@classes) {
#        push @name, map { $_ } $class->meta->get_method_list;
#        push @name, map { $_ } $class->meta->get_attribute_list;
#    }
#    
#    my %return = map { $_ => $_ } grep { $_ !~ m/_.+/ && m/[A-Z]/ } @name;
#    delete $return{DESTROY};
#    delete $return{BUILD};
#    delete $return{xml};
#
#    return %return;
#}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
