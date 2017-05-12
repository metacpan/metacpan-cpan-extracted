package DBIx::ObjectMapper::Mapper::Instance;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Try::Tiny;
use Scalar::Util qw(refaddr weaken);
use Log::Any qw($log);
use DBIx::ObjectMapper::Utils;
use DBIx::ObjectMapper::Session::Array;

our $call = 0;
my %INSTANCES;
my %STATUS = (
    # "status" => "changable status"
    transient  => [ 'pending', 'persistent', 'detached' ],
    pending    => [ 'expired', 'detached' ],
    persistent => [ 'expired', 'detached' ],
    detached   => [],
    expired    => [ 'persistent', 'detached' ],
);

sub new {
    my ( $class, $instance ) = @_;
    return $class->get(refaddr($instance)) || $class->create($instance);
}

sub create {
    my ( $class, $instance ) = @_;

    my $self = bless {
        instance            => $instance,
        status              => 'transient',
        is_modified         => 0,
        modified_data       => +{},
        unit_of_work        => undef,
        identity_condition  => undef,
        relation_condition  => +{},
        primary_cache_key   => undef,
        unique_cache_keys   => [],
        save_many_to_many   => [],
        remove_many_to_many => [],
    }, $class;
    $INSTANCES{refaddr($instance)} = $self;
    $self->initialize;
    return $self;
}

sub initialize {
    my $self = shift;
    $self->init_identity_condition;
    $self->init_relation_identity_condition;
    $self->init_cache_keys;
    $self->{add_lazy_column} = [];
}

sub lazy_column {
    my ( $self, $name ) = @_;
    my $class_mapper = $self->instance->__class_mapper__;
    my %lazy_column = $class_mapper->attributes->lazy_column($name);
    for my $lc ( @{$self->{add_lazy_column}} ) {
        if( $name eq $lc->name ) {
            $lazy_column{$name} = $lc;
        }
    }
    return %lazy_column;
}

sub init_identity_condition {
    my $self = shift;
    my $record = shift || $self->reducing;
    my $class_mapper = $self->instance->__class_mapper__;
    my $identity_condition
        = +[ map { $class_mapper->table->c($_) == $record->{$_} }
            @{ $class_mapper->table->primary_key } ];

    if( @$identity_condition ) {
        return $self->{identity_condition} = $identity_condition;
    }
    elsif( my $unique_key = @{ $class_mapper->table->unique_key } ) {
        for my $uniq ( @$unique_key ) {
            return $self->{identity_condition} = map {
                $class_mapper->table->c($_) == $record->{$_} } @{$uniq->[1]};
        }
    }

    confess "Can't define identity.";
}

sub identity_condition { $_[0]->{identity_condition} }

sub init_relation_identity_condition {
    my $self = shift;
    my $record = shift || $self->reducing;
    my $class_mapper = $self->instance->__class_mapper__;

    for my $prop_name ( $class_mapper->attributes->property_names ) {
        my $prop = $class_mapper->attributes->property_info($prop_name);
        next unless $prop->type eq 'relation';
        my @cond = $prop->{isa}->identity_condition($self);
        next unless @cond;
        $self->{relation_condition}->{$prop_name} = \@cond;
    }
}

sub relation_condition { $_[0]->{relation_condition} }

sub init_cache_keys {
    my $self = shift;
    my $result = shift || $self->reducing;
    my $class_mapper = $self->instance->__class_mapper__;
    $self->{primary_cache_key} = $class_mapper->primary_cache_key($result);
    $self->{unique_cache_keys} = [ $class_mapper->unique_cache_keys($result) ];
}

sub cache_keys {
    my $self = shift;
    return ( $self->primary_cache_key, $self->unique_cache_keys );
}

sub primary_cache_key { $_[0]->{primary_cache_key} }
sub unique_cache_keys { @{$_[0]->{unique_cache_keys}} }

sub get {
    my ( $self, $addr ) = @_;
    $INSTANCES{$addr};
}

sub unit_of_work { $_[0]->{unit_of_work} }
sub status       { $_[0]->{status} }

