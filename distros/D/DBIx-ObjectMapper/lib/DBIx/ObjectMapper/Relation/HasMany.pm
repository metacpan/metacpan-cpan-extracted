package DBIx::ObjectMapper::Relation::HasMany;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Relation);

sub initial_is_multi { 1 };

sub get {
    my $self = shift;
    my $mapper = shift;
    my @val = $self->_get($mapper);

    $mapper->set_val(
        $self->name => DBIx::ObjectMapper::Session::Array->new(
            $self->name,
            $mapper,
            @val
        )
    );
}

sub _get {
    my $self = shift;
    my $mapper = shift;
    return $self->get_multi($mapper);
}

sub foreign_key {
    my ( $self, $class_table, $table ) = @_;
    return $table->get_foreign_key_by_table( $class_table );
}

sub relation_condition {
    my $self = shift;
    my $class_table = shift;
    my $table = shift;

    my $rel_table = $self->mapper->table;
    my $fk = $self->foreign_key($class_table, $rel_table);

    my @cond;
    for my $i ( 0 .. $#{$fk->{keys}} ) {
        push @cond,
            $table->c( $fk->{keys}->[$i] )
                == $class_table->c($fk->{refs}->[$i]);
    }

    return @cond;
}

sub validation {
    my $self = shift;
    my $rel_class = $self->rel_class;
    return sub {
        my ( $val ) = @_;
        if( ref $val eq 'ARRAY' ) {
            return ( grep{ $rel_class eq ( ref($_) || '' ) } @$val ) == @$val;
        }
        return 0;
    };
}

1;
