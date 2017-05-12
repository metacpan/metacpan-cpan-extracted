package DBIx::ObjectMapper::Relation;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use DBIx::ObjectMapper::Session::Array;
use DBIx::ObjectMapper::Mapper;

my %CASCADE_TYPES = (
    # type         => [ single, multi ]
    save_update    => [ 0, 1 ],
    delete         => [ 0, 0 ],
    detach         => [ 0, 0 ],
    reflesh_expire => [ 0, 0 ],
    delete_orphan  => [ 0, 0 ],
);

sub new {
    my ( $class, $rel_class, $option ) = @_;

    my $is_multi = $class->initial_is_multi || 0;

    my $self = bless +{
        name      => undef,
        rel_class => $rel_class,
        option    => $option || {},
        type      => 'relation',
        cascade   => +{},
        is_multi  => $is_multi,
        table     => undef,
        via       => [],
    }, $class;

    $self->_init_option;
    return $self;
}

sub is_multi { $_[0]->{is_multi} }

sub _init_option {
    my $self = shift;

    if( my $cascade_option = $self->option->{cascade} ) {
        $cascade_option =~ s/\s//g;
        my %cascade = map { $_ => 1 } split ',', $cascade_option;
        if( $cascade{all} ) {
            $self->{cascade}{$_} = 1
                for qw(save_update reflesh_expire delete detach);
        }

        for my $c ( keys %CASCADE_TYPES ) {
            $self->{cascade}{$c} = 1 if $cascade{$c};
        }
    }

    if( my $order_by = $self->option->{order_by} ) {
        $order_by = [ $order_by ] unless ref $order_by eq 'ARRAY';
        $self->{order_by} = $order_by;
    }
}

{
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $cascade ( keys %CASCADE_TYPES ) {
        *{"$pkg\::is_cascade_$cascade"} = sub {
            my $self = shift;
            return $self->{cascade}{$cascade} || do {
                if( $self->is_multi ) {
                    $CASCADE_TYPES{$cascade}->[1];
                }
                else {
                    $CASCADE_TYPES{$cascade}->[0];
                }
            }
        };
    }
};

sub mapper    {
    my $self = shift;
    unless( DBIx::ObjectMapper::Mapper->is_initialized($self->rel_class) ) {
        confess 'the '
            . $self->rel_class
            . " is not mapped by the DBIx::ObjectMapper."
    }
    return $self->rel_class->__class_mapper__;
}

sub type      { $_[0]->{type} }
sub rel_class { $_[0]->{rel_class} }
sub option    { $_[0]->{option} }
sub table     { $_[0]->{table} ||= $_[0]->mapper->table->clone($_[0]->name) }
sub property  {
    my $self = shift;
    my $name = shift;
    my $prop = $self->mapper->attributes->property($name);
    my @via = @{$self->{via}};

    if( $prop->isa('DBIx::ObjectMapper::Metadata::Table::Column') ) {
        $prop->as_alias($self->name, @via);
    }
    else {
        return $prop->clone(@via);
    }
}
*prop = *p = \&property;

sub clone {
    my $self = shift;
    my @via = @_;
    push @via, @{$self->{via}} if $self->{via};
    my $clone = bless {%$self}, ref($self);
    $clone->{via} = \@via;
    return $clone;
}

sub name {
    my $self = shift;
    if( @_ ) {
        $self->{name} = shift;
        unshift @{$self->{via}}, $self->{name};
    }
    return $self->{name};
}

sub foreign_key {}

sub get_one {
    my $self = shift;
    my $mapper = shift;
    my $cond = $mapper->relation_condition->{$self->name} || return;
    return $mapper->unit_of_work->get( $self->rel_class => $cond );
}

sub get_multi {
    my $self = shift;
    my $mapper = shift;
    my $cond = $mapper->relation_condition->{$self->name} || return;

    my $rel_mapper = $self->mapper;

    my @order_by;
    if( $self->{order_by} ) {
        @order_by = @{$self->{order_by}};
    }
    else {
        @order_by = map { $rel_mapper->attributes->property($_) }
            @{ $rel_mapper->table->primary_key };
    }

    return $mapper->unit_of_work->search( $self->rel_class )->filter(@$cond)
        ->order_by(@order_by)->execute->all;
}

