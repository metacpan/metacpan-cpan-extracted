package DBIx::Class::ResultClass::TrackColumns;

our $VERSION = '0.001002';
 
use strict;
use warnings; 
use parent 'DBIx::Class';

__PACKAGE__->mk_classdata('_storage_tracked_columns');

sub _track_storage_value {
  my ($self, $col) = @_;
  return 1 if $self->next::method($col);
  return 0 unless $self->_storage_tracked_columns;
  return $self->_storage_tracked_columns->{$col} ? 1:0;
}

sub register_column {
  my ($self, $column, $info, @rest) = @_;
  if(delete $info->{track_storage}) {
    $self->_storage_tracked_columns({
      %{ $self->_storage_tracked_columns || {} },
      $column => 1,
    });
  }
  return $self->next::method($column, $info, @rest);
}

sub get_column_storage {
  my ($self, $col) = @_;
  return $self->{_column_data_in_storage}{$col} || '';
}

1;

=head1 NAME

DBIx::Class::ResultClass::TrackColumns - track changed columns

=head1 SYNOPSIS

    package Example::Schema::Result;

    use strict;
    use warnings;

    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/
      ResultClass::TrackColumns
      Core
    /);

    package Example::Schema::Result::Todo;

    use warnings;
    use strict;

    use base 'Example::Schema::Result';

    __PACKAGE__->table("todo");
    __PACKAGE__->add_columns(
      id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },  
      title => { data_type => 'varchar', is_nullable => 0, size => 60 },
      status => { data_type => 'varchar', is_nullable => 0, default=>'active', size => 60, track_storage => 1},
    );

Now the column 'status' is tracked such that if you change it we preserve the original
loaded from storage value until you persist the row.

=head1 DESCRIPTION

Allows you to preserve the original value of a column as it was loaded from storage
if you change it (via ->set_column, for example) but haven't saved the change to storage
yet.  I wrote this because for the L<Valiant> DBIC glue (L<DBIx::Class::Valiant>) you
sometimes want the original storage value for doing certain types of constraints (for
example you might have a status field which accepts an enum but there's rules about
which states you can set based on the existing state).

=head1 METHODS

This component defines the following public methods

=head2 get_column_storage

    my $old = $row->get_column_storage($column);

If a column has been changed since you loaded it from storage but has not yet been persisted you
can get the original value using this method, if the column is marked as 'tracked'.

=head1 SEE ALSO
 
L<DBIx::Class>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 COPYRIGHT & LICENSE
 
Copyright 2022, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
