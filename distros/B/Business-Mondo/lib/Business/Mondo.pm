package Business::Mondo;

=head1 NAME

Business::Mondo - DEPRECATED please use Business::Monzo instead
(https://api.getmondo.co.uk)

=for html
<a href='https://travis-ci.org/leejo/business-mondo?branch=master'><img src='https://travis-ci.org/leejo/business-mondo.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/leejo/business-mondo?branch=master'><img src='https://coveralls.io/repos/leejo/business-mondo/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

9999.99

=head1 DESCRIPTION

Business::Mondo was a library for easy interface to the Mondo banking API,
since Mondo have now changed their name to Monzo the namespace of the dist
has been updated to L<Business::Monzo> and you should now be using that
dist instead.

Note the functionality of Business::Mondo remains but may be removed from
CPAN at anytime in the future.

=cut

use strict;
use warnings;

use Moo;
with 'Business::Mondo::Version';

use Carp qw/ confess /;

use Business::Mondo::Client;
use Business::Mondo::Account;
use Business::Mondo::Attachment;

has [ qw/ token / ] => (
    is       => 'ro',
    required => 1,
);

has api_url => (
    is       => 'ro',
    required => 0,
    default  => sub { $Business::Mondo::API_URL },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::Mondo::Client" )
            if ref $_[0] ne 'Business::Mondo::Client';
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        # fix any load order issues with Resources requiring a Client
        $Business::Mondo::Resource::client = Business::Mondo::Client->new(
            token   => $self->token,
            api_url => $self->api_url,
        );
    },
);

sub transactions {
    my ( $self,%params ) = @_;

    # transactions requires account_id, whereas transaction doesn't
    # the Mondo API is a little inconsistent at this point...
    $params{account_id} || Business::Mondo::Exception->throw({
        message => "transactions requires params: account_id",
    });

    return Business::Mondo::Account->new(
        client => $self->client,
        id     => $params{account_id},
    )->transactions( 'expand[]' => 'merchant' );
}

sub balance {
    my ( $self,%params ) = @_;

    $params{account_id} || Business::Mondo::Exception->throw({
        message => "balance requires params: account_id",
    });

    return Business::Mondo::Account->new(
        client => $self->client,
        id     => $params{account_id},
    )->balance( %params );
}

sub transaction {
    my ( $self,%params ) = @_;

    if ( my $expand = delete( $params{expand} ) ) {
        $params{'expand[]'} = $expand;
    }

    return $self->client->_get_transaction( \%params );
}

sub accounts {
    my ( $self ) = @_;
    return $self->client->_get_accounts;
}

sub upload_attachment {
    my ( $self,%params ) = @_;

    return Business::Mondo::Attachment->new(
        client => $self->client,
    )->upload( %params );
}

=head1 SEE ALSO

L<Business::Monzo>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
