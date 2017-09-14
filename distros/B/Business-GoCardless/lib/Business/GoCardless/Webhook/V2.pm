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
use Business::GoCardless::Client;
use Business::GoCardless::Exception;
use Business::GoCardless::Webhook::Event;

=head1 ATTRIBUTES

    json
    signature
    has_legacy_data

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
		eval { $params = JSON->new->decode( $json ) };
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

=head1 CONFIRMING WEBHOOKS

According to the gocardless API docs you should respond once the signature of the
webhook has been checked. The response is a HTTP status 204 code:

	HTTP/1.1 204 OK

You should handle this in your own code, the library will not do it for you. See
https://developer.gocardless.com/#response for more information

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
