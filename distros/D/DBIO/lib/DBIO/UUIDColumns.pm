package DBIO::UUIDColumns;
# ABSTRACT: Automatically populate UUID columns on insert

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Base/;
use Crypt::URandom ();
use DBIO::Util ();

__PACKAGE__->mk_classdata('uuid_maker');
__PACKAGE__->uuid_maker(__PACKAGE__);


sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (delete $info->{uuid_on_create}) {
      $info->{_uuid_on_create} = 1;
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}


sub prepare_insert {
  my $self = shift;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    next unless $columns_info->{$col}{_uuid_on_create};
    next if defined $self->get_column($col);
    $self->store_column($col => $self->get_uuid);
  }

  return $self->next::method(@_);
}


sub uuid_class {
  my ($self, $class) = @_;
  if ($class) {
    DBIO::Util::assert_class_name($class);
    if (!eval "require $class; 1") {
      $self->throw_exception("$class could not be loaded: $@");
    }
    $self->uuid_maker($class);
  }
  return $self->uuid_maker;
}


sub get_uuid {
  my $self = shift;
  my $class = $self->uuid_maker;
  if ($class eq __PACKAGE__) {
    return generate_uuid_v4();
  } elsif ($class eq 'Data::UUID') {
    return Data::UUID->new->create_str;
  } elsif ($class eq 'UUID') {
    my ($uuid, $string);
    UUID::generate($uuid);
    UUID::unparse($uuid, $string);
    return $string;
  } else {
    return $class->new->as_string;
  }
}


sub generate_uuid_v4 {
  my @b = unpack 'C16', Crypt::URandom::urandom(16);
  $b[6] = ($b[6] & 0x0f) | 0x40;
  $b[8] = ($b[8] & 0x3f) | 0x80;
  return sprintf '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x', @b;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::UUIDColumns - Automatically populate UUID columns on insert

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/UUIDColumns/);
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    artist_id => { data_type => 'varchar', size => 36, uuid_on_create => 1 },
    name      => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('artist_id');

See F<t/uuid_columns.t> for a runnable example.

=head1 DESCRIPTION

Automatically populates columns flagged with C<< uuid_on_create =E<gt> 1 >>
with a freshly generated UUID on insert. Existing values are respected --
only undefined columns receive a generated UUID.

The generator backend is selected per class via L</uuid_class>. By
default the component generates version 4 UUIDs itself from
L<Crypt::URandom>: random, hard to guess, and needing no further module.
C<< uuid_class('Data::UUID') >> or C<< uuid_class('UUID') >> selects one of
those backends explicitly.

The default values are random and not guessable, but they are identifiers,
not secrets, and they do not sort by creation time. A database that
generates UUIDs itself (for example PostgreSQL's C<gen_random_uuid()> as a
column default, see L<DBIO::PostgreSQL>) is the server-side route; this
component is the client-side one.

Based on L<DBIx::Class::UUIDColumns> by Chia-liang Kao and Chris Laco.

=head1 METHODS

=head2 add_columns

Component override: translates the C<uuid_on_create> column-info flag into
the internal C<_uuid_on_create> marker L</prepare_insert> reads, then delegates to
C<next::method>. Called the same way as the plain C<add_columns>; not
normally called directly.

=head2 prepare_insert

Component override of L<DBIO::Row/prepare_insert>: fills every
C<uuid_on_create> column that has no value already set with a fresh
L</get_uuid>, then delegates to C<next::method>. Called by C<insert> and
C<insert_async> alike; not normally called directly.

=head2 uuid_class

  __PACKAGE__->uuid_class('Data::UUID');

Class-level accessor. Selects the UUID generator backend. The default is
this component's own generator (L</generate_uuid_v4>); C<Data::UUID> and
C<UUID> are chosen by naming them explicitly.

=head2 get_uuid

Returns one freshly generated UUID string from the configured backend.
Override this in your Result class to customize.

=head2 generate_uuid_v4

  my $uuid = DBIO::UUIDColumns::generate_uuid_v4();

Package function. Returns a version 4 UUID in canonical lowercase form
(C<xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx>, C<y> one of C<8 9 a b>), built
from 16 bytes of L<Crypt::URandom> with the version and variant bits set.

=head1 COLUMN FLAGS

=over 4

=item C<< uuid_on_create =E<gt> 1 >>

The column receives a freshly generated UUID on insert if no value was
supplied.

=back

=head1 OVERRIDABLE METHODS

=over 4

=item C<get_uuid>

Returns one freshly generated UUID string from the configured backend.
Override in your Result class to customize.

=item C<uuid_class($class)>

Class-level accessor for the generator backend. Pass a class name to
switch backend (e.g. C<'Data::UUID'>).

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
