package Business::GoCardless::RedirectFlow;

=head1 NAME

Business::GoCardless::RedirectFlow

=head1 DESCRIPTION

A class for a gocardless redirect flow, extends L<Business::GoCardless::PreAuthorization>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::PreAuthorization';

use Business::GoCardless::Exception;
use Business::GoCardless::Mandate;

=head1 ATTRIBUTES

    confirmation_url
    redirect_url
    scheme
    session_token
    success_redirect_url
    links
    metadata

=cut

has [ qw/
    confirmation_url
    redirect_url
    scheme
    session_token
    success_redirect_url
    links
    metadata
/ ] => (
    is => 'rw',
);


=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

sub cancel {
	Business::GoCardless::Exception->throw({
		message => "->cancel on a RedirectFlow is not meaningful in the Pro API",
	});
}

sub mandate {
    my ( $self ) = @_;

    if ( ! $self->links ) {
        $self->find_with_client( 'redirect_flows' );
    }

    my $Mandate = Business::GoCardless::Mandate->new(
        client => $self->client,
        id => $self->links ? $self->links->{mandate} : undef,
    );

    return $Mandate->find_with_client( 'mandates' );
}

1;

# vim: ts=4:sw=4:et