sub change_status {
    my $self = shift;
    my $status_name = shift;
    return if $self->status eq $status_name;

    if ( $STATUS{$status_name}
        and grep { $_ eq $status_name } @{$STATUS{ $self->status }} )
    {
        $self->{status} = $status_name;
        if( $status_name eq 'persistent' || $status_name eq 'pending' ) {
            unless( $self->unit_of_work ) {
                my $uow = shift ||  confess "need UnitOfWork";
                $self->{unit_of_work} = $uow;
            }
        }
        elsif( $status_name eq 'detached' ) {
            my $class_mapper = $self->instance->__class_mapper__;
            for my $prop_name ( $class_mapper->attributes->property_names ) {
                my $prop = $class_mapper->attributes->property_info($prop_name);
                next unless $prop->type eq 'relation';
                if( $prop->{isa}->is_cascade_detach() ) {
                    if( my $instance = $self->get_val($prop_name) ) {
                        my @instance
                            = ref $instance eq 'ARRAY'
                            ? @$instance
                            : ($instance);
                        $self->unit_of_work->detach($_) for @instance;
                    }
                }
            }
            $self->_clear_cache;
        }
        elsif( $status_name eq 'expired' ) {
            my $class_mapper = $self->instance->__class_mapper__;
            for my $prop_name ( $class_mapper->attributes->property_names ) {
                my $prop = $class_mapper->attributes->property_info($prop_name);
                next unless $prop->type eq 'relation';
                if( $prop->{isa}->is_cascade_reflesh_expire() ) {
                    if( my $instance = $self->get_val($prop_name) ) {
                        my @instance
                            = ref $instance eq 'ARRAY'
                                ? @$instance
                                    : ($instance);
                        for ( @instance ) {
                            my $mapper = $_->__mapper__;
                            if (   $mapper->is_pending
                                || $mapper->is_persistent )
                            {
                                $mapper->change_status('expired');
                            }
                        }
                    }
                }
            }
            $self->_clear_cache;
        }
        else {
            #warn $status_name;
        }
    }
    else {
        if( $self->status eq 'expired' ) {
            $self->reflesh;
            $self->change_status($status_name);
        }
        else {
            confess "Can't change status : "
                . $self->status
                . " => $status_name";
        }
    }
}

sub is_transient  { $_[0]->status eq 'transient' }
sub is_persistent { $_[0]->status eq 'persistent' }
sub is_detached   { $_[0]->status eq 'detached' }
sub is_pending    { $_[0]->status eq 'pending' }
sub is_expired    { $_[0]->status eq 'expired' }

sub instance { $_[0]->{instance} }

sub reducing {
    my ( $self ) = @_;
    my %result;
    my $class_mapper = $self->instance->__class_mapper__;
    my %primary_key = map { $_ => 1 } @{$class_mapper->table->primary_key};
    for my $prop_name ( $class_mapper->attributes->property_names ) {
        my $prop = $class_mapper->attributes->property_info($prop_name);
        next unless $prop->type eq 'column';
        my $col_name = $prop->name;
        my $val = $self->get_val($prop_name);
        next if $primary_key{$col_name} and !defined $val;
        $result{$col_name} = $val;
    }
    return \%result;
}

sub reflesh {
    my $self = shift;
    return unless $self->is_expired;

    my $class_mapper = $self->instance->__class_mapper__;
    my ( $key, @cond )
        = $class_mapper->get_unique_condition( $self->identity_condition );
    my $new_val = $class_mapper->table->_find(@cond) || do {
        $self->change_status('detached');
        return;
    };

    $self->change_status('persistent');
    $self->_modify( $new_val );
    $self->unit_of_work->_set_cache($self);
    $self->initialize;

    for my $prop_name ( $class_mapper->attributes->property_names ) {
        my $prop = $class_mapper->attributes->property_info($prop_name);
        next unless $prop->type eq 'relation';
        if( $prop->{isa}->is_cascade_reflesh_expire() ) {
            if( my $instance = $self->get_val($prop_name) ) {
                my @instance
                    = ref $instance eq 'ARRAY'
                    ? @$instance
                    : ($instance);
                $_->__mapper__->reflesh for @instance;
            }
        }
    }
}

# this method internal use only.
sub _modify {
    my $self = shift;
    my $rdata = shift;
    my $class_mapper = $self->instance->__class_mapper__;
    for my $prop_name ( $class_mapper->attributes->property_names ) {
        my $prop = $class_mapper->attributes->property_info($prop_name);
        my $col = $prop->name
            || $prop_name;
        if( exists $rdata->{$col} ) {
            if( defined $rdata->{$col} and $prop->type eq 'column' ) {
                $rdata->{$col} = $prop->{isa}->from_storage( $rdata->{$col} );
            }
            $self->set_val($prop_name => $rdata->{$col});

            # re-regist change_checker. because internal use only.
            if( ref $rdata->{$col} ) {
                $self->unit_of_work->change_checker->regist( $rdata->{$col} );
            }
        }
    }

    return $self->instance;
}

