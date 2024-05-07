package Business::Monzo;

=head1 NAME

Business::Monzo - Perl library for interacting with the Monzo API
(https://api.monzo.com)

=for html
<a href='https://travis-ci.org/leejo/business-monzo?branch=master'><img src='https://travis-ci.org/leejo/business-monzo.svg?branch=master' alt='Build Status' /></a>
<a href='https://coveralls.io/r/leejo/business-monzo?branch=master'><img src='https://coveralls.io/repos/leejo/business-monzo/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

0.13

=head1 DESCRIPTION

Business::Monzo is a library for easy interface to the Monzo banking API,
it implements all of the functionality currently found in the service's API
documentation: L<https://monzo.com/docs>

B<You should refer to the official Monzo API documentation in conjunction>
B<with this perldoc>, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods.

Please note this library is very much a work in progress, as is the Monzo API.
Also note the Monzo were previously called Mondo, so if you see any references
to Mondo they are either typos or historical references that have not yet been
updated to reflect the changes.

All objects within the Business::Monzo namespace are immutable. Calls to methods
will, for the most part, return new instances of objects.

=head1 SYNOPSIS

    my $monzo = Business::Monzo->new(
        token   => $token, # REQUIRED
        api_url => $url,   # optional
    );

    # transaction related information
    my @transactions = $monzo->transactions( account_id => $account_id );

    my $Transaction  = $monzo->transaction( id => 1 );

    $Transaction->annotate(
        foo => 'bar',
        baz => 'boz,
    );

    my $annotations = $Transaction->annotations;

    # account related information
    my @accounts = $monzo->accounts;

    foreach my $Account ( @accounts ) {

        my @transactions = $Account->transactions;

        $Account->add_feed_item(
            params => {
                title     => 'My Feed Item',
                image_url => 'http://...',
            }
        );

        # balance information
        my $Balance = $Account->balance;

        # webhooks
        my @webhooks = $Account->webhooks;

        my $Webhook = $Account->register_webhook(
            callback_url => 'http://www.foo.com',
        );

        $Webhook->delete
    }

    # pots
    my @pots = $monzo->pots();

    # attachments
    my $Attachment = $monzo->upload_attachment(
        file_name => 'foo.png',
        file_type => 'image/png',
    );

    $Attachment->register(
        external_id => 'my_id'
    );

    $Attachment->deregister;

=head1 ERROR HANDLING

Any problems or errors will result in a Business::Monzo::Exception
object being thrown, so you should wrap any calls to the library in the
appropriate error catching code (ideally a module from CPAN):

    try {
        ...
    }
    catch ( Business::Monzo::Exception $e ) {
        # error specific to Business::Monzo
        ...
        say $e->message;  # error message
        say $e->code;     # HTTP status code
        say $e->response; # HTTP status message

        # ->request may not always be present
        say $e->request->{path}    if $e->request;
        say $e->request->{params}  if $e->request;
        say $e->request->{headers} if $e->request;
        say $e->request->{content} if $e->request;
    }
    catch ( $e ) {
        # some other failure?
        ...
    }

You can view some useful debugging information by setting the MONZO_DEBUG
env varible, this will show the calls to the Monzo endpoints as well as a
stack trace in the event of exceptions:

    $ENV{MONZO_DEBUG} = 1;

=cut

use strict;
use warnings;

use Moo;
with 'Business::Monzo::Version';

$Business::Monzo::VERSION = '0.13';

use Carp qw/ confess /;

use Business::Monzo::Client;
use Business::Monzo::Account;
use Business::Monzo::Pot;
use Business::Monzo::Attachment;

=head1 ATTRIBUTES

=head2 token

Your Monzo access token, this is required

=head2 api_url

The Monzo url, which will default to https://api.monzo.com

=head2 client

A Business::Monzo::Client object, this will be constructed for you so
you shouldn't need to pass this

=cut

has [ qw/ token / ] => (
    is       => 'ro',
    required => 1,
);

has api_url => (
    is       => 'ro',
    required => 0,
    default  => sub { $Business::Monzo::API_URL },
);

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::Monzo::Client" )
            if ref $_[0] ne 'Business::Monzo::Client';
    },
    required => 0,
    lazy     => 1,
    default  => sub {
        my ( $self ) = @_;

        # fix any load order issues with Resources requiring a Client
        $Business::Monzo::Resource::client = Business::Monzo::Client->new(
            token   => $self->token,
            api_url => $self->api_url,
        );
    },
);

