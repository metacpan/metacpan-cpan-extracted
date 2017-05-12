package DBIx::ObjectMapper::Mapper::Attribute::Array;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use base qw(DBIx::ObjectMapper::Mapper::Attribute);
use DBIx::ObjectMapper::Mapper::Attribute::Property;

sub init {
    my $self = shift;

    my @attributes = $self->_init_attributes();
    my %settle_attribute;

    my @properties;
    if( @{$self->properties} ) {
        for my $prop ( @{$self->properties} ) {
            my $isa = $prop->{isa} || confess "Please set \"isa\" propertiy. ";
            my $name
                = delete $prop->{name}
                || $isa->name
                || confess "name is not defined.";
            $isa->name($name);

            $prop->{getter} ||= $self->prefix . $isa->name;
            $prop->{setter} ||= $self->prefix . $isa->name;
            push @properties,
                DBIx::ObjectMapper::Mapper::Attribute::Property->new(%$prop);
            $settle_attribute{ $isa->name } = 1;
        }
    }
    else {
        for my $attr ( @attributes ) {
            $settle_attribute{ $attr->name } = 1;
            push @properties,
                DBIx::ObjectMapper::Mapper::Attribute::Property->new(
                    isa    => $attr,
                    getter => $self->prefix . $attr->name,
                    setter => $self->prefix . $attr->name,
                );
        }
    }

    confess "primary key must be included in property"
        if List::MoreUtils::notall { $settle_attribute{$_} }
        @{ $self->table->primary_key };

    $self->{properties} = \@properties;
}

sub property_names { map { $_->name } @{ $_[0]->properties } }

sub property_info {
    my ($self, $name) = @_;
    for( @{ $self->properties } ) {
        return $_ if $_->name eq $name;
    }
    return;
}

1;

=head1 NAME

DBIx::ObjectMapper::Mapper::Attribute::Array

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
