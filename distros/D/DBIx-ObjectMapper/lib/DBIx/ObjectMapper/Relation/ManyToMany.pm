package DBIx::ObjectMapper::Relation::ManyToMany;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Relation);

sub initial_is_multi { 1 }

sub new {
    my ( $class, $assc_table, $rel_class, $option ) = @_;
    my $self = $class->SUPER::new($rel_class, $option);
    $self->{assc_table} = $assc_table;
    return $self;
}

sub type       {'many_to_many'}
sub assc_table { $_[0]->{assc_table} }

sub identity_condition {
    my $self = shift;
    my $mapper = shift;
    my $class_mapper = $mapper->instance->__class_mapper__;

    my $fk =
        $self->assc_table->get_foreign_key_by_table( $class_mapper->table );
    my @cond;
    for my $i ( 0 .. $#{$fk->{keys}} ) {
        my $val = $mapper->get_val($fk->{refs}->[$i]);
        next unless defined $val;
        push @cond, $self->assc_table->c( $fk->{keys}->[$i] ) == $val;
    }

    return @cond;
}

sub relation_condition {
    my $self = shift;
    my $class_table = shift;
    my $rel_table = shift;

    my $fk1 = $self->assc_table->get_foreign_key_by_table( $class_table );
    my @assc_cond;
    for my $i ( 0 .. $#{$fk1->{keys}} ) {
        push @assc_cond,
            $self->assc_table->c( $fk1->{keys}->[$i] )
                == $class_table->c($fk1->{refs}->[$i]);
    }

    my $fk2 = $self->assc_table->get_foreign_key_by_table($rel_table);
    my @cond;
    my $attr = $self->mapper->attributes;
    for my $i ( 0 .. $#{$fk2->{keys}} ) {
        push @cond,
            $self->assc_table->c( $fk2->{keys}->[$i] )
                == $rel_table->c($fk2->{refs}->[$i]);
    }

    return \@cond, [ $self->assc_table => \@assc_cond ];
}

sub get {
    my $self = shift;
    my $mapper = shift;
    my @val = $self->_get($mapper);
    return $mapper->set_val(
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
    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;
    my $attr = $rel_mapper->attributes;
    my $fk1 =
        $self->assc_table->get_foreign_key_by_table( $rel_mapper->table );
    my @assc_cond;
    for my $i ( 0 .. $#{$fk1->{keys}} ) {
        push @assc_cond,
            $self->assc_table->c( $fk1->{keys}->[$i] )
                == $rel_mapper->table->c($fk1->{refs}->[$i]);
    }

    my $cond = $mapper->relation_condition->{$self->name};
    my $query = $mapper->unit_of_work->search( $self->rel_class )
        ->filter(@$cond)
        ->order_by( map { $attr->p($_) }
            @{ $rel_mapper->table->primary_key } );
    push @{$query->{join}}, [ $self->assc_table => \@assc_cond ];

    return $query->execute->all;
}

sub cascade_save {
    my $self = shift;
    my $mapper = shift;
    my $instance = shift;
    return unless $self->is_cascade_save_update;

    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;

    $mapper->unit_of_work->add($instance);
    if( $instance->__mapper__->is_pending ) {
        $instance->__mapper__->save;
    }

    my %values;
    my $fk1 =
        $self->assc_table->get_foreign_key_by_table( $rel_mapper->table );
    for my $i ( 0 .. $#{$fk1->{keys}} ) {
        $values{ $fk1->{keys}->[$i] }
            = $instance->__mapper__->get_val( $fk1->{refs}->[$i] );
    }

    my $fk2 =
        $self->assc_table->get_foreign_key_by_table( $class_mapper->table );
    for my $i ( 0 .. $#{$fk2->{keys}} ) {
        $values{ $fk2->{keys}->[$i] } = $mapper->get_val( $fk2->{refs}->[$i] );
    }

    $self->assc_table->insert->values(\%values)->execute;

    return $instance;
}

sub cascade_update {
    my $self = shift;
    my $mapper = shift;
    return unless $self->is_cascade_save_update and $mapper->is_modified;

    my $uniq_cond = $mapper->relation_condition->{$self->name};
    my $modified_data = $mapper->modified_data;
    my $class_mapper = $mapper->instance->__class_mapper__;

    my $fk =
        $self->assc_table->get_foreign_key_by_table( $class_mapper->table );
    my %foreign_key =
        map{ $fk->{refs}->[$_] => $fk->{keys}->[$_] } 0 .. $#{$fk->{keys}};

    my %sets;
    for my $mkey ( keys %$modified_data ) {
        my $prop = $class_mapper->attributes->property_info( $mkey );
        if( $foreign_key{$prop->name} ) {
            $sets{$foreign_key{$prop->name}} = $modified_data->{$mkey};
        }
    }
    return unless keys %sets;

    $self->assc_table->update->set(%sets)->where(@$uniq_cond)->execute;
}

sub cascade_delete {
    my $self = shift;
    my $mapper = shift;

    return unless $self->is_cascade_delete;

    my @cond = $self->identity_condition($mapper);
    return if !@cond || ( @cond == 1 and !defined $cond[0]->[2] );

    $self->assc_table->delete->where(@cond)->execute;
}

sub many_to_many_add {
    my $self = shift;
    my ($mapper, $instance) = @_;
    $self->cascade_save(@_);
}

sub many_to_many_remove {
    my $self = shift;
    my ($mapper, $instance) = @_;
    my $rel_mapper = $self->mapper;
    my $uniq_cond = $mapper->relation_condition->{$self->name};
    my @cond = @$uniq_cond;

    my $fk1 =
        $self->assc_table->get_foreign_key_by_table( $rel_mapper->table );

    for my $i ( 0 .. $#{$fk1->{keys}} ) {
        push @cond,
            $self->assc_table->c( $fk1->{keys}->[$i] )
                == $instance->__mapper__->get_val($fk1->{refs}->[$i]);
    }

    my ( $type, @uniq_cond ) = $self->assc_table->get_unique_condition(\@cond);
    if( !@uniq_cond and my $primary_key = $self->assc_table->primary_key ) {
        my $row = $self->assc_table->select->where(@cond)
            ->order_by( @$primary_key )->first;
        @cond = map { $self->assc_table->c($_) == $row->{$_} } @$primary_key;
    }

    $self->assc_table->delete->where(@cond)->execute;
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

sub deleted_parent {}

1;
