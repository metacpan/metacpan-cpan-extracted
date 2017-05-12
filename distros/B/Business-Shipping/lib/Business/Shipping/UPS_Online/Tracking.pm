package Business::Shipping::UPS_Online::Tracking;

=head1 NAME

Business::Shipping::UPS_Online::Tracking

=head2 EXAMPLE 

my $results = $tracker->results();

# The results hash will contain this type of information

{
  # Date the package was picked up
  pickup_date => '...',


  # Scheduled delivery date (YYYYMMDD)
  scheduled_delivery_date => '...',

  # Scheduled delivery time (HHMMSS)
  scheduled_delivery_time => '...',

  # Rescheduled delivery date (YYYYMMDD)
  rescheduled_delivery_date => '...',

  # Rescheduled delivery time (HHMMSS)
  rescheduled_delivery_time => '...',


  # Shipment method code and description for package
  service_code => '...',
  service_description => '...',

  
  # Summary will contain the latest activity entry, a copy of activity->[0]
  summary => { },
  # Activity of the package in transit, newest entries first.
  activity => [
  {
    # Address information of the activity 
    address => {
       city => '...',
       state => '...',
       zip => '...',
       country => '...',
       description => '...',
       code => '...',
       signedforbyname => '...',
    },

    # Code of activity
    status_code => '...',
    status_description => '...',
    
    # Date of activity (YYYYMMDD)
    date => '...',
    # Time of activity (HHMMSS)
    time => '...',
  }
 
  ],
}

=cut

use Any::Moose;
use Business::Shipping::Logging;
use XML::Simple 2.05;
use XML::DOM;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::Tracking';

has 'access_key' => (is => 'rw');

has 'prod_url' => (
    is      => 'rw',
    default => 'https://www.ups.com/ups.app/xml/Track',
);

has 'test_url' => (
    is      => 'rw',
    default => 'https://wwwcie.ups.com/ups.app/xml/Track',
);

__PACKAGE__->meta()->make_immutable();

sub Required {
    return ($_[0]->SUPER::Required, qw/ user_id password access_key /);
}

sub Optional {
    return ($_[0]->SUPER::Optional, qw/ prod_url test_url /);
}

# UPS only allows tracking one package at a time, so each package
# needs its own XML document.  Hopefully UPS will get the on same bus
# as USPS and allow multiple packages to be tracked in the same
# request.
sub _gen_single_package_xml {
    trace '()';

    info('Creating XML request.');
    my $self        = shift;
    my $tracking_id = shift;

    if ($self->results_exists($tracking_id)) {

        # The result for this package was already found in the cache.
        return;
    }

    if (!grep { !$self->results_exists($_) } @{ $self->tracking_ids }) {

        # All results were found in the cache
        return;
    }

    my $trackReqDoc = XML::DOM::Document->new();

    my $access_tree = {
        'AccessRequest' => [
            {   'xml:lang'            => 'en-US',
                'AccessLicenseNumber' => [$self->access_key()],
                'UserId'              => [$self->user_id()],
                'Password'            => [$self->password()],
            }
        ]
    };

    my $request_tree = {
        'TrackRequest' => [
            {   Request => [
                    {   TransactionReference => [
                            {   CustomerContext => ["Tracking Request"],
                                XpciVersion     => [1.0001],
                            },
                        ],
                        RequestAction => ["Track"],
                        RequestOption => ["activity"],
                    },
                ],
                TrackingNumber => [$tracking_id],
            }
        ]
    };

    my $access_xml = '<?xml version="1.0"?>' . "\n"
        . XML::Simple::XMLout($access_tree, KeepRoot => 1);

    my $request_xml
        = $access_xml
        . '<?xml version="1.0"?>' . "\n"
        . XML::Simple::XMLout($request_tree, KeepRoot => 1);

# We only do this to provide a pretty, formatted XML doc for the debug.
# Commented out lines below, because XML::Parser complains
#my $request_xml_tree = XML::Simple::XMLin( $request_xml, KeepRoot => 1, ForceArray => 1 );

    trace(XML::Simple::XMLout($request_tree, KeepRoot => 1))
        if is_trace();

    return ($request_xml);
}

# _gen_request_xml()
# Generate a list of XML documents that need to be processed.
sub _gen_request_xml {
    trace '()';
    my $self = shift;
    my @xml_documents = grep { defined($_) }
        map { $self->_gen_single_package_xml($_) } @{ $self->tracking_ids };
    return \@xml_documents;
}

sub _gen_url {
    trace '()';
    my ($self) = shift;

    return ($self->test_mode() ? $self->test_url() : $self->prod_url());
}

sub _gen_request {
    my ($self) = shift;
    trace('called');

    my $request_xml = $self->_gen_request_xml();

    if (!defined($request_xml) || scalar(@$request_xml) == 0) {
        return;
    }

    # Return an array of http request objects with the
    my @http_request_objects;
    for my $xml_request (@$request_xml) {
        my $request = HTTP::Request->new('POST', $self->_gen_url());
        $request->header(
            'content-type' => 'application/x-www-form-urlencoded');
        $request->header('content-length' => length($xml_request));
        $request->content($xml_request);

        # Large debug
        trace('HTTP Request: ' . $request->as_string()) if is_trace();
        push @http_request_objects, $request;
    }
    debug('Done creating HTTP::Request objects.');

    return @http_request_objects;
}

