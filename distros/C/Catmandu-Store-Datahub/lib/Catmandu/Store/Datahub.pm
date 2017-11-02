package Catmandu::Store::Datahub;

our $VERSION = '0.08';

use Catmandu::Sane;

use Moo;
use Catmandu::Store::Datahub::Bag;
use Catmandu::Store::Datahub::OAuth;
use LWP::UserAgent;

with 'Catmandu::Store';

has url           => (is => 'ro', required => 1);
has client_id     => (is => 'ro', required => 1);
has client_secret => (is => 'ro', required => 1);
has username      => (is => 'ro', required => 1);
has password      => (is => 'ro', required => 1);

has client       => (is => 'lazy');
has access_token => (
    is      => 'lazy',
    writer  => '_set_access_token',
    builder => '_build_access_token'
);

##
# TODO: error reporting 'n stuff

sub _build_client {
    my $self = shift;
    return LWP::UserAgent->new();
}

sub _build_access_token {
    my $self = shift;
    return $self->generate_token();
}

sub set_access_token {
    my $self = shift;
    # Used to regenerate the token when it becomes invalid
    return $self->_set_access_token($self->generate_token());
}

sub generate_token {
    my $self = shift;
    my $oauth = Catmandu::Store::Datahub::OAuth->new(username => $self->username, password => $self->password, client_id => $self->client_id, client_secret => $self->client_secret, url => $self->url);
    return $oauth->token();
}

1;

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-Store-Datahub"><img src="https://travis-ci.org/thedatahub/Catmandu-Store-Datahub.svg?branch=master"></a>

Catmandu::Store::Datahub - Store/retrieve items from the Datahub

=head1 SYNOPSIS

A module that allows to interface with the Datahub as a Catmandu::Store.

Supports retrieving, adding, deleting and updating of data.

=head1 DESCRIPTION

Configure the L<Datahub|https://github.com/thedatahub/Datahub> as a L<store|http://librecat.org/Catmandu/#stores> for L<Catmandu|http://librecat.org/>.

With Catmandu, it is possible to convert (almost) any data to L<LIDO|http://lido-schema.org/>, which is suitable for importing in the Datahub. This module allows you to integrate the importing in your Catmandu workflow by setting up a Catmandu-compatible interface between the Datahub and Catmandu.

Note that you must convert your data to LIDO in order to use this module. All other formats will result in an error.

=head1 CONFIGURATION

To configure the store, the location of the Datahub is required. As OAuth2 is used, a client id and secret are also required, as well as a username and a password.

=over

=item C<url>

base url of the Datahub (e.g. I<http://www.datahub.be>).

=item C<client_id>

OAuth2 client ID.

=item C<client_secret>

OAuth2 client secret.

=item C<username>

Datahub username.

=item C<password>

Datahub password.

=back

=head1 USAGE

See L<the Catmandu documentation|http://librecat.org/Catmandu/#stores> for more information on how to use Stores.

=head1 SEE ALSO

L<Catmandu::LIDO> and L<Catmandu>

=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>
Pieter De Praetere <pieter@packed.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by PACKED, vzw, Vlaamse Kunstcollectie, vzw.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License, Version 3, June 2007.

=cut
