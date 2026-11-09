package DBIO::Timestamp;
# ABSTRACT: Automatically set and update timestamp columns

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Base/;

use DateTime::Tiny ();
use Scalar::Util ();


__PACKAGE__->mk_classdata('timestamp_class' => 'DateTime::Tiny');


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


sub prepare_insert {
  my $self = shift;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    my $info = $columns_info->{$col};
    next unless $info->{_timestamp_on_create};
    next if defined $self->get_column($col);
    $self->store_column($col => $self->_timestamp_for_column($info));
  }

  return $self->next::method(@_);
}


sub prepare_update {
  my ($self, $upd) = @_;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    my $info = $columns_info->{$col};
    next unless $info->{_timestamp_on_update};
    delete $upd->{$col} if $upd;
    $self->set_inflated_columns({ $col => $self->_timestamp_for_column($info) });
  }

  return $self->next::method($upd);
}


sub get_timestamp {
  my $self  = shift;
  my $class = $self->timestamp_class;
  $self->ensure_class_loaded($class) unless $class->can('now');
  return $class->now;
}

# Resolve the value to store into a timestamp column. Columns managed by
# InflateColumn::DateTime deflate through the storage datetime formatter
# (format_datetime), which needs a full DateTime object — a DateTime::Tiny
# would break there. For such columns inflate the Tiny to a real DateTime (the
# lazy ->DateTime path, which loads DateTime on demand) so the deflate behaves
# exactly as a hand-set DateTime would. Every other column keeps the value
# get_timestamp returned as-is.
sub _timestamp_for_column {
  my ($self, $info) = @_;

  my $ts = $self->get_timestamp;

  return $ts->DateTime
    if $info->{_ic_dt_method}
      and Scalar::Util::blessed($ts)
      and $ts->isa('DateTime::Tiny');

  return $ts;
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

version 0.900004

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

See F<t/timestamp_runtime.t> for a runnable example of the auto-population
on insert and update; the column-metadata the helpers install is covered
by F<t/test/10_timestamp_helpers.t>.

=head1 DESCRIPTION

Automatically populates timestamp columns on insert and update. Columns
flagged with C<< set_on_create =E<gt> 1 >> are filled in when a new row
is inserted; columns flagged with C<< set_on_update =E<gt> 1 >> are
refreshed on every update.

Explicit values are respected: create is no-clobber, update always
refreshes.

The timestamp objects are built by L</get_timestamp>, which calls
C<< timestamp_class->now >>. The default L</timestamp_class> is
L<DateTime::Tiny> — a lightweight value class with no compile-time
dependency on the full L<DateTime> distribution. A DateTime::Tiny
stringifies to an ISO 8601 timestamp literal (C<YYYY-MM-DDTHH:MM:SS>) and
can be promoted to a real L<DateTime> on demand via its C<< ->DateTime >>
method (which loads L<DateTime> lazily).

=head2 Choosing full DateTime objects

If you would rather store full L<DateTime> objects, set the class once:

  __PACKAGE__->timestamp_class('DateTime');

=head2 Interoperating with InflateColumn::DateTime

A column may carry both C<Timestamp> and L<DBIO::InflateColumn::DateTime>.
InflateColumn::DateTime deflates the column through the storage datetime
formatter (C<format_datetime>), which requires a full L<DateTime> object.
For any column it manages, C<Timestamp> therefore inflates a default
DateTime::Tiny to a real L<DateTime> automatically before storing it, so the
combination behaves exactly as it would with a hand-set L<DateTime>. You do
not need to set L</timestamp_class> for that case; it only affects columns
without InflateColumn::DateTime.

=head1 METHODS

=head2 timestamp_class

  __PACKAGE__->timestamp_class('DateTime');   # opt into full DateTime

Class-data accessor naming the class whose C<< ->now >> constructor
L</get_timestamp> calls. Defaults to L<DateTime::Tiny>, a lightweight
timestamp value class that carries no compile-time dependency on the full
L<DateTime> stack. Set it in your Result class (or a shared base class) to
any class exposing a C<now> constructor — e.g. C<'DateTime'> to get full
L<DateTime> objects. The named class is loaded on demand.

=head2 add_columns

Component override: translates the C<set_on_create> / C<set_on_update>
column-info flags into the internal C<_timestamp_on_create> /
C<_timestamp_on_update> markers L</prepare_insert> and L</prepare_update> read, then
delegates to C<next::method>. Called the same way as the plain
C<add_columns>; not normally called directly.

=head2 prepare_insert

Component override of L<DBIO::Row/prepare_insert>: fills every
C<set_on_create> column that has no value already set with a fresh
L</get_timestamp>, then delegates to C<next::method>. Called by C<insert> and
C<insert_async> alike; not normally called directly.

=head2 prepare_update

Component override of L<DBIO::Row/prepare_update>: refreshes every
C<set_on_update> column with a fresh L</get_timestamp> (unconditionally,
unlike L</prepare_insert>'s no-clobber rule), then delegates to
C<next::method>. A value for such a column in the update hashref is dropped:
the timestamp wins. Called by C<update> and C<update_async> alike; not
normally called directly.

=head2 get_timestamp

Returns the current-time object used to populate timestamp columns, built
as C<< $self->timestamp_class->now >> — a L<DateTime::Tiny> by default. Set
L</timestamp_class> to change the class, or override this method entirely in
your Result class for full control (e.g. to force a specific timezone).

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

Returns the current-time object (C<< timestamp_class->now >>) used to fill
timestamp columns. Override in your Result class to customize, e.g. to set a
specific timezone; or set L</timestamp_class> to swap the class without
overriding the method.

=item C<timestamp_class>

Class-data accessor naming the class whose C<< ->now >> constructor
L</get_timestamp> uses. Defaults to L<DateTime::Tiny>; set to C<'DateTime'>
(or any class exposing C<now>) to change it.

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