sub get_val_trigger {
    my ( $self, $name ) = @_;

    my $class_mapper = $self->instance->__class_mapper__;
    my $prop = $class_mapper->attributes->property_info($name);

    if( $self->is_expired ) {
        $self->reflesh;
    }
    elsif( !$self->is_persistent ) {
        if( $prop->is_multi ) {
            my $val = $self->get_val($name);
            $self->set_val( $name => [] )
                if !defined $val || ( ref $val eq 'ARRAY' and @$val == 0 );
        }
        return;
    }

    if( $prop->type eq 'relation' ) {
        my $val = $self->get_val($name);
        if ( !defined $val ) {
            $self->load_rel_val($name);
        }
        elsif( ref $val eq 'ARRAY' ) {
            if( @$val == 0 and !tied(@$val) ) {
                $self->load_rel_val($name);
            }
            elsif( !tied(@$val) ) {
                $self->set_val(
                    $name => DBIx::ObjectMapper::Session::Array->new(
                        $name,
                        $self,
                        @$val,
                    )
                )
            }
        }
    }
    elsif( my %lazy_column = $self->lazy_column($name) ) {
        unless ( defined $self->get_val($name) ) {
            my $uniq_cond = $self->identity_condition;
            my $val = $class_mapper->select( values %lazy_column )
                ->where(@$uniq_cond)->first;
            $self->unit_of_work->{query_cnt}++;
            for my $col ( keys %lazy_column ) {
                $self->unit_of_work->change_checker->regist( $val->{$col} )
                    if ref $val->{$col};
                $self->set_val( $col => $val->{$col} );
            }
        }
    }

    $self->demolish if $self->is_transient;
}

sub load_rel_val {
    my $self = shift;
    my $name = shift;
    my $class_mapper = $self->instance->__class_mapper__;
    $class_mapper->attributes->property_info($name)->get($self);
}

sub set_val_trigger {
    my ( $self, $name, $val ) = @_;

    if( $self->status eq 'expired' ) {
        $self->reflesh;
    }

    my $class_mapper = $self->instance->__class_mapper__;
    my $prop = $class_mapper->attributes->property_info($name);

    if ( my $code = $prop->validation ) {
        unless ( $code->($val) ) {
            confess "parameter $name is invalid.";
        }
    }

    if ($self->is_persistent
        and !DBIx::ObjectMapper::Utils::is_deeply(
            $self->get_val($name), $val
        )
    ) {
        $self->{is_modified} = 1;
        $self->{modified_data}->{ $name } = $val;
    }

    $self->demolish if $self->is_transient;
    return;
}

sub get_val {
    my ( $self, $name ) = @_;
    return unless $self->instance; ## maybe in global destruction.

    local $call = 1;
    my $class_mapper = $self->instance->__class_mapper__;
    if( my $getter = $class_mapper->accessors->generic_getter ) {
        return $self->instance->$getter($name);
    }
    else {
        my $prop = $class_mapper->attributes->property_info($name);
        if( my $getter = $prop->getter ) {
            return $self->instance->$getter();
        }
        else {
            return wantarray
                ? ( $self->instance->{ $prop->name || $name } )
                : $self->instance->{ $prop->name || $name };
        }
    }
}

sub set_val {
    my ( $self, $name, $val ) = @_;
    return unless $self->instance; ## maybe in global destruction.

    local $call = 1;
    my $class_mapper = $self->instance->__class_mapper__;
    if( my $setter = $class_mapper->accessors->generic_setter ) {
        $self->instance->$setter($name => $val);
    }
    else {
        my $prop = $class_mapper->attributes->property_info($name);
        if( my $setter = $prop->setter ) {
            $self->instance->$setter($val);
        }
        else {
            $self->instance->{$prop->name || $name} = $val;
        }
    }

    return $val;
}

sub is_modified   {
    my $self = shift;

    my $is_modified = $self->{is_modified};
    return $is_modified unless $self->instance; ## maybe in global destruction.

    my $class_mapper = $self->instance->__class_mapper__;
    my $modified_data = $self->modified_data;
    for my $prop_name ( $class_mapper->attributes->property_names ) {
        my $prop = $class_mapper->attributes->property_info($prop_name);
        my $col = $prop->name || $prop_name;
        my $val = $self->get_val($prop_name);
        next unless $prop->type eq 'column' and ref $val;
        if( $self->unit_of_work->change_checker->is_changed( $val ) ) {
            $modified_data->{$prop_name} = $val;
            $is_modified = 1;
        }
    }

    return $is_modified;
}

sub modified_data { $_[0]->{modified_data} }

