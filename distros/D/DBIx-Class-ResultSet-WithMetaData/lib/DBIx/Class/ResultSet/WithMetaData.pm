package DBIx::Class::ResultSet::WithMetaData;

use strict;
use warnings;

use Data::Alias;
use Moose;
use Method::Signatures::Simple;
extends 'DBIx::Class::ResultSet';

has '_row_info' => (
  is => 'rw',
  isa => 'HashRef'
);

has 'was_row' => (
  is => 'rw',
  isa => 'Int'
);

has 'id_cols' => (
  is => 'rw',
  isa => 'ArrayRef',
);

has '_hash_modifiers' => (
  is => 'rw',
  isa => 'ArrayRef',
);

has '_key_modifiers' => (
  is => 'rw',
  isa => 'ArrayRef',
);

has '_object_hash_modifiers' => (
  is => 'rw',
  isa => 'ArrayRef',
);

has '_object_key_modifiers' => (
  is => 'rw',
  isa => 'ArrayRef',
);

=head1 VERSION

Version 1.001000

=cut

our $VERSION = '1.001000';

=head1 NAME

DBIx::Class::ResultSet::WithMetaData

=head1 SYNOPSIS

  package MyApp::Schema::ResultSet::ObjectType;

  use Moose;
  use MooseX::Method::Signatures;
  extends 'DBIx::Class::ResultSet::WithMetaData;

  method with_substr () {
    return $self->_with_meta_key( 
      substr => sub {
        return substr(shift->{name}, 0, 3);
      }
    );
  }

  ...


  # then somewhere else

  my $object_type_arrayref = $object_type_rs->with_substr->display();

  # [{
  #    'artistid' => '1',
  #    'name' => 'Caterwauler McCrae',
  #    'substr' => 'Cat'
  #  },
  #  {
  #    'artistid' => '2',
  #    'name' => 'Random Boy Band',
  #    'substr' => 'Ran'
  #  },
  #  {
  #    'artistid' => '3',
  #    'name' => 'We Are Goth',
  #    'substr' => 'We '
  #  }]

=head1 DESCRIPTION

Attach metadata to rows by chaining ResultSet methods together. When the ResultSet is
flattened to an ArrayRef the metadata is merged with the row hashes to give
a combined 'hash-plus-other-stuff' representation.

=head1 METHODS

=cut

sub new {
  my $self = shift;

  my $new = $self->next::method(@_);
  foreach my $key (qw/_row_info was_row id_cols _key_modifiers _hash_modifiers _object_key_modifiers _object_hash_modifiers/) {
    alias $new->{$key} = $new->{attrs}{$key};
  }

  unless ($new->_row_info) {
    $new->_row_info({});
  }

  unless ($new->_key_modifiers) {
    $new->_key_modifiers([]);
  }
  unless ($new->_hash_modifiers) {
    $new->_hash_modifiers([]);
  }
  unless ($new->_object_key_modifiers) {
    $new->_object_key_modifiers([]);
  }
  unless ($new->_object_hash_modifiers) {
    $new->_object_hash_modifiers([]);
  }

  unless ($new->id_cols && scalar(@{$new->id_cols})) {
    $new->id_cols([sort $new->result_source->primary_columns]);
  }

  return $new;
}

=head2 display

=over 4

=item Arguments: none

=item Return Value: ArrayRef

=back

 $arrayref_of_row_hashrefs = $rs->display();

This method uses L<DBIx::Class::ResultClass::HashRefInflator> to convert all
rows in the ResultSet to HashRefs. Then the subrefs that were added via 
L</_with_meta_key> or L</_with_meta_hash> are run for each row and the
resulting data merged with them.

=cut

method display () {
  my $rs = $self->search({});
#  $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
  $rs->result_class('DBIx::Class::WithMetaData::Inflator');
  my @rows;
  foreach my $row_rep ($rs->all) {
    # the custom inflator inflates to a arrayref with two versions of the row in it - hash and obj
    my ($row, $row_obj) = @{$row_rep};
    # THIS BLOCK IS DEPRECATED
    if (my $info = $self->row_info_for(id => $self->_mk_id(row => $row))) {
      $row = { %{$row}, %{$info} };
    }

    foreach my $modifier (@{$rs->_hash_modifiers}) {
      my $row_hash = $modifier->($row);
      if (ref $row_hash ne 'HASH') {
        die 'modifier subref (added via build_metadata) did not return hashref';
      }

      # simple merge for now, potentially needs to be more complex
      $row->{$_} = $row_hash->{$_} for keys %{$row_hash};
    }

    foreach my $modifier (@{$rs->_object_hash_modifiers}) {
      my $row_hash = $modifier->($row, $row_obj);
      if (ref $row_hash ne 'HASH') {
        die 'modifier subref (added via build_metadata) did not return hashref';
      }

      # simple merge for now, potentially needs to be more complex
      $row->{$_} = $row_hash->{$_} for keys %{$row_hash};
    }

    foreach my $params (@{$rs->_key_modifiers}) {
      my $modifier = $params->{modifier};
      my $key = $params->{key};

      if (my $val = $modifier->($row)) {
        $row->{$key} = $val;
      }
    }

    foreach my $params (@{$rs->_object_key_modifiers}) {
      my $modifier = $params->{modifier};
      my $key = $params->{key};

      if (my $val = $modifier->($row, $row_obj)) {
        $row->{$key} = $val;
      }
    }
    push(@rows, $row);
  }

  return ($self->was_row) ? $rows[0] : \@rows;
}

