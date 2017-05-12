package Business::MollieAPI;

use strict;
use 5.008_005;
our $VERSION = '0.10';

use Moo;
use URI;

use LWP::UserAgent;
use JSON::XS;

use Business::MollieAPI::Payments;
use Business::MollieAPI::Methods;
use Business::MollieAPI::Issuers;

has endpoint => (
    is      => 'rw',
    builder => 1,
);

sub _build_endpoint {
    my $self = shift;
    return URI->new('https://api.mollie.nl');
}

has version => (
    is      => 'rw',
    default => 'v1',
);

has client_version => (
    is      => 'rw',
    default => $VERSION,
);


has payments => (
    is => 'lazy',
);

sub _build_payments {
    my $self = shift;
    return Business::MollieAPI::Payments->new(client => $self);
}

has methods => (
    is => 'lazy',
);

sub _build_methods {
    my $self = shift;
    return Business::MollieAPI::Methods->new(client => $self);
}

has issuers => (
    is => 'lazy',
);

sub _build_issuers {
    my $self = shift;
    return Business::MollieAPI::Issuers->new(client => $self);
}

has api_key => (
    is  => 'rw',
    isa => sub {
        my $value = shift;
        die "API KEY is not valid" unless $value =~ m/^(live_|test_)\w+/;
    },
);

sub log_response {
    return;
}

sub perform {
    my $self = shift;
    my $req = shift;
    $req->header('Authorization', 'Bearer ' . $self->api_key);
    my $ua = LWP::UserAgent->new();
    my $res = $ua->request($req);
    my $data = decode_json($res->decoded_content);
    $self->log_response({ request => $req, response => $res });
    return $data;
}

1;
__END__

=encoding utf-8

=head1 NAME

Business::MollieAPI - Implementation of new Mollie API

=head1 SYNOPSIS

  use Business::MollieAPI;

  my $api = Business::MollieAPI->new(api_key => 'live_.....');

  my $methods = $api->methods->all;

  my $issuers = $api->issuers->all;

  my $payment = $api->payments->create(
    amount      => '12.34',
    redirectUrl => 'http://example.com/test.php',
    description => 'Order #123',
  );

  # Save $payment->{id} for later

  # Later...
  my $l = $api->payments->get($id);

=head1 DESCRIPTION

Business::MollieAPI is the implementation of the new Mollie API.

It supports multiple payment methods: iDEAL, MisterCash and creditcard.

Currently also the webhook url needs to be set.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright 2013- Peter Stuifzand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
