package Catalyst::Plugin::Session::Store::MongoDB;
use strict;
use warnings;

our $VERSION = '0.03';

use Moose;
use namespace::autoclean;

use MongoDB::MongoClient;
use Data::Dumper;

BEGIN { extends 'Catalyst::Plugin::Session::Store' }

has client_options => (
  isa => 'HashRef',
  is => 'ro',
  lazy_build => 1,
);

# deprecated
has hostname => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

# deprecated
has port => (
  isa => 'Int',
  is => 'ro',
  lazy_build => 1,
);

has dbname => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

has collectionname => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

has '_collection' => (
  isa => 'MongoDB::Collection',
  is => 'ro',
  lazy_build => 1,
);

has '_connection' => (
  isa => 'MongoDB::MongoClient',
  is => 'ro',
  lazy_build => 1,
);

has '_db' => (
  isa => 'MongoDB::Database',
  is => 'ro',
  lazy_build => 1,
);

sub _cfg_or_default {
  my ($self, $name, $default) = @_;

  # _session_plugin_config is not present for tests
  if ($self->can('_session_plugin_config')) {
    my $cfg = $self->_session_plugin_config;
    return $cfg->{$name} || $default;
  } else {
    return $default;
  }
}

sub _build_client_options {
  my ($self) = @_;
  return $self->_cfg_or_default('client_options', {
    host => $self->hostname,
    port => $self->port,
  });
}

sub _build_hostname {
  my ($self) = @_;
  return $self->_cfg_or_default('hostname', 'localhost');
}

sub _build_port {
  my ($self) = @_;
  return $self->_cfg_or_default('port', 27017);
}

sub _build_dbname {
  my ($self) = @_;
  return $self->_cfg_or_default('dbname', 'catalyst');
}

sub _build_collectionname {
  my ($self) = @_;
  return $self->_cfg_or_default('collectionname', 'session');
}

sub _build__collection {
  my ($self) = @_;

  return $self->_db->get_collection($self->collectionname);
}

sub _build__connection {
  my ($self) = @_;

  return MongoDB::MongoClient->new(%{$self->client_options});
}

sub _build__db {
  my ($self) = @_;

  return $self->_connection->get_database($self->dbname);
}

sub _serialize {
  my ($self, $data) = @_;

  my $d = Data::Dumper->new([ $data ]);

  return $d->Indent(0)->Purity(1)->Terse(1)->Quotekeys(0)->Dump;
}

sub get_session_data {
  my ($self, $key) = @_;

  my ($prefix, $id) = split(/:/, $key);

  my $found = $self->_collection->find_one({ _id => $id },
    { $prefix => 1, 'expires' => 1 });

  return undef unless $found;

  if ($found->{expires} && time() > $found->{expires}) {
    $self->delete_session_data($id);
    return undef;
  }

  return eval($found->{$prefix});
}

sub store_session_data {
  my ($self, $key, $data) = @_;

  my ($prefix, $id) = split(/:/, $key);

  # we need to not serialize the expires date, since it comes in as an
  # integer and we need to preserve that in order to be able to use
  # mongodb's '$lt' function in delete_expired_sessions()
  my $serialized;
  if ($prefix =~ /^expires$/) {
    $serialized = $data;
  } else {
    $serialized = $self->_serialize($data);
  }

  $self->_collection->update({ _id => $id },
    { '$set' => { $prefix => $serialized } }, { upsert => 1 });
}

sub delete_session_data {
  my ($self, $key) = @_;

  my ($prefix, $id) = split(/:/, $key);

  my $found = $self->_collection->find_one({ _id => $id });
  return unless $found;

  if (exists($found->{$prefix})) {
    if ((scalar(keys(%$found))) > 2) {
      $self->_collection->update({ _id => $id },
        { '$unset' => { $prefix => 1 }} );
      return;
    } else {
      $self->_collection->remove({ _id => $id });
    }
  }
}

sub delete_expired_sessions {
  my ($self) = @_;

  $self->_collection->remove({ 'expires' => { '$lt' => time() } });
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

Catalyst::Plugin::Session::Store::MongoDB - MongoDB session store for Catalyst

=head1 SYNOPSIS

In your MyApp.pm:

  use Catalyst qw/
    Session
    Session::Store::MongoDB
    Session::State::Cookie # or similar
  /;

and in your MyApp.conf:

  <Plugin::Session>
    <client_options>             # if empty, lets MongoDB::MongoClient
      host mongodb://foo:27017   #   use its own defaults
      timeout 10000              # if unspecified, defaults to
      ...                        #   { host => hostname, port => port }
    </client_options>            #   for compatibility with previous versions
    dbname test                  # defaults to catalyst
    collectionname s2            # defaults to session
  </Plugin::Session>

Then you can use it as usual:

  $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::MongoDB> is a session storage plugin using
MongoDB (L<http://www.mongodb.org>) as its backend.

=head1 CONFIGURATION

=over 4

=item client_options

Options passed to MongoDB::MongoClient->new().  If a reference to an
empty hash is provided, lets MongoDB::MongoClient use its own defaults.

If left unspecified, defaults to the following for compatibility with
previous versions of this module:

  {
    host => $self->hostname,
    port => $self->port
  }

=item dbname

Name of the database in which to store session data.  Defaults to catalyst.

=item collectioname

Name of the collection in which to store session data.  Defaults to session.

=item hostname, port

B<Deprecated>: use client_options instead.  Default to localhost and
27017, when used as default for an unspecified client_options for
compatibility with previous versions of this module.

=back

=head1 USAGE

See L<Catalyst::Plugin::Session> and L<Catalyst::Plugin::Session::Store>.

=over 4

=item B<Expired Sessions>

When getting session data, this store automatically deletes the
session if it has expired.  Additionally this store implements the
optional delete_expired_sessions() method.

=back

=head1 AUTHORS

Ronald J Kimball, <rjk@tamias.net>

Stefan Völkel, <bd@bc-bd.org> <http://bc-bd.org>

Cory G Watson, <gphat at cpan.org>

=head1 LICENSE

Copyright 2010 Stefan Völkel <bd@bc-bd.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License v2 or (at your
option) any later version, as published by the Free Software
Foundation; or the Artistic License.

=cut