=head2 _with_meta_key

=over 4

=item Arguments: key_name => subref($row_hash)

=item Return Value: ResultSet

=back

 $self->_with_meta_key( substr => sub ($row) { 
   return substr(shift->{name}, 0, 3);
 });

This method allows you populate a certain key for each row hash at  L</display> time.

=cut

method _with_meta_key ($key, $modifier) {
  my $rs = $self->search({});
  unless ($key) {
    die 'build_metadata called without key';
  }

  unless ($modifier && (ref $modifier eq 'CODE')) {
    die 'build_metadata called without modifier param';
  }

  push( @{$rs->_key_modifiers}, { key => $key, modifier => $modifier });
  return $rs;
}

=head2 _with_object_meta_key

=over 4

=item Arguments: key_name => subref($row_hash, $row_obj)

=item Return Value: ResultSet

=back

 $self->_with_object_meta_key( substr => sub { 
   my ($row_hash, $row_obj) = @_;
   return substr($row_obj->row_method, 0, 3);
 });

The same as L</_with_meta_key> but the subref gets the row object
as well as the row hash. This should only be used when you need to
access row methods as it's slower to inflate objects.

=cut

method _with_object_meta_key ($key, $modifier) {
  my $rs = $self->search({});
  unless ($key) {
    die '_with_object_meta_key called without key';
  }

  unless ($modifier && (ref $modifier eq 'CODE')) {
    die '_with_object_meta_key called without modifier param';
  }

  push( @{$rs->_object_key_modifiers}, { key => $key, modifier => $modifier });
  return $rs;
}

=head2 _with_meta_hash

=over 4

=item Arguments: subref($row_hash)

=item Return Value: ResultSet

=back

 $self->_with_meta_hash( sub ($row) { 
   my $row = shift;
   my $return_hash = { substr => substr($row->{name}, 0, 3), substr2 => substr($row->{name}, 0, 4) };
   return $return_hash;
 });

Use this method when you want to populate multiple keys of the hash at the same time. If you just want to 
populate one key, use L</_with_meta_key>.

=cut

method _with_meta_hash ($modifier) {
  my $rs = $self->search({});
  unless ($modifier && (ref $modifier eq 'CODE')) {
    die 'build_metadata called without modifier param';
  }

  push( @{$rs->_hash_modifiers}, $modifier );
  return $rs;
}

=head2 _with_object_meta_hash

=over 4

=item Arguments: subref($row_hash, $row_object)

=item Return Value: ResultSet

=back

 $self->_with_object_meta_hash( sub { 
   my ($row_hash, $row_object) = @_;

   my $return_hash = { substr => substr($row_object->name, 0, 3), substr2 => substr($row_hash->{name}, 0, 4) };
   return $return_hash;
 });

Like L</_with_meta_hash> but the subref gets the row object
as well as the row hash. This should only be used when you need to
access row methods as it's slower to inflate objects.

=cut

method _with_object_meta_hash ($modifier) {
  my $rs = $self->search({});
  unless ($modifier && (ref $modifier eq 'CODE')) {
    die 'build_metadata called without modifier param';
  }

  push( @{$rs->_object_hash_modifiers}, $modifier );
  return $rs;
}

=head2 add_row_info (DEPRECATED)

=over 4

=item Arguments: row => DBIx::Class::Row object, info => HashRef to attach to the row

=item Return Value: ResultSet

=back

 $rs = $rs->add_row_info(row => $row, info => { dates => [qw/mon weds fri/] } );

DEPRECATED - this method is quite slow as it requires that you iterate through 
the resultset each time you want to add metadata. Replaced by L</build_metadata>.

=cut

method add_row_info (%opts) {
  my ($row, $id, $info) = map { $opts{$_} } qw/row id info/;

  warn 'DEPRECATED - add_row_info is deprecated in favour of build_metadata';
  if ($row) {
    $id = $self->_mk_id(row => { $row->get_columns });
  }

  unless ($row || $self->find($id)) {
    die 'invalid id passed to add_row_info';
  }

  if (my $existing = $self->_row_info->{$id}) {
    $info = { %{$existing}, %{$info} };
  }

  $self->_row_info->{$id} = $info;  
}

# DEPRECATED
method row_info_for (%opts) {
  my $id = $opts{id};
  return $self->_row_info->{$id};
}

# DEPRECATED
method _mk_id (%opts) {
  my $row = $opts{row};
  return join('-', map { $row->{$_} } @{$self->id_cols});
}

=head1 AUTHOR

  Luke Saunders <luke.saunders@gmail.com>

=head1 THANKS

As usual, thanks to Matt S Trout for the sanity check.

=head1 LICENSE

  This library is free software under the same license as perl itself

=cut

1;