sub relation_condition {}

sub cascade_delete {
    my $self = shift;
    return unless $self->is_cascade_delete;
    my $mapper = shift;
    my $deleted_key = shift;
    for my $child ( $self->_get($mapper) ) {
        unless( $deleted_key->{$child->__mapper__->primary_cache_key} ) {
            $child->__mapper__->delete($deleted_key);
        }
    }
}

sub relation_value {
    my $self = shift;
    my $mapper = shift;
    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;

    my $fk = $self->foreign_key($class_mapper->table, $rel_mapper->table);
    my %foreign_key =
        map{ $fk->{refs}->[$_] => $fk->{keys}->[$_] } 0 .. $#{$fk->{keys}};

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

sub identity_condition {
    my $self = shift;
    my $mapper = shift;

    my $rel_val = $self->relation_value($mapper);
    my $rel_mapper = $self->mapper;
    my @cond;
    for my $r ( keys %$rel_val ) {
        next unless defined $rel_val->{$r};
        push @cond, $rel_mapper->table->c( $r ) == $rel_val->{$r};
    }
    return @cond;
}

sub cascade_update {
    my $self = shift;
    my $mapper = shift;

    return unless $self->is_cascade_save_update and $mapper->is_modified;

    my $uniq_cond = $mapper->relation_condition->{$self->name};
    my $modified_data = $mapper->modified_data;

    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;
    my $fk = $self->foreign_key($class_mapper->table, $rel_mapper->table);
    my %foreign_key =
        map{ $fk->{refs}->[$_] => $fk->{keys}->[$_] } 0 .. $#{$fk->{keys}};

    my %sets;
    for my $mkey ( keys %$modified_data ) {
        my $prop = $class_mapper->attributes->property_info( $mkey );
        if( $foreign_key{$mkey} ) {
            $sets{$foreign_key{$mkey}} = $modified_data->{$mkey};
        }
    }
    return unless keys %sets;

    $self->mapper->update( \%sets, $uniq_cond );
}

sub cascade_save {
    my $self = shift;
    my $mapper = shift;
    my $instance = shift;

    return unless $self->is_cascade_save_update;

    my %sets;
    my $rel_val = $self->relation_value($mapper);
    for my $r ( keys %$rel_val ) {
        $instance->__mapper__->set_val( $r => $rel_val->{$r} );
    }

    $mapper->unit_of_work->add($instance);

    $instance->__mapper__->save;
}

sub validation {
    my $self = shift;
    my $rel_class = $self->rel_class;
    return sub {
        my ( $val ) = @_;
        return $rel_class eq ( ref($val) || '' );
    };
}

sub deleted_parent {
    my $self = shift;
    my $mapper = shift;

    return unless $self->is_multi;

    my $class_mapper = $mapper->instance->__class_mapper__;
    my $rel_mapper = $self->mapper;
    my $fk = $self->foreign_key($class_mapper->table, $rel_mapper->table);
    my %foreign_key =
        map{ $fk->{keys}->[$_] => $fk->{refs}->[$_] } 0 .. $#{$fk->{keys}};

    my @delete_name;
    for my $prop_name ( $rel_mapper->attributes->property_names ) {
        my $prop = $rel_mapper->attributes->property_info( $prop_name );
        next unless $prop->type eq 'column';
        if( $foreign_key{$prop->name} ) {
            push @delete_name, $prop_name;
        }
    }

    my @children = $self->_get($mapper);
    for my $c ( @children ) {
        for my $name (@delete_name) {
            $c->__mapper__->set_val_trigger( $name => undef );
            $c->__mapper__->set_val( $name => undef );
        }
        $c->__mapper__->update;
    }
}

sub DESTROY {
    my $self = shift;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

1;
