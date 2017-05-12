package DBIx::Class::ResultSet::Faceter::Facet::Column;
use Moose;

with 'DBIx::Class::ResultSet::Faceter::Facet';

=head1 NAME

DBIx::Class::ResultSet::Faceter::Facet::Column - Simple faceting on a column

=head1 SYNOPSIS

  $faceter->add_facet('Column', {
	name => 'Last Name', column => 'name_last'
  });
  
  # or
  
  $faceter->add_facet('Date Created', {
	name => 'Last Name', column => 'date_created.ymd'
  });

=head1 DESCRIPTION

Returns the value of the specified column.  Used in situations where the facet
desired in the unmodified value of a column.

=head1 ATTRIBUTES

=head2 column

The name of the column to facet on.  If the name contains dots then it is split
and each method is invoked on the value of the previous invocation.  In other
words if the column name is C<owner.identity.name> then the result will be
the same as C<$row->owner->identity->name>.  This is suitable for both
DBIx::Class relationships and for columns that return objects, such as a
DateTime.

=cut

has 'column' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=head1 METHODS

=head2 process

Returns the name of the specified column.

=cut

sub process {
    my ($self, $row) = @_;

    my $column = $self->column;

    my @calls = ( $column );
    # If there is a dot in the name (e.g. foo.bar) then create a list.
    if($column =~ /\./) {
        @calls = split(/\./, $column);
    }

    my $val = $row;
    foreach my $col (@calls) {
        $val = $val->$col;
    }
    return $val;
}

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;