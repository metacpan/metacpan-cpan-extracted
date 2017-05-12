package CQL::Prefix;

use strict;
use warnings;
use Carp qw( croak );

=head1 NAME

CQL::Prefix - represents a CQL prefix mapping

=head1 SYNOPSIS

    use CQL::Prefix;

=head1 DESCRIPTION

Represents a CQL prefix mapping from short name to long identifier.

=head1 METHODS

=head2 new()

You need to pass in the name and identifier parameters. 

The name is the short name of the prefix mapping. That is, the prefix
itself, such as dc, as it might be used in a qualifier like dc.title.

The identifier is the name of the prefix mapping.  That is,
typically, a URI permanently allocated to a specific qualifier
set, such as http://zthes.z3950.org/cql/1.0.

    my $prefix = CQL::Prefix->new(
        name        => 'dc',
        identifier  => 'http://zthes.z3950.org/cql/1.0'
    );
              
=cut

sub new {
    my ($class,%opts) = @_;
    croak( 'must supply name' ) if ! exists $opts{name};
    croak( 'must supply identifier' ) if ! exists $opts{identifier};
    my $self = { name => $opts{name}, identifier => $opts{identifier} };
    return bless $self, ref($class) || $class;
}

=head2 getName()

=cut

sub getName {
    return shift->{name};
}

=head2 getIdentifier()

=cut

sub getIdentifier {
    return shift->{identifier};
}

1;
