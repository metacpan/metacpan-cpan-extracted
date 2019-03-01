# Data::Hopen::G::Entity - base class for hopen's data model
package Data::Hopen::G::Entity;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000012';

sub name;

use Class::Tiny qw(name);

=head1 NAME

Data::Hopen::G::Entity - The base class for all hopen nodes and edges

=head1 SYNOPSIS

hopen creates and manages a graph of entities: nodes and edges.  This class
holds common information.

=head1 MEMBERS

=head2 name

The name of this entity.  The name is for human consumption and is not used by
hopen to make any decisions.  However, node names starting with an underscore
are reserved for hopen's internal use.

The name C<'0'> (a single digit zero) is forbidden (since it's falsy).

=cut

=head1 FUNCTIONS

=head2 name

A custom accessor for name.  If no name has been stored, return the stringifed
version of the entity.  That way every entity always has a name.

=cut

sub name {
    my $self = shift or croak 'Need an instance';
    if (@_) {                               # Setter
        return $self->{name} = shift;
    } elsif ( exists $self->{name} ) {      # Getter
        return $self->{name};
    } else {                                # Default
        return "$self";
    }
} #name()

=head2 has_custom_name

Returns truthy if a name has been set using L</name>.

=cut

sub has_custom_name { !!(shift)->{name} }

1;
__END__
# vi: set fdm=marker: #
