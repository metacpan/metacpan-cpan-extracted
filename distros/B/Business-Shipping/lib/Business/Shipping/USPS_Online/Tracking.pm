package Business::Shipping::USPS_Online::Tracking;

=head1 NAME

Business::Shipping::USPS_Online::Tracking - A USPS module for Tracking Packages

See Tracking.pm POD for usage information.

=head2 EXAMPLE

my $results = $tracker->results();

# The results hash will contain this type of information

{
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
       signedforbyname => '...',
    },

    # Description of activity
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
use Date::Parse;
use POSIX;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::Tracking';

has 'prod_url' => (
    is      => 'rw',
    default => 'http://production.shippingapis.com/ShippingAPI.dll'
);

has 'test_url' => (
    is      => 'rw',
    default => 'http://testing.shippingapis.com/ShippingAPItest.dll'
);

# _gen_request_xml()
# Generate the XML document.
sub _gen_request_xml {
    trace '()';
    my $self = shift;

    if (!grep { !$self->results_exists($_) } @{ $self->tracking_ids }) {

        # All results were found in the cache
        return;
    }

    my @results;

    foreach my $id (@{ $self->tracking_ids() }) {

# Note: The XML::Simple hash-tree-based generation method wont work with USPS,
# because they enforce the order of their parameters (unlike UPS).
#
        my $trackReqDoc = XML::DOM::Document->new();

        my $trackReqEl = $trackReqDoc->createElement('TrackFieldRequest');

        $trackReqEl->setAttribute('USERID',   $self->user_id());
        $trackReqEl->setAttribute('PASSWORD', $self->password());
        $trackReqDoc->appendChild($trackReqEl);

# Could already have some responses cached so don't pull them from the server.

        foreach my $tracking_id (grep { !$self->results_exists($_) }
            @{ $self->tracking_ids })
        {
            my $trackIDEl = $trackReqDoc->createElement("TrackID");
            $trackIDEl->setAttribute('ID', $tracking_id);
            $trackReqEl->appendChild($trackIDEl);
        }

        my $request_xml = $trackReqDoc->toString();

       # We only do this to provide a pretty, formatted XML doc for the debug.
        my $request_xml_tree = XML::Simple::XMLin(
            $request_xml,
            KeepRoot   => 1,
            ForceArray => 1
        );

        trace(XML::Simple::XMLout($request_xml_tree, KeepRoot => 1))
            if is_trace();

        #
        push @results, $request_xml;
    }

    return @results;
}

sub _gen_url {
    trace '()';
    my ($self) = shift;

    return ($self->test_mode() ? $self->test_url() : $self->prod_url());
}

sub _gen_request {
    my ($self) = shift;
    trace('called');

    my @reqs;
    foreach my $request_xml ($self->_gen_request_xml()) {
        my $request = HTTP::Request->new('POST', $self->_gen_url());

        $request->header(
            'content-type' => 'application/x-www-form-urlencoded');
        $request->header('content-length' => length($request_xml));

        # This is how USPS slightly varies from Business::Shipping
        my $new_content = 'API=TrackV2' . '&XML=' . $request_xml;
        $request->content($new_content);
        $request->header('content-length' => length($request->content()));

        trace('HTTP Request: ' . $request->as_string()) if is_trace();

        push @reqs, $request;
    }
    return @reqs;
}

sub cleanup_xml_hash {
    my $hash_ref = shift;

    map { $hash_ref->{$_} = undef; } grep {
        ref($hash_ref->{$_}) eq 'HASH'
            && scalar(keys %{ $hash_ref->{$_} })
            == 0
    } keys %$hash_ref;
}

sub _handle_response {
    trace '()';
    my $self = shift;

    my $response_tree = XML::Simple::XMLin(
        $self->response()->content(),
        ForceArray => 0,
        KeepRoot   => 1,
    );

    # TODO: Handle multiple packages errors.
    # (this doesn't seem to handle multiple packagess errors very well)
    if ($response_tree->{Error}) {
        my $error             = $response_tree->{Error};
        my $error_number      = $error->{Number};
        my $error_source      = $error->{Source};
        my $error_description = $error->{Description};
        $self->user_error(
            "$error_source: $error_description ($error_number)");
        return (undef);
    }

    trace('response = ' . $self->response->content) if is_trace();

    $response_tree = $response_tree->{TrackResponse};

    my $results;

    foreach my $trackInfo (
        (     (ref($response_tree->{TrackInfo}) eq 'ARRAY')
            ? (@{ $response_tree->{TrackInfo} })
            : $response_tree->{TrackInfo}
        )
        )
    {
        my $id = $trackInfo->{'ID'};

        if (exists($trackInfo->{'Error'})) {
            $self->results(
                {   $id => {
                        error => 1,
                        error_description =>
                            $trackInfo->{Error}->{Description},
                        error_source => $trackInfo->{Error}->{Source},
                    }
                }
            );
        }
        else {
            cleanup_xml_hash($trackInfo->{TrackSummary});

            my @activity_array;

            if (ref($trackInfo->{TrackDetail}) eq 'ARRAY') {
                @activity_array = @{ $trackInfo->{TrackDetail} };
            }
            else {
                @activity_array = ($trackInfo->{TrackDetail});
            }

            if (exists($trackInfo->{TrackSummary})) {
                unshift @activity_array, $trackInfo->{TrackSummary};
            }

            my $i = 1;

            my %month_name_hash = map { ($_ => sprintf("%0.2d", $i++)) }
                qw(January February March April May June July August September October November December);

            my @activity_entries;

            foreach my $activity (grep { defined($_) } @activity_array) {

                my $activity_time = Date::Parse::str2time(
                    $activity->{EventDate} . " " . $activity->{EventTime});

                my @lt   = localtime($activity_time);
                my $date = POSIX::strftime("%Y%m%d", @lt);
                my $time = POSIX::strftime("%H%M00", @lt);

                my $activity_hash = {
                    address => {
                        zip             => $activity->{EventZIPCode},
                        state           => $activity->{EventState},
                        country         => $activity->{EventCountry},
                        city            => $activity->{EventCity},
                        signedforbyname => $activity->{Name},
                        company         => $activity->{FirmName},
                    },
                    date               => $date,
                    status_description => $activity->{Event},
                    time               => $time,
                };

                push @activity_entries, $activity_hash;

            }

            my $summary;
            if (scalar(@activity_entries) > 0) {
                $summary = $activity_entries[0];
            }

            my $result = {
                (($summary) ? (summary => $summary) : ()),
                activity => \@activity_entries,
            };

            debug('returning results.');

            Business::Shipping::Tracking::_delete_undefined_keys($result);
            $self->results({ $id => $result });
        }
    }

    trace 'returning success';
    return $self->is_success(1);
}

sub gen_unique_key {
    my $self = shift;
    my $id   = shift;

    return 'Tracking:USPS:' . $id;
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
