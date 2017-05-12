package Business::CPI::Gateway::MercadoPago;

# ABSTRACT: Business::CPI's Mercado Pago driver

use Moo;
use Carp;
use URI;
use Data::Dumper;
use LWP::UserAgent ();
use JSON;

extends 'Business::CPI::Gateway::Base';

our $VERSION = '0.102'; # VERSION

has '+currency' => ( default => sub { 'BRL' } );

has _base_url => (
    is      => 'ro',
    default => sub { 'https://api.mercadolibre.com' },
);

has [ 'token', 'back_url' ] => (
    is       => 'ro',
    required => 1
);

has _user_agent_name => (
    is      => 'ro',
    default => sub {
        my $base    = 'Business::CPI::Gateway::MercadoPago';
        my $version = __PACKAGE__->VERSION;
        return $version ? "$base/$version" : $base;
    }
);

has user_agent => (
    is      => 'lazy',
    default => sub {
        my $self = shift;

        my $ua = LWP::UserAgent->new();
        $ua->agent( $self->_user_agent_name );
        $ua->default_header( 'Accept'       => 'application/json' );
        $ua->default_header( 'Content-Type' => 'application/json' );

        return $ua;
    },
);

has access_token => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_builder_access_token'
);

sub _builder_access_token {
    my $self     = shift;
    my $auth_url = $self->_build_uri('/oauth/token');

    my $ua = $self->user_agent;

    $ua->default_header(
        'Content-Type' => 'application/x-www-form-urlencoded' );

    my $r = $ua->post(
        $auth_url,
        {
            grant_type    => 'client_credentials',
            client_id     => $self->receiver_email,
            client_secret => $self->token
        }
    );
    die "Couldn't connect to '$auth_url': " . $r->status_line
      if $r->is_error;

    my $json         = from_json( $r->content );
    my $access_token = $json->{access_token};

    die "Coundn't retried access_token" unless $access_token;

    return $access_token;
}

sub _build_uri {
    my ( $self, $path, $info ) = @_;
    my $uri = URI->new( $self->_base_url . $path );
    return $uri->as_string;
}

sub _make_json {
    my ( $self, $info ) = @_;

    my $items;
    for my $item ( @{ $info->{items} } ) {
        my $item_ref = {
            id          => $item->id,
            title       => $item->description,
            description => $item->description,
            quantity    => $item->quantity,
            unit_price  => $item->price * 1,
            currency_id => $self->currency,

            # picture_url (?)
        };
        push( @{$items}, $item_ref );
    }

    my $request = {
        items              => $items,
        external_reference => $info->{payment_id},
        payer              => {
            name  => $info->{buyer}->name,
            email => $info->{buyer}->email
        },
        back_urls => {
            success => $self->back_url,
            failure => $self->back_url,
            pending => $self->back_url
        }
    };

    return to_json( $request, { utf8 => 1, pretty => 1 } );
}

sub get_checkout_code {
    my ( $self, $info ) = @_;

    my $ua  = $self->user_agent;
    my $url = $self->_build_uri(
        '/checkout/preferences?access_token=' . $self->access_token );
    my $json = $self->_make_json($info);

    my $req = HTTP::Request->new( 'POST', $url );
    $req->content_type('application/json');
    $req->content($json);
    my $res = $ua->request($req);

    die $res->status_line unless $res->is_success;

    my $content = $res->content;
    $json = from_json($content);

    my $init_point = $json->{'init_point'};

    $self->checkout_url($init_point);
    return $init_point;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Business::CPI::Gateway::MercadoPago - Business::CPI's Mercado Pago driver

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    my $cpi = Business::CPI::Gateway::MercadoPago->new(
        receiver_email => $ENV{'MP_CLIENT_ID'},
        token          => $ENV{'MP_CLIENT_SECRET'},
        currency       => 'BRL',
        back_url       => 'https://com',
    );

    my $cart = $cpi->new_cart({
        buyer => {
            name  => 'Mr. Buyer',
            email => 'sender@andrewalker.net',
        }
    });

    my $item = $cart->add_item({
        id          => 1,
        quantity    => 1,
        price       => 200,
        description => 'my desc'
    });

    $cart->get_checkout_code($shopping_id);

=head1 DESCRIPTION

Business::CPI::Gateway::MercadoPago, Perl extension to access "Mercado Pago" API.

For more information, see L<http://developers.mercadopago.com/>.

=head1 ATTRIBUTES

=head2 receiver_email

The 'cliente_id' provided by Mercado Pago

=head2 token

The 'client_secret' provided by Mercado Pago

=head2 back_url

The return URL.

=head1 SPONSORED BY

Aware - L<http://www.aware.com.br>

=head1 SEE ALSO

L<Business::CPI::Gateway::Base>

=head1 AUTHOR

Thiago Rondon <thiago@aware.com.br>

=head1 CONTRIBUTOR

Carlos Corrêa <cadu.rcorrea@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Thiago Rondon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
