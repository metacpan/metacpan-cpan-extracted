package Alzabo::ForeignKey;

use strict;
use vars qw($VERSION);

use Alzabo;


$VERSION = 2.0;

1;

sub table_from
{
    my $self = shift;

    return ($self->columns_from)[0]->table;
}

sub table_to
{
    my $self = shift;

    return ($self->columns_to)[0]->table;
}

sub columns_from
{
    my $self = shift;

    return wantarray ? @{ $self->{columns_from} } : $self->{columns_from}[0];
}

sub columns_to
{
    my $self = shift;

    return wantarray ? @{ $self->{columns_to} } : $self->{columns_to}[0];
}

sub column_pairs
{
    my $self = shift;

    return ( map { [ $self->{columns_from}[$_] => $self->{columns_to}[$_] ] }
	     0..$#{ $self->{columns_from} } );
}

sub column_pair_names
{
    my $self = shift;

    return ( map { [ $self->{columns_from}[$_]->name => $self->{columns_to}[$_]->name ] }
	     0..$#{ $self->{columns_from} } );
}

sub cardinality
{
    my $self = shift;

    return @{ $self->{cardinality} };
}

sub is_one_to_one
{
    my $self = shift;

    my @c = $self->cardinality;

    return $c[0] eq '1' && $c[1] eq '1';
}

sub is_one_to_many
{
    my $self = shift;

    my @c = $self->cardinality;

    return $c[0] eq '1' && $c[1] eq 'n';
}

sub is_many_to_one
{
    my $self = shift;

    my @c = $self->cardinality;

    return $c[0] eq 'n' && $c[1] eq '1';
}

sub from_is_dependent
{
    return shift->{from_is_dependent};
}

sub to_is_dependent
{
    return shift->{to_is_dependent};
}

sub is_same_relationship_as
{
    my ($self, $other) = @_;
    return ( $self->id eq $other->id
             or
             $self->id eq $other->reverse->id
           );
}

sub reverse
{
    my $self = shift;

    return bless { table_from        => $self->table_to,
                   table_to          => $self->table_from,
                   columns_from      => [ $self->columns_to ],
                   columns_to        => [ $self->columns_from ],
                   from_is_dependent => $self->to_is_dependent,
                   to_is_dependent   => $self->from_is_dependent,
                   cardinality       => [ reverse @{ $self->{cardinality} } ],
		 }, ref $self;
}

sub id
{
    my $self = shift;

    return join '___', ( ( map { $_->name }
			   $self->table_from,
			   $self->table_to,
			   $self->columns_from,
			   $self->columns_to,
			 ),
			 $self->cardinality,
			 $self->from_is_dependent,
			 $self->to_is_dependent,
		       );
}

sub comment { $_[0]->{comment} }

__END__

=head1 NAME

Alzabo::ForeignKey - Foreign key (relation) objects

=head1 SYNOPSIS

  use Alzabo::ForeignKey;

  foreach my $fk ($table->foreign_keys)
  {
      print $fk->cardinality;
  }

=head1 DESCRIPTION

A foreign key is an object defined by several properties.  It
represents a relationship from a column or columns in one table to a
column or columns in another table.

This relationship is defined by its cardinality (one to one, one to
many, or many to one) and its dependencies (whether or not table X is
dependent on table Y, and vice versa).

Many to many relationships are not allowed.  However, you may indicate
such a relationship when using the
L<Alzabo::Create::Schema-E<gt>add_relation
method|Alzabo::Create::Schema/add_relation> method, and it will create
the necessary intermediate linking table for you.

=head1 METHODS

=head2 table_from

=head2 table_to

Returns the relevant L<C<Alzabo::Table>|Alzabo::Table> object.

=head2 columns_from

=head2 columns_to

Returns the relevant L<C<Alzabo::Column>|Alzabo::Column> object(s) for
the property as an array.

=head2 column_pairs

Returns an array of array references.  The references are to two
column array of L<C<Alzabo::Column>|Alzabo::Column> objects.  These
two columns correspond in the tables being linked together.

=head2 cardinality

Returns a two element array containing the two portions of the
cardinality of the relationship.  Each portion will be either '1' or
'n'.

=head2 from_is_dependent

=head2 to_is_dependent

Returns a boolean value indicating whether there is a dependency from
one table to the other.

=head2 is_one_to_one

=head2 is_one_to_many

=head2 is_many_to_one

Returns a boolean value indicating what kind of relationship the
object represents.

=head2 is_same_relationship_as ($fk)

Given a foreign key object, this returns true if the two objects
represent the same relationship.  However, the two objects may
represent the same relationship from different table's points of view.

=head2 id

Returns a string uniquely identifying the foreign key.

=head2 comment

Returns the comment associated with the foreign key object, if any.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
