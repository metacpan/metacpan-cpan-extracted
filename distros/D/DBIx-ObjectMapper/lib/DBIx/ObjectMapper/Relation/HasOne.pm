package DBIx::ObjectMapper::Relation::HasOne;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Relation);

sub initial_is_multi { 0 }

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
    my ( $self, $my_table, $ref_table ) = @_;

    if( my $fk = $ref_table->get_foreign_key_by_table( $my_table ) ) {
        return $fk;
    }
    else {
        return {
            keys  => $ref_table->primary_key,
            refs  => $my_table->primary_key,
            table => $ref_table->table_name,
        };
    }
}

sub relation_condition {
    my $self = shift;
    my $class_table = shift;
    my $table = shift;

    my $fk = $self->foreign_key($class_table, $table);

    my @cond;
    for my $i ( 0 .. $#{$fk->{keys}} ) {
        push @cond,
            $class_table->c( $fk->{keys}->[$i] )
                == $table->c($fk->{refs}->[$i]);
    }

    return @cond;
}

1;
