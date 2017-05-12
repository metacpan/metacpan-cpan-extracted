package DBIx::ObjectMapper::Relation::BelongsTo;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Relation);

sub initial_is_multi { 0 };

sub get {
    my $self = shift;
    my $mapper = shift;
    my $obj = $self->_get($mapper) || return;
    return $mapper->set_val( $self->name => $obj );
}

sub _get {
    my $self = shift;
    my $mapper = shift;
    return $self->get_one($mapper);
}

sub foreign_key {
    my ( $self, $class_table, $table ) = @_;
    return $class_table->get_foreign_key_by_table( $table );
}

sub relation_condition {
    my $self = shift;
    my $class_table = shift;
    my $table = shift;

    my $rel_table = $self->mapper->table;
    my $fk = $self->foreign_key( $class_table, $rel_table );

    my @cond;
    for my $i ( 0 .. $#{$fk->{keys}} ) {
        push @cond,
            $table->c( $fk->{refs}->[$i] )
                == $class_table->c($fk->{keys}->[$i]);
    }

    return @cond;
}

sub relation_value {
    my $self = shift;
    my $mapper = shift;
    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;

    my $fk = $self->foreign_key($class_mapper->table, $rel_mapper->table);
    my %foreign_key =
        map{ $fk->{keys}->[$_] => $fk->{refs}->[$_] } 0 .. $#{$fk->{keys}};

    my %val;
    for my $prop_name ( $class_mapper->attributes->property_names ) {
        my $prop = $class_mapper->attributes->property_info( $prop_name );
        next unless $prop->type eq 'column';
        if( $foreign_key{$prop->name} ) {
            $val{$foreign_key{$prop->name}} = $mapper->get_val( $prop_name );
        }
    }

    return \%val;
}

sub cascade_update { }

sub cascade_save {
    my $self = shift;
    my $mapper = shift;
    my $instance = shift;

    return unless $self->is_cascade_save_update;
    if( $instance->__mapper__->is_transient ) {
        $mapper->unit_of_work->add($instance);
        $instance->__mapper__->save;
    }

    $self->set_val_from_object($mapper, $instance);
}

sub set_val_from_object {
    my $self = shift;
    my $mapper = shift;
    my $instance = shift || return;

    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;
    my $fk = $self->foreign_key($class_mapper->table, $rel_mapper->table);
    my $modified_data = $mapper->modified_data;

    for my $i ( 0 .. $#{$fk->{keys}} ) {
        my $key = $fk->{keys}->[$i];
        my $val = $instance->__mapper__->get_val( $fk->{refs}->[$i] ) || next;
        unless ( defined $mapper->get_val($key)
            and exists $modified_data->{$key} )
        {
            $mapper->set_val_trigger( $key => $val );
            $mapper->set_val( $key => $val );
        }
    }
}

1;