=head1 METHODS

In the following %query_params refers to the possible query params as shown in
the Monzo API documentation. For example: limit=100.

    # transactions in the previous month
    my @transactions = $monzo->transactions(
        since => DateTime->now->subtract( months => 1 ),
    );

=cut

=head2 transactions

    $monzo->transactions( %query_params );

Get a list of transactions. Will return a list of L<Business::Monzo::Transaction>
objects. Note you must supply an account_id in the params hash;

=cut

sub transactions {
    my ( $self,%params ) = @_;

    # transactions requires account_id, whereas transaction doesn't
    # the Monzo API is a little inconsistent at this point...
    $params{account_id} || Business::Monzo::Exception->throw({
        message => "transactions requires params: account_id",
    });

    return Business::Monzo::Account->new(
        client => $self->client,
        id     => $params{account_id},
    )->transactions( 'expand[]' => 'merchant',%params );
}

=head2 balance

    my $Balance = $monzo->balance( account_id => $account_id );

Get an account balance Returns a L<Business::Monzo::Balance> object.

=cut

sub balance {
    my ( $self,%params ) = @_;

    $params{account_id} || Business::Monzo::Exception->throw({
        message => "balance requires params: account_id",
    });

    return Business::Monzo::Account->new(
        client => $self->client,
        id     => $params{account_id},
    )->balance( %params );
}

=head2 transaction

    my $Transaction = $monzo->transaction(
        id     => $id,
        expand => 'merchant'
    );

Get a transaction. Will return a L<Business::Monzo::Transaction> object

=cut

sub transaction {
    my ( $self,%params ) = @_;

    if ( my $expand = delete( $params{expand} ) ) {
        $params{'expand[]'} = $expand;
    }

    return $self->client->_get_transaction( \%params );
}

=head2 accounts

    $monzo->accounts;                                   # all accounts
    $monzo->accounts( account_type => "uk_prepaid" );   # prepaid accounts
    $monzo->accounts( account_type => "uk_retail" );    # current accounts

Get a list of accounts. Will return a list of L<Business::Monzo::Account>
objects

=cut

sub accounts {
    my ( $self,%params ) = @_;
    return $self->client->_get_accounts( \%params );
}

=head2 pots

    $monzo->pots;

Get a list of pots. Will return a list of L<Business::Monzo::Pot>
objects

=cut

sub pots {
    my ( $self ) = @_;
    return $self->client->_get_pots;
}

sub upload_attachment {
    my ( $self,%params ) = @_;

    return Business::Monzo::Attachment->new(
        client => $self->client,
    )->upload( %params );
}

=head1 PAGINATION

As per the Monzo docs: L<https://monzo.com/docs/#pagination> - you can pass
through arguments to the methods (e.g. C<transactions>) to limit the return
data or set date ranges, etc:

    # last three months transactions, but only show 5
    my $since = DateTime->now->subtract( months => 3 )->iso8601 . "Z";
    my $limit = 5;

    foreach my $transaction (
        $monzo->transactions(
            account_id => $account_id,
            limit      => $limit,
            since      => $since,
        )
    {
        ...
    }

The supported pagination keys are C<limit>, C<since>, and C<before> - where
C<since> can be an RFC 3339-encoded timestamp or an object id, and C<before>
can be an RFC 3339-encoded timestamp. C<limit> should always be an integer.

=head1 EXAMPLES

See the t/002_end_to_end.t test included with this distribution. you can run
this test against the Monzo emulator by running end_to_end_emulated.sh (this
is advised, don't run it against a live endpoint).

You can also see the scripts in the bin/ directory included in this dist for
more examples.

=head1 SEE ALSO

L<Business::Monzo::Account>

L<Business::Monzo::Attachment>

L<Business::Monzo::Balance>

L<Business::Monzo::Transaction>

L<Business::Monzo::Webhook>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

With contributions from:

    Chris Merry
    Aaron Moses
    Dave Cross

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-monzo

=cut

1;

# vim: ts=4:sw=4:et
