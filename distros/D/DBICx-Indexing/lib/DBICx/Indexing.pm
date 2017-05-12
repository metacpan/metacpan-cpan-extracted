package DBICx::Indexing;
our $VERSION = '0.002';

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata('_dbicx_indexing');

sub indices {
  my $class = shift;

  if (@_) {
    my $idxs;
    if   (scalar(@_) == 1) { $idxs = $_[0] }
    else                   { $idxs = {@_} }

    for my $cols (values %$idxs) {
      $cols = [$cols] unless ref $cols eq 'ARRAY';
    }

    $class->_dbicx_indexing($idxs);
  }

  return $class->_dbicx_indexing;
}

sub sqlt_deploy_hook {
  my $self = shift;
  my ($table) = @_;

  $self->next::method(@_) if $self->next::can;

  my $indexes = $self->_dbicx_indexing;
  for my $name (keys %$indexes) {
    my $cols = $indexes->{$name};

    next if _has_cover_index($table, $cols);

    $table->add_index(name => $name, fields => $cols);
  }
}

sub _has_cover_index {
  my ($table, $cols) = @_;

  my @idxs;
  push @idxs, map { [$_->fields] } $table->get_indices;
  push @idxs, map { [$_->field_names] } $table->unique_constraints;
  push @idxs, [$table->primary_key->field_names];

IDXS: for my $flst (@idxs) {
    for my $c (@$cols) {
      next IDXS unless @$flst;
      next IDXS unless $flst->[0] eq $c;

      shift @$flst;
    }

    return 1;
  }

  return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

DBICx::Indexing - Easy way do declare extra indices to your tables


=head1 VERSION

version 0.002

=head1 SYNOPSIS

  package My::App::Schema::Result::Table;
  
  use strict;
  use warnings;
  use bsae 'DBIx::Class';
  
  ## include the DBICx::Indexing component
  __PACKAGE__->load_components('+DBICx::Indexing', 'Core');
  
  ## declare your table, fields, primary key, and unique constraints
  
  ## declare your extra indices
  __PACKAGE__->indices(
    important_field_idx => 'date_added',
    another_idx         => ['type', 'date_modified'],
  );


=head1 DESCRIPTION

Sometimes you need some extra indices on your tables. With
L<DBIx::Class|DBIx::Class> there is no easy way to declare them. The
appropriate cookbook entry is
L<DBIx::Class::Manual::Cookbook/Adding Indexes And Functions To Your SQL>.

This component makes the process easier with some extra niceties.

In the source that needs extra indices, just call L<indices()> with a
hashref describing them.

The keys are the indices names, and the value for each key is the list
of fields included in the index.


=head2 Covering indexes

If you specify an index specification that is already covered by any of
the automatic indices created by the database (primary keys, unique
constraints, or even other indices created manually via a per-source
C<sqlt_deploy_hook()>), then we will not create another index.

For example, if your table has 8 columns, C<a> through C<h>, with the
following constraints:

=over 4

=item * primary key: C<a>, C<b>, C<c>

=item * unique constraint: C<d>

=item * extra index: C<e>, C<f>

=back

With that constraints, if you ask for these indices, you'll get these replies:

=over 4

=item C<idx1> for C<a>

This index will be ignored, covered by the primary key.

=item C<idx2> for C<a>, C<c>

This index will be created, it is not covered by any of the other
indices. The C<a> is covered by the primary key, but not the C<c>, not
in that order.

=item C<idx3> for C<d>, C<a>

This index will be created, it is not covered by any of the other
indices. The unique constraint covers the C<d> column, but not the C<a>.

=item C<idx4>  for C<e>, C<f>

Ignored, covered by the extra index.

=back


=head2 Per-source sqlt_deploy_hook()

If you need to define a C<sqlt_deploy_hook()> for a specific source,
make sure that your code calls the next C<sqlt_deploy_hook()> in turn.

You own C<sqlt_deploy_hook()> should look something like this:

    sub sqlt_deploy_hook {
      my $self = shift;
      my ($table) = @_;
      
      ... your code goes here ...
      
      $self->next::method(@_) if $self->next::can;
    }


=head1 METHODS

=head2 indices()

    package My::Schema::Results::MySource;
    
    __PACKAGE__->load_components('+DBICx::Indexing', 'Core');
    ... rest of source initialization here...
    __PACKAGE__->indices({
      idx1 => ['field1', 'field2'],
      idx2 => 'field3',
    });

The L<indices()> method accepts a hashref (or a hash) with the list of
indices to create. The keys will be used as the index name. The values
are the list of fields that each index will cover.

If the field list is only one element, you can just use a single scalar
(like the C<idx2> index in the example above).


=head1 SEE ALSO

L<DBIx::Class>, L<SQL::Translator>


=head1 AUTHOR

Pedro Melo, C<< <melo@simplicidade.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2010 Pedro Melo

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut