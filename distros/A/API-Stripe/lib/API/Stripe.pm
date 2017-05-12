# ABSTRACT: Stripe.com API Client
package API::Stripe;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library qw(
    Str
);

extends 'API::Client';

our $VERSION = '0.07'; # VERSION

our $DEFAULT_URL = "https://api.stripe.com";

# ATTRIBUTES

has username => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# DEFAULTS

has '+identifier' => (
    default  => 'API::Stripe (Perl)',
    required => 0,
);

has '+url' => (
    default  => $DEFAULT_URL,
    required => 0,
);

has '+version' => (
    default  => 1,
    required => 0,
);

# CONSTRUCTION

method BUILD () {

    my $identifier = $self->identifier;
    my $username   = $self->username;
    my $version    = $self->version;
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);

    $url->path("/v$version");
    $url->userinfo($username);

    return $self;

}

method PREPARE ($ua, $tx, %args) {

    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;
    my $method  = $tx->req->method;
    my $content = 'application/json';

    if (grep lc $method eq $_, qw(delete patch post put)) {

        $content = 'application/x-www-form-urlencoded';

    }

    # default headers
    $headers->header('Content-Type' => $content);

    return $self;

}

method resource (@segments) {

    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        identifier => $self->identifier,
        username   => $self->username,
        version    => $self->version,
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Stripe - Stripe.com API Client

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use API::Stripe;

    my $stripe = API::Stripe->new(
        username   => 'USERNAME',
        identifier => 'APPLICATION NAME',
    );

    $stripe->debug(1);
    $stripe->fatal(1);

    my $charge = $stripe->charges('ch_163Gh12CVMZwIkvc');
    my $results = $charge->fetch;

    # after some introspection

    $charge->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Stripe (L<https://stripe.com>) API. For usage and
documentation information visit L<https://stripe.com/docs/api>. API::Stripe is
derived from L<API::Client> and inherits all of it's functionality. Please read
the documentation for API::Client for more usage information.

=head1 ATTRIBUTES

=head2 identifier

    $stripe->identifier;
    $stripe->identifier('IDENTIFIER');

The identifier attribute should be set to a string that identifies your app.

=head2 username

    $stripe->username;
    $stripe->username('USERNAME');

The username attribute should be set to an API key associated with your account.

=head2 debug

    $stripe->debug;
    $stripe->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=head2 fatal

    $stripe->fatal;
    $stripe->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Client::Exception> object.

=head2 retries

    $stripe->retries;
    $stripe->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=head2 timeout

    $stripe->timeout;
    $stripe->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=head2 url

    $stripe->url;
    $stripe->url(Mojo::URL->new('https://api.stripe.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=head2 user_agent

    $stripe->user_agent;
    $stripe->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=head1 METHODS

=head2 action

    my $result = $stripe->action($verb, %args);

    # e.g.

    $stripe->action('head', %args);    # HEAD request
    $stripe->action('options', %args); # OPTIONS request
    $stripe->action('patch', %args);   # PATCH request

The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=head2 create

    my $results = $stripe->create(%args);

    # or

    $stripe->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 delete

    my $results = $stripe->delete(%args);

    # or

    $stripe->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 fetch

    my $results = $stripe->fetch(%args);

    # or

    $stripe->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head2 update

    my $results = $stripe->update(%args);

    # or

    $stripe->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=head1 RESOURCES

=head2 account

    $stripe->account;

The account method returns a new instance representative of the API
I<Account> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#account>.

=head2 application_fees

    $stripe->application_fees;

The application_fees method returns a new instance representative of the API
I<Application Fees> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#application_fees>.

=head2 balance

    $stripe->balance->history;

The balance method returns a new instance representative of the API
I<Balance> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#balance>.

=head2 bitcoin_receivers

    $stripe->bitcoin->receivers;

The bitcoin_receivers method returns a new instance representative of the API
I<Bitcoin Receivers> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#bitcoin_receivers>.

=head2 cards

    $stripe->cards;

The cards method returns a new instance representative of the API
I<Cards> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#cards>.

=head2 charges

    $stripe->charges;

The charges method returns a new instance representative of the API
I<Charges> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#charges>.

=head2 coupons

    $stripe->coupons;

The coupons method returns a new instance representative of the API
I<Coupons> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#coupons>.

=head2 customers

    $stripe->customers;

The customers method returns a new instance representative of the API
I<Customers> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#customers>.

=head2 discounts

    $stripe->discounts;

The discounts method returns a new instance representative of the API
I<Discounts> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#discounts>.

=head2 disputes

    $stripe->disputes;

The disputes method returns a new instance representative of the API
I<Disputes> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#disputes>.

=head2 events

    $stripe->events;

The events method returns a new instance representative of the API
I<Events> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#events>.

=head2 fee_refunds

    $stripe->application_fees('fee_6HiNDgLZ85q6KD')->refunds('fr_6HiNza7kmLzMFc');

The fee_refunds method returns a new instance representative of the API
I<Application Fee Refunds> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#fee_refunds>.

=head2 file_uploads

    $stripe->files;

The file_uploads method returns a new instance representative of the API
I<File Uploads> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#file_uploads>.

=head2 invoiceitems

    $stripe->invoiceitems;

The invoiceitems method returns a new instance representative of the API
I<Invoice Items> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#invoiceitems>.

=head2 invoices

    $stripe->invoices;

The invoices method returns a new instance representative of the API
I<Invoices> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#invoices>.

=head2 plans

    $stripe->plans;

The plans method returns a new instance representative of the API
I<Plans> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#plans>.

=head2 recipients

    $stripe->recipients;

The recipients method returns a new instance representative of the API
I<Recipients> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#recipients>.

=head2 refunds

    $stripe->refunds;

The refunds method returns a new instance representative of the API
I<Refunds> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#refunds>.

=head2 subscriptions

    $stripe->subscriptions;

The subscriptions method returns a new instance representative of the API
I<Subscriptions> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#subscriptions>.

=head2 tokens

    $stripe->tokens;

The tokens method returns a new instance representative of the API
I<Tokens> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#tokens>.

=head2 transfer_reversals

    $stripe->transfers('tr_164xRv2eZvKYlo2CZxJZWm1E')->reversals;

The transfer_reversals method returns a new instance representative of the API
I<Transfer Reversals> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#transfer_reversals>.

=head2 transfers

    $stripe->transfers;

The transfers method returns a new instance representative of the API
I<Transfers> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://stripe.com/docs/api#transfers>.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
