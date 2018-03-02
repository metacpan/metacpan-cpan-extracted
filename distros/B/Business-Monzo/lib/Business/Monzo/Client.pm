package Business::Monzo::Client;

=head1 NAME

Business::Monzo::Client

=head1 DESCRIPTION

This is a class for the lower level requests to the Monzo API. generally
there is nothing you should be doing with this.

=cut

use strict;
use warnings;

use Moo;
with 'Business::Monzo::Utils';
with 'Business::Monzo::Version';

use Business::Monzo::Exception;
use Business::Monzo::Transaction;
use Business::Monzo::Account;

use Data::Dumper;
use Mojo::UserAgent;
use Mojo::JSON;
use Carp qw/ carp /;

=head1 ATTRIBUTES

=head2 token

Your Monzo access token, this is required

=head2 api_url

The Monzo url, which will default to https://api.monzo.com

=head2 user_agent

The user agent string used in requests to the monzo API, defaults to
business-monzo/perl/v . $version_of_this_library.

=cut

has [ qw/ token / ] => (
    is       => 'ro',
    required => 1,
);

has api_url => (
    is       => 'ro',
    required => 0,
    default  => sub {
        return $ENV{MONZO_URL} || $Business::Monzo::API_URL;
    },
);

has user_agent => (
    is      => 'ro',
    default => sub {
        # probably want more infoin here, version of perl, platform, and such
        require Business::Monzo;
        return "business-monzo/perl/v" . $Business::Monzo::VERSION;
    }
);

has _ua => (
    is => 'ro',
    lazy => 1,
    builder => '_build_ua',
);

sub _build_ua {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;
    $ua->transactor->name( $self->user_agent );
    $ua->proxy->detect;
    return $ua;
}

sub _get_transaction {
    my ( $self,$params ) = @_;

    my $data = $self->_api_request( 'GET',"transactions/" . $params->{id} );

    my $transaction = Business::Monzo::Transaction->new(
        client => $self,
        %{ $data->{transaction} },
    );

    return $transaction;
}

sub _get_transactions {
    return shift->_get_entities( shift,'transaction' );
}

sub _get_accounts {
    return shift->_get_entities( shift,'account' );
}

sub _get_pots {
    return shift->_get_entities( shift,'pot','pots/listV1' );
}

sub _get_entities {
    my ( $self,$params,$entity,$endpoint ) = @_;

    my $plural = $entity . 's';
    $endpoint //= $plural;
    my $data   = $self->_api_request( 'GET', $endpoint, $params );
    my $class  = "Business::Monzo::" . ucfirst( $entity );
    my @objects;

    foreach my $e ( @{ $data->{$plural} // [] } ) {
        push( @objects,$class->new( client => $self,%{ $e } ) );
    }

    return @objects;
}

=head1 METHODS

    api_get
    api_post
    api_delete
    api_patch

Make a request to the Monzo API:

    my $data = $Client->api_get( 'location',\%params );

May return a the decoded response data as a hash/array/string depending
on the reposonse type

=cut

sub api_get {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'GET',$path,$params );
}

sub api_post {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'POST',$path,$params );
}

sub api_delete {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'DELETE',$path,$params );
}

sub api_patch {
    my ( $self,$path,$params ) = @_;
    return $self->_api_request( 'PATCH',$path,$params );
}

sub _api_request {
    my ( $self,$method,$path,$params ) = @_;

    carp( "$method -> $path" )
        if $ENV{MONZO_DEBUG};

    $path = $self->_add_query_params( $path,$params )
        if $method =~ /GET/;

    my $tx;
    $method = lc( $method );

    $path = $path =~ /^http/ ? $path : join( '/',$self->api_url,$path );

    carp( "PATH: $path" )
        if $ENV{MONZO_DEBUG};

    carp( "PARAMS: " . Dumper $params )
        if $ENV{MONZO_DEBUG};

    my %headers = (
        'Authorization' => "Bearer " . $self->token,
        'Accept'        => 'application/json',
    );

    if ( $method =~ /POST|PUT|PATCH/i ) {
        $tx = $self->_ua->$method( $path => { %headers } => form => $params );
    } else {
        $tx = $self->_ua->$method( $path => { %headers } );
    }

    if ( $tx->success ) {
        carp( "RES: " . Dumper $tx->res->json )
            if $ENV{MONZO_DEBUG};

        return $tx->res->json;
    }
    else {
        my $error = $tx->error;

        carp( "ERROR: " . Dumper $error )
            if $ENV{MONZO_DEBUG};

        Business::Monzo::Exception->throw({
            message  => $error->{message},
            code     => $error->{code},
            response => $tx->res->body,
        });
    }
}

sub _add_query_params {
    my ( $self,$path,$params ) = @_;

    if ( my $query_params = $self->normalize_params( $params ) ) {
        return "$path?$query_params";
    }

    return $path;
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-monzo

=cut

1;

# vim: ts=4:sw=4:et