sub update {
    my ( $self ) = @_;
    confess 'it need to be "persistent" status.' unless $self->is_persistent;

    my $reduce_data = $self->reducing;
    my $modified_data = $self->modified_data;
    my $uniq_cond = $self->identity_condition;
    my $class_mapper = $self->instance->__class_mapper__;

    my $result;
    try {
        my @after_cascade;
        for my $prop_name ( $class_mapper->attributes->property_names ) {
            my $prop = $class_mapper->attributes->property_info($prop_name);
            next unless $prop->type eq 'relation';
            if (ref( $prop->{isa} ) eq
                'DBIx::ObjectMapper::Relation::BelongsTo' )
            {
                if ( $prop->{isa}->is_cascade_save_update() ) {
                    $prop->{isa}->cascade_update($self);
                }

                if( $modified_data->{$prop_name} ) {
                    $prop->{isa}->set_val_from_object(
                        $self,
                        $self->get_val($prop_name),
                    );
                }
            }
            elsif ( $prop->{isa}->is_cascade_save_update() ) {
                push @after_cascade, $prop;
            }
        }

        my $new_val;
        if( keys %$modified_data ) {
            my %mod_data;
            for ( keys %$modified_data ) {
                my $prop = $class_mapper->attributes->property_info($_);
                $mod_data{$prop->name} = $modified_data->{$_};
            }

            $result = $class_mapper->update( \%mod_data, $uniq_cond );
            $new_val = DBIx::ObjectMapper::Utils::merge_hashref(
                $reduce_data,
                $modified_data
            );
        }

        for my $c ( @after_cascade ) {
            $c->{isa}->cascade_update( $self );
        }

        $self->_release_many_to_many_event;
        $self->_modify($new_val) if $new_val;
    } catch {
        $self->change_status('detached');
        confess $_[0];
    };

    $self->{is_modified} = 0;
    $self->{modified_data} = +{};

    $self->change_status('expired'); # cascade expire if cascade_reflesh_expire
    return !$result || $self->instance;
}

sub save {
    my ( $self ) = @_;

    confess 'it need to be "pending" status.' unless $self->is_pending;
    my $class_mapper = $self->instance->__class_mapper__;

    try {
        my @after_cascade;
        for my $prop_name ( $class_mapper->attributes->property_names ) {
            my $prop = $class_mapper->attributes->property_info($prop_name);
            if ( $prop->type eq 'relation' ) {
                if (ref( $prop->{isa} ) eq
                    'DBIx::ObjectMapper::Relation::BelongsTo' )
                {
                    if ( my $instance = $self->get_val($prop_name) ) {
                        my @instances
                            = ref $instance eq 'ARRAY'
                            ? @$instance
                            : ($instance);
                        for my $i (@instances) {
                            if( $prop->{isa}->is_cascade_save_update() ) {
                                $prop->{isa}->cascade_save( $self, $i );
                            }
                            else {
                                $prop->{isa}->set_val_from_object( $self, $i );
                            }
                        }
                    }
                }
                elsif( $prop->{isa}->is_cascade_save_update() ) {
                    push @after_cascade, $prop;
                }
            }
        }

        my $reduce_data = $self->reducing;
        my $data = { %$reduce_data, %{$class_mapper->default_value} };
        my $comp_result = $class_mapper->insert(%$data);
        $self->_modify($comp_result);
        $self->initialize;

        for my $c ( @after_cascade ) {
            if ( my $instance = $self->get_val($c->name) ) {
                my @instances
                    = ref $instance eq 'ARRAY'
                    ? @$instance
                    : ($instance);
                for my $i (@instances) {
                    $c->{isa}->cascade_save( $self, $i );
                }
            }
        }

    } catch {
        $self->change_status('detached');
        confess $_[0];
    };

    $self->change_status('expired');
    return $self->instance;
}

sub delete {
    my $self = shift;
    confess 'it need to be "persistent" status.' unless $self->is_persistent;

    my $deleted_key = shift || +{};
    my $uniq_cond = $self->identity_condition;
    my $class_mapper = $self->instance->__class_mapper__;

    my $result;
    try {
        my @after_cascade;
        $deleted_key->{$self->primary_cache_key} = 1;
        for my $prop_name ( $class_mapper->attributes->property_names ) {
            my $prop = $class_mapper->attributes->property_info($prop_name);
            if (    $prop->type eq 'relation'
                and $prop->{isa}->is_cascade_delete() )
            {
                if (ref( $prop->{isa} ) eq
                    'DBIx::ObjectMapper::Relation::BelongsTo' )
                {
                    push @after_cascade, $prop;
                }
                else {
                    $self->_cascade_delete($prop, $deleted_key);
                }
            }
            elsif( $prop->is_multi ) {
                $prop->{isa}->deleted_parent($self);
            }
        }

        $result = $class_mapper->delete(@$uniq_cond);

        for my $c ( @after_cascade ) {
            $self->_cascade_delete($c, $deleted_key);
        }
    } catch {
        $self->change_status('detached');
        confess $_[0];
    };

    $self->change_status('detached');
    return $result;
}

