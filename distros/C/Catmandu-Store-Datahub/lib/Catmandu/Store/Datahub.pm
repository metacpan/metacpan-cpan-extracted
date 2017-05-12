package Catmandu::Store::Datahub;

our $VERSION = '0.01';

use Catmandu::Sane;

use Moo;
use Lido::XML;
use Catmandu::Store::Datahub::Bag;
use Catmandu::Store::Datahub::OAuth;
use LWP::UserAgent;


with 'Catmandu::Store';

has url           => (is => 'ro', required => 1);
has client_id     => (is => 'ro', required => 1);
has client_secret => (is => 'ro', required => 1);
has username      => (is => 'ro', required => 1);
has password      => (is => 'ro', required => 1);

has lido     => (is => 'lazy');
has client   => (is => 'lazy');
has access_token => (is => 'lazy');

##
# TODO: error reporting 'n stuff

sub _build_lido {
    my $self = shift;
    return Lido::XML->new();
}

sub _build_client {
    my $self = shift;
    return LWP::UserAgent->new();
}

sub _build_access_token {
    my $self = shift;
    my $oauth = Catmandu::Store::Datahub::OAuth->new(username => $self->username, password => $self->password, client_id => $self->client_id, client_secret => $self->client_secret, url => $self->url);
    return $oauth->token();
}


1;

=head1 NAME

Catmandu::Store::Datahub - Store/retrieve items from the Datahub

=head1 SYNOPSIS

A module that allows to interface with the Datahub as a Catmandu::Store.

Supports retrieving, adding, deleting and updating of data.

=head1 DESCRIPTION

Configure the [Datahub](https://github.com/thedatahub/Datahub) as a [store](http://librecat.org/Catmandu/#stores) for [Catmandu](http://librecat.org/).

With Catmandu, it is possible to convert (almost) any data to [LIDO](http://lido-schema.org/), which is suitable for importing in the Datahub. This module allows you to integrate the importing in your Catmandu workflow by setting up a Catmandu-compatible interface between the Datahub and Catmandu.

Note that you must convert your data to LIDO in order to use this module. All other formats will result in an error.

=head1 CONFIGURATION

To configure the store, the location of the Datahub is required. As OAuth2 is used, a client id and secret are also required, as well as a username and a password.

* `url`: base url of the Datahub (e.g. _http://www.datahub.be_).
* `client_id`: OAuth2 client ID.
* `client_secret`: OAuth2 client secret.
* `username`: Datahub username.
* `password`: Datahub password.

=head1 USAGE

See [the Catmandu documentation](http://librecat.org/Catmandu/#stores) for more information on how to use Stores.

=head1 SEE ALSO

L<Catmandu::LIDO> and L<Catmandu>

=head1 AUTHORS

Pieter De Praetere, C<< pieter at packed.be >>
Matthias Vandermaesen, C<< matthias.vandermaesen at vlaamsekunstcollectie.be >>

=head1 CONTRIBUTORS

Pieter De Praetere
Matthias Vandermaesen

=head1 COPYRIGHT AND LICENSE

The Perl software is copyright (c) 2016 by Pieter De Praetere.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=encoding utf8

=cut
