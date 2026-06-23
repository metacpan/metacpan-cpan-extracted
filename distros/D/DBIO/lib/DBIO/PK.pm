package DBIO::PK;
# ABSTRACT: Primary Key class

use strict;
use warnings;

use base qw/DBIO::Row/;



sub id {
  my ($self) = @_;
  $self->throw_exception( "Can't call id() as a class method" )
    unless ref $self;
  my @id_vals = $self->_ident_values;
  return (wantarray ? @id_vals : $id_vals[0]);
}


sub _ident_values {
  my ($self, $use_storage_state) = @_;

  my (@ids, @missing);

  for ($self->result_source->_pri_cols_or_die) {
    push @ids, ($use_storage_state and exists $self->{_column_data_in_storage}{$_})
      ? $self->{_column_data_in_storage}{$_}
      : $self->get_column($_)
    ;
    push @missing, $_ if (! defined $ids[-1] and ! $self->has_column_loaded ($_) );
  }

  if (@missing && $self->in_storage) {
    $self->throw_exception (
      'Unable to uniquely identify result object with missing PK columns: '
      . join (', ', @missing )
    );
  }

  return @ids;
}


sub ID {
  my ($self) = @_;
  $self->throw_exception( "Can't call ID() as a class method" )
    unless ref $self;
  return undef unless $self->in_storage;
  return $self->_create_ID(%{$self->ident_condition});
}


sub _create_ID {
  my ($self, %vals) = @_;
  return undef if grep { !defined } values %vals;
  return join '|', ref $self || $self, $self->result_source->name,
    map { $_ . '=' . $vals{$_} } sort keys %vals;
}


sub ident_condition {
  shift->_mk_ident_cond(@_);
}


sub _storage_ident_condition {
  shift->_mk_ident_cond(shift, 1);
}


sub _mk_ident_cond {
  my ($self, $alias, $use_storage_state) = @_;

  my @pks = $self->result_source->_pri_cols_or_die;
  my @vals = $self->_ident_values($use_storage_state);

  my (%cond, @undef);
  my $prefix = defined $alias ? $alias.'.' : '';
  for my $col (@pks) {
    if (! defined ($cond{$prefix.$col} = shift @vals) ) {
      push @undef, $col;
    }
  }

  if (@undef && $self->in_storage) {
    $self->throw_exception (
      'Unable to construct result object identity condition due to NULL PK columns: '
      . join (', ', @undef)
    );
  }

  return \%cond;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PK - Primary Key class

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

=head1 DESCRIPTION

This class contains methods for handling primary keys and methods
depending on them.

=head1 METHODS

=head2 id

Returns the primary key(s) for a row. Can't be called as
a class method.

=head2 _ident_values

Internal helper returning primary-key values (optionally from in-storage state).

=head2 ID

Returns a unique id string identifying a result object by primary key.

=over

=item WARNING

The default C<_create_ID> method used by this function orders the returned
values by the alphabetical order of the primary column names, B<unlike>
the L</id> method, which follows the same order in which columns were fed
to L<DBIO::ResultSource/set_primary_key>.

=back

=head2 _create_ID

Internal formatter producing a unique identity string for a result object.

=head2 ident_condition

  my $cond = $result_source->ident_condition();

  my $cond = $result_source->ident_condition('alias');

Produces a condition hash to locate a row based on the primary key(s).

=head2 _storage_ident_condition

Internal variant of C<ident_condition> using in-storage PK values.

=head2 _mk_ident_cond

Internal builder for primary-key based condition hashes.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
