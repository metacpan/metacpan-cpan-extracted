package DBIO::Timestamp;
# ABSTRACT: Automatically set and update timestamp columns

use strict;
use warnings;
use DateTime;

sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (delete $info->{set_on_create}) {
      $info->{_timestamp_on_create} = 1;
    }

    if (delete $info->{set_on_update}) {
      $info->{_timestamp_on_update} = 1;
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}

sub insert {
  my $self = shift;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    next unless $columns_info->{$col}{_timestamp_on_create};
    next if defined $self->get_column($col);
    $self->store_column($col => $self->get_timestamp);
  }

  return $self->next::method(@_);
}

sub update {
  my $self = shift;
  my $upd  = shift;

  $self->set_inflated_columns($upd) if $upd;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    next unless $columns_info->{$col}{_timestamp_on_update};
    $self->set_inflated_columns({ $col => $self->get_timestamp });
  }

  return $self->next::method(@_);
}


sub get_timestamp {
  return DateTime->now;
}


sub col_created {
  my ($self, $name) = @_;
  $name ||= 'created_at';
  $self->add_columns($name => {
    data_type     => 'timestamp',
    set_on_create => 1,
    is_nullable   => 0,
  });
}


sub col_updated {
  my ($self, $name) = @_;
  $name ||= 'updated_at';
  $self->add_columns($name => {
    data_type     => 'timestamp',
    set_on_create => 1,
    set_on_update => 1,
    is_nullable   => 0,
  });
}


sub cols_updated_created {
  my ($self) = @_;
  $self->col_created;
  $self->col_updated;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Timestamp - Automatically set and update timestamp columns

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  package MyApp::Schema::Result::Article;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Timestamp/);
  __PACKAGE__->table('article');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer',  is_auto_increment => 1 },
    title      => { data_type => 'varchar',  size => 255 },
    created_at => { data_type => 'datetime', set_on_create => 1 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );
  __PACKAGE__->set_primary_key('id');

Or use the helpers to declare both standard columns in one go:

  __PACKAGE__->cols_updated_created;

=head1 DESCRIPTION

Automatically populates timestamp columns on insert and update. Columns
flagged with C<< set_on_create =E<gt> 1 >> are filled in when a new row
is inserted; columns flagged with C<< set_on_update =E<gt> 1 >> are
refreshed on every update.

Explicit values are respected: create is no-clobber, update always
refreshes.

=head1 METHODS

=head2 get_timestamp

Returns a L<DateTime> object for the current time. Override this in your
Result class to customize (e.g. set a specific timezone).

=head2 col_created

  __PACKAGE__->col_created;              # creates 'created_at'
  __PACKAGE__->col_created('born_at');   # custom name

Adds a NOT NULL timestamp column with C<set_on_create>.

=head2 col_updated

  __PACKAGE__->col_updated;                # creates 'updated_at'
  __PACKAGE__->col_updated('modified_at'); # custom name

Adds a NOT NULL timestamp column with C<set_on_create> and C<set_on_update>.

=head2 cols_updated_created

  __PACKAGE__->cols_updated_created;

Adds both C<created_at> and C<updated_at> columns in one call.

=head1 COLUMN FLAGS

=over 4

=item C<< set_on_create =E<gt> 1 >>

The column receives a fresh timestamp on insert if no value was supplied.

=item C<< set_on_update =E<gt> 1 >>

The column is refreshed on every update.

=back

=head1 HELPER METHODS

=over 4

=item C<col_created($name)>

Adds a C<set_on_create> timestamp column. Default name: C<created_at>.

=item C<col_updated($name)>

Adds a column with both C<set_on_create> and C<set_on_update>. Default
name: C<updated_at>.

=item C<cols_updated_created>

Adds both standard columns in one call.

=back

=head1 OVERRIDABLE METHODS

=over 4

=item C<get_timestamp>

Returns a L<DateTime> object for the current time. Override in your
Result class to customize, e.g. to set a specific timezone.

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
