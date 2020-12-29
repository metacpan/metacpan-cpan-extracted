# Data::Hopen::G::Entity - base class for hopen's data model
package Data::Hopen::G::Entity;
use Data::Hopen;
use strict;
use Data::Hopen::Base;

use overload;
use Scalar::Util qw(refaddr);

our $VERSION = '0.000019';

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
    croak 'Need an instance' unless ref $_[0];
        # Note: avoiding `shift` since I've had problems with that in the past
        # in classes that overload stringification.

    if (@_>1) {                             # Setter
        croak "Name `$_[1]' is disallowed" unless !!$_[1];  # no falsy names
        return $_[0]->{name} = $_[1];
    } elsif ( $_[0]->{name} ) {             # Getter
        return $_[0]->{name};
    } else {                                # Default
        return overload::StrVal($_[0]);
    }
} #name()

=head2 has_custom_name

Returns truthy if a name has been set using L</name>.

=cut

sub has_custom_name { !!($_[0]->{name}) }

=head2 Stringification

Stringifies to the name plus, if the name is custom, the refaddr.

=cut

sub _stringify {
    $_[0]->has_custom_name ?
        sprintf("%s (%x)", $_[0]->{name}, refaddr $_[0]) :
        overload::StrVal($_[0]);
} #_stringify

use overload fallback => 1,
    '""' => \&_stringify;

1;
__END__
# vi: set fdm=marker: #
