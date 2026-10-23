package Business::GoCardless::Webhook::V2;

=head1 NAME

Business::GoCardless::Webhook

=head1 DESCRIPTION

A class for gocardless webhooks, extends L<Business::GoCardless::Resource>.
For more details see the gocardless API documentation specific to webhooks:
https://developer.gocardless.com/api-reference/#appendix-webhooks

Note to use webhooks you must set the webhook_secret on the client object

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Webhook';
with 'Business::GoCardless::Utils';

use JSON ();
use Encode ();
use Business::GoCardless::Client;
use Business::GoCardless::Exception;
use Business::GoCardless::Webhook::Event;

=head1 ATTRIBUTES

    json
    signature
    has_legacy_data

The following attributes are only populated when the object comes from the
webhooks list endpoint (i.e. L<Business::GoCardless::Pro/webhooks>), and contain
details of the webhook delivery itself:

    id
    created_at
    url
    request_headers
    response_code
    response_body
    response_body_truncated
    response_headers
    response_headers_content_truncated
    response_headers_count_truncated
    is_test
    successful

=cut

has [ qw/
    events
    signature
    _signature

    has_legacy_data
    legacy_webhook
/ ] => (
    is => 'rw',
	clearer => 1,
);

has [ qw/
    id
    created_at
    url
    request_headers
    response_code
    response_body
    response_body_truncated
    response_headers
    response_headers_content_truncated
    response_headers_count_truncated
    is_test
    successful
/ ] => (
    is => 'rw',
);

=head1 Operations on a webhook

=head2 events

Get a list of L<Business::GoCardless::Webhook::Event> objects for processing:

    foreach my $Event ( @{ $Webhook->events // [] } ) {
        ...
    }

=head2 json

Allows you to set the json data sent to you in the webhook:

    $Webhook->json( $json_data )

Will throw a L<Business::GoCardless::Exception> exception if the json fails to
parse or if the signature does not match the payload data.

=cut

has json => (
	is       => 'rw',
    required => 1,
    trigger  => sub {
        my ( $self,$json ) = @_;

        # defensive decoding
		my $params;
		# the json is the raw (UTF-8 encoded) request body, as that is what
		# the signature is generated from
		eval { $params = JSON->new->utf8->decode( $json ) };
		$@ && do {
			$self->clear_events;
			$self->clear_signature;

			Business::GoCardless::Exception->throw({
				message  => "Failed to parse json: $@",
			});
		};

        if ( $params->{payload} ) {

            # this is a legacy API webhook
            $self->has_legacy_data( 1 );

            my $LegacyWebhook = Business::GoCardless::Webhook->new(
                json   => $json,
                client => Business::GoCardless::Client->new(
                    app_secret => $self->client->webhook_secret, # bad assumption?
                    %{ $self->client },
                ),
            );

            $self->legacy_webhook( $LegacyWebhook );

        } else {

            # coerce the events into objects
            $self->events([
                map { Business::GoCardless::Webhook::Event->new(
                    client => $self->client,
                    %{ $_ }
                ) }
                @{ $params->{events} }
            ]);

            $self->signature( $self->_signature ) if ! $self->signature;

            if ( ! $self->signature_valid(
                $json,$self->client->webhook_secret,$self->signature
            ) ) {
                $self->clear_events;
                $self->clear_signature;

                Business::GoCardless::Exception->throw({
                    message  => "Invalid signature for webhook",
                });
            }
        }

        return $json;
    }
);

=head2 is_legacy

See if the webhook is a legacy (Basic API) webhook

    if ( $Webhook->is_legacy ) {
        ...
    }

=cut

sub is_legacy { 0 }

=head2 retry

Retry the delivery of a webhook, only for webhooks from the webhooks list
endpoint (see L<Business::GoCardless::Pro/webhooks>). Returns a new
Webhook::V2 object for the new delivery:

    my $Retried = $Webhook->retry if ! $Webhook->successful;

=cut

sub retry {
    my ( $self ) = @_;

    my $data = $self->client->api_post(
        "/webhooks/@{[ $self->id ]}/actions/retry"
    );

    return ref( $self )->_new_from_api( $self->client,$data->{webhooks} );
}

# create an object from the webhooks API, which has the details of the
# delivery as well as the original request
sub _new_from_api {
    my ( $class,$client,$data ) = @_;

    return $class->new(
        client => $client,
        %{ $data }, # delivery details: id, url, response_code, etc
        # the signature is of the raw (UTF-8 encoded) request body
        json   => Encode::encode_utf8( $data->{request_body} ),
        # load ordering handled by setting _signature rather than signature
        # signature will be set in the json trigger
        _signature => $data->{request_headers}{'Webhook-Signature'},
    );
}

=head1 CONFIRMING WEBHOOKS

According to the gocardless API docs you should respond once the signature of the
webhook has been checked. The response is a HTTP status 204 code:

	HTTP/1.1 204 OK

You should handle this in your own code, the library will not do it for you. See
https://developer.gocardless.com/#response for more information

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
