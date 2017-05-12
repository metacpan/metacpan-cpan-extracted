package DBIx::ObjectMapper::Mapper::Attribute::Hash;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use base qw(DBIx::ObjectMapper::Mapper::Attribute);
use DBIx::ObjectMapper::Mapper::Attribute::Property;

sub init {
    my $self = shift;

    my $table = $self->table;
    my @attributes = $self->_init_attributes();

    my %properties;
    my %settle_property;

    for my $name ( keys %{ $self->properties } ) {
        my $isa
            = $self->properties->{$name}{isa}
                || $table->c($name)
                || confess "$name : column not found. set property \"isa\". ";

        $self->properties->{$name}{getter} ||= $self->prefix . $name;
        $self->properties->{$name}{setter} ||= $self->prefix . $name;

        if( ref($isa) eq 'DBIx::ObjectMapper::Metadata::Table::Column' ) {
            $settle_property{ $isa->name } = 1;
        }
        else {
            $isa->name($name);
        }

        $self->properties->{$name}{isa} = $isa;

        $properties{$name}
            = DBIx::ObjectMapper::Mapper::Attribute::Property->new(
            %{ $self->properties->{$name} }
        );
    }

    for my $attr (@attributes) {
        next if $settle_property{ $attr->name };
        $properties{ $attr->name }
            = DBIx::ObjectMapper::Mapper::Attribute::Property->new(
            isa    => $attr,
            getter => $self->prefix . $attr->name,
            setter => $self->prefix . $attr->name,
            );
        $settle_property{ $attr->name } = 1;
    }

    if ( $self->prefix ) {
        %properties = map { $self->prefix . $_ => $properties{$_} }
            keys %properties;
    }

    $self->{properties} = \%properties;
}

sub property_names { keys %{ $_[0]->{properties} } }
sub property_info  { $_[0]->{properties}->{ $_[1] } }

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Mapper::Attribute::Hash

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