sub _handle_response {
    trace '()';
    my $self = shift;

    my $response_tree = XML::Simple::XMLin(
        $self->response()->content(),
        ForceArray => 0,
        KeepRoot   => 0,
    );

    my $status_code = $response_tree->{Response}->{ResponseStatusCode};
    my $status_description
        = $response_tree->{Response}->{ResponseStatusDescription};
    my $error = $response_tree->{Response}->{Error}->{ErrorDescription};
    my $err_location = $response_tree->{Response}->{Error}->{ErrorLocation}
        ->{ErrorLocationElementName} || '';
    if ($error and $error !~ /Success/) {
        my $combined_error_msg
            = "$status_description ($status_code): $error @ $err_location";
        $combined_error_msg =~ s/\s{3,}/ /g;
        $self->user_error($combined_error_msg);
        return (undef);
    }

    # This is a large debug.
    trace('response = ' . $self->response->content);

    my $shipment_id
        = $response_tree->{Shipment}->{ShipmentIdentificationNumber};
    my $result_hash;

    $result_hash->{pickup_date} = $response_tree->{Shipment}->{PickupDate};
    $result_hash->{scheduled_delivery_date}
        = $response_tree->{Shipment}->{ScheduledDeliveryDate};
    $result_hash->{scheduled_delivery_time}
        = $response_tree->{Shipment}->{ScheduledDeliveryTime};

    $result_hash->{rescheduled_delivery_date}
        = $response_tree->{Shipment}->{RescheduledDeliveryDate};
    $result_hash->{rescheduled_delivery_time}
        = $response_tree->{Shipment}->{RescheduledDeliveryTime};

    my $shipper = $response_tree->{Shipment}->{Shipper};
    if ($shipper) {
        $result_hash->{shipper} = {
            shipper_number => $shipper->{ShipperNumber},
            address1       => $shipper->{Address}->{AddressLine1},
            address2       => $shipper->{Address}->{AddressLine2},
            city           => $shipper->{Address}->{City},
            state          => $shipper->{Address}->{StateProvinceCode},
            zip            => $shipper->{Address}->{PostalCode},
            country        => $shipper->{Address}->{CountryCode},
        };
    }

    my $ship_to = $response_tree->{Shipment}->{ShipTo};

    if ($shipper) {
        $result_hash->{ship_to} = {
            address1 => $ship_to->{Address}->{AddressLine1},
            address2 => $ship_to->{Address}->{AddressLine2},
            city     => $ship_to->{Address}->{City},
            state    => $ship_to->{Address}->{StateProvinceCode},
            zip      => $ship_to->{Address}->{PostalCode},
            country  => $ship_to->{Address}->{CountryCode},
        };
    }

    $result_hash->{service_code}
        = $response_tree->{Shipment}->{Service}->{Code};
    $result_hash->{service_description}
        = $response_tree->{Shipment}->{Service}->{Description};

    $result_hash->{activity} = [];

    my $package = $response_tree->{Shipment}->{Package};
    my $activities
        = (ref $package->{Activity} eq 'ARRAY')
        ? $package->{Activity}
        : [$package->{Activity}];

    foreach my $activity (@$activities) {
        my $activity_info = {
            address => {
                city  => $activity->{ActivityLocation}->{Address}->{City},
                state => $activity->{ActivityLocation}->{Address}
                    ->{StateProvinceCode},
                zip => $activity->{ActivityLocation}->{Address}->{PostalCode},
                country =>
                    $activity->{ActivityLocation}->{Address}->{CountryCode},
                description =>
                    $activity->{ActivityLocation}->{Address}->{Description},
                signedforbyname => $activity->{ActivityLocation}->{Address}
                    ->{SignedForByName},
                code => $activity->{ActivityLocation}->{Address}->{code},
            },
            status_code => $activity->{Status}->{StatusType}->{Code},
            status_description =>
                $activity->{Status}->{StatusType}->{Description},
            date => $activity->{Date},
            time => $activity->{Time}
        };

        push @{ $result_hash->{activity} }, $activity_info;
    }

    if (defined(scalar(@{ $result_hash->{activity} }) > 0)) {
        $result_hash->{summary} = $result_hash->{activity}->[0];
    }

    Business::Shipping::Tracking::_delete_undefined_keys($result_hash);

    $self->results({ $shipment_id => $result_hash });

    trace 'returning success';
    return $self->is_success(1);
}

sub gen_unique_key {
    my $self = shift;
    my $id   = shift;

    return 'Tracking:UPS:' . uc($id);
}

1;

=head1 AUTHOR

Rusty Conover <rconover@infogears.com>

=head1 COPYRIGHT AND LICENCE

Copyright 2004-2007 Infogears Inc. Portions Copyright 2003-2011 Daniel 
Browning <db@kavod.com>. All rights reserved. This program is free 
software; you may redistribute it and/or modify it under the same terms as 
Perl itself. See LICENSE for more info.

=cut