sub _cascade_delete {
    my ( $self, $prop, $deleted_key ) = @_;

    $prop->{isa}->cascade_delete($self, $deleted_key);
    if ( my $instance = $self->get_val($prop->name) ) {
        my @instance
            = ref $instance eq 'ARRAY'
            ? @$instance
            : ($instance);
        $self->unit_of_work->detach($_) for @instance;
    }
}

sub _clear_cache {
    my $self = shift;
    $self->unit_of_work->_clear_cache($self) if $self->unit_of_work;
}

sub add_multi_val {
    my $self = shift;
    my $name = shift;
    my $obj  = shift;

    my $class_mapper = $self->instance->__class_mapper__;
    my $prop = $class_mapper->attributes->property_info($name) || return;
    return unless $prop->type eq 'relation';

    $self->unit_of_work->add($obj) unless $obj->__mapper__->is_persistent;
    if ( $prop->{isa}->type eq 'many_to_many' ) {
        my $mapper_addr = refaddr($obj);
        $self->_regist_many_to_many_event( $name, $mapper_addr, 'save' );
    }
    else {
        my $rel_val = $prop->{isa}->relation_value($self);
        for my $r ( keys %$rel_val ) {
            $obj->__mapper__->set_val_trigger( $r => $rel_val->{$r} );
            $obj->__mapper__->set_val( $r => $rel_val->{$r} );
        }
        $self->unit_of_work->flush if $self->unit_of_work->autoflush;
    }
}

sub remove_multi_val {
    my $self = shift;
    my $name = shift;
    my $obj  = shift;

    my $class_mapper = $self->instance->__class_mapper__;
    my $prop = $class_mapper->attributes->property_info($name) || return;

    return unless $prop->type eq 'relation';

    if (    $prop->{isa}->type eq 'many_to_many'
        and $obj->__mapper__->is_persistent )
    {
        my $mapper_addr  = refaddr($obj);
        $self->_regist_many_to_many_event($name, $mapper_addr, 'remove');
    }
    elsif( $self->is_persistent ) {
        if( $prop->{isa}->is_cascade_delete_orphan ) {
            $self->unit_of_work->delete($obj);
        }
        else {
            my $rel_val = $prop->{isa}->relation_value($self);
            for my $r ( keys %$rel_val ) {
                $obj->__mapper__->set_val_trigger( $r => undef );
                $obj->__mapper__->set_val( $r => undef );
            }
        }
        $self->unit_of_work->flush if $self->unit_of_work->autoflush;
    }
}

sub _regist_many_to_many_event {
    my $self = shift;
    my ($name, $mapper_addr, $event) = @_;
    $self->{is_modified} = 1;
    push @{$self->{$event . '_many_to_many'}}, {
        name => $name,
        mapper_addr => $mapper_addr,
    };
    $self->_release_many_to_many_event if $self->unit_of_work->autoflush;
}

sub _release_many_to_many_event {
    my $self = shift;
    my $class_mapper = $self->instance->__class_mapper__;

    while( my $smm = shift(@{$self->{save_many_to_many}}) ) {
        my $prop = $class_mapper->attributes->property_info($smm->{name});
        next unless $prop->type eq 'relation';
        $prop->{isa}->many_to_many_add(
            $self,
            $self->get($smm->{mapper_addr})->instance,
        );
    }

    while( my $rmm = shift(@{$self->{remove_many_to_many}}) ) {
        my $prop = $class_mapper->attributes->property_info($rmm->{name});
        next unless $prop->type eq 'relation';
        $prop->{isa}->many_to_many_remove(
            $self,
            $self->get($rmm->{mapper_addr})->instance,
        );
    }
}

sub demolish {
    my $self = shift;
    my $id = refaddr($self->instance) || return;
    $self->{unit_of_work} = undef;
    delete $INSTANCES{$id} if exists $INSTANCES{$id};
}

sub DESTROY {
    my $self = shift;
    eval{ $self->demolish };
    warn $@ if $@;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Mapper::Instance

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

