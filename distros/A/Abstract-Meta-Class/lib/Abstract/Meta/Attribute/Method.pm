package Abstract::Meta::Attribute::Method;


use strict;
use warnings;
use Carp 'confess';
use vars qw($VERSION);

$VERSION = 0.06;


=head1 NAME

Abstract::Meta::Attribute::Method - Method generator.

=head1 DESCRIPTION

Generates methods for attribute's definition.

=head1 SYNOPSIS

    use Abstract::Meta::Class ':all';
    has '$.attr1' => (default => 0); 

=head2 methods

=over

=item generate_scalar_accessor_method

=cut

sub generate_scalar_accessor_method {
    my $attr = shift; 
    my $mutator = $attr->mutator;
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;    
    my $on_read = $attr->on_read;
    my $array_storage_type = $attr->storage_type eq 'Array';
    $array_storage_type ? 
        ($transistent ? sub {
            my ($self, @args) = @_;
            $self->$mutator(@args) if scalar(@args) >= 1;
            my $result = $on_read
            ? $on_read ->($self, $attr, 'accessor')
            : get_attribute($self, $storage_key);
            $result;
        }
        : (
           $on_read ?
           sub {
            my ($self, @args) = @_;
            $self->$mutator(@args) if scalar(@args) >= 1;
            my $result = $on_read
            ? $on_read ->($self, $attr, 'accessor')
            : $self->[$storage_key];
            $result;
            } :
            sub {
                my ($self, @args) = @_;
                $self->$mutator(@args) if @args >= 1;
                $self->[$storage_key];
            }
           )
        )
    :
    sub {
        my ($self, @args) = @_;
        $self->$mutator(@args) if scalar(@args) >= 1;
        my $result = $on_read
        ? $on_read ->($self, $attr, 'accessor')
        : $transistent ? get_attribute($self, $storage_key) : $self->{$storage_key};
        $result;
    };
}


=item generate_code_accessor_method

=cut

sub generate_code_accessor_method {
    my $attr = shift;
    $attr->generate_scalar_accessor_method;
}


=item generate_mutator_method

=cut

sub generate_mutator_method {
    my $attr = shift;
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;    
    my $accessor = $attr->accessor;
    my $required = $attr->required;
    my $default = $attr->default;
    my $associated_class = $attr->associated_class;
    my $perl_type = $attr->perl_type;
    my $index_by = $attr->index_by;
    my $on_change = $attr->on_change;
    my $data_type_validation = $attr->data_type_validation;
    my $on_validate = $attr->on_validate;
    my $array_storage_type = $attr->storage_type eq 'Array';
    $array_storage_type ?
    sub {
        my ($self, $value) = @_;
        if (! defined $value && defined $default) {
            if (ref($default) eq 'CODE') {
                $value = $default->($self, $attr);
            } else {
                $value = $default;
            }
        }

        $on_validate->($self, $attr, 'mutator', \$value) if $on_validate;
        if ($data_type_validation) {
            $value = index_association_data($value, $accessor, $index_by)
                if ($associated_class && $perl_type eq 'Hash');
            $attr->validate_data_type($self, $value, $accessor, $associated_class, $perl_type);
            if($required) {
                if ($perl_type eq 'Hash') {
                    confess "attribute $accessor is required"
                      unless scalar %$value;
                      
                } elsif ($perl_type eq 'Array') {
                    confess "attribute $accessor is required"
                      unless scalar @$value;
                }
            }

        } else {
        confess "attribute $accessor is required"
          if $required && ! defined $value;
        }
        
        $on_change->($self, $attr, 'mutator', \$value) or return $self
          if ($on_change && defined $value);
        

        if ($transistent) {
            set_attribute($self, $storage_key, $value);
        } else {
            $self->[$storage_key] = $value;
        }
        $self;
    }    
    :
    sub {
        my ($self, $value) = @_;
        if (! defined $value && defined $default) {
            if (ref($default) eq 'CODE') {
                $value = $default->($self, $attr);
            } else {
                $value = $default;
            }
        }

        $on_validate->($self, $attr, 'mutator', \$value) if $on_validate;
        if ($data_type_validation) {
            $value = index_association_data($value, $accessor, $index_by)
                if ($associated_class && $perl_type eq 'Hash');
            $attr->validate_data_type($self, $value, $accessor, $associated_class, $perl_type);
            if($required) {
                if ($perl_type eq 'Hash') {
                    confess "attribute $accessor is required"
                      unless scalar %$value;
                      
                } elsif ($perl_type eq 'Array') {
                    confess "attribute $accessor is required"
                      unless scalar @$value;
                }
            }
        } else {
            confess "attribute $accessor is required"
              if $required && ! defined $value;
        }

        
        $on_change->($self, $attr, 'mutator', \$value) or return $self
          if ($on_change && defined $value);
        

        if ($transistent) {
            set_attribute($self, $storage_key, $value);
        } else {
            $self->{$storage_key} = $value;
        }
        $self;
    };
}


=item index_association_data

=cut

sub index_association_data {
    my ($data, $attr_name, $index) = @_;
    return $data if ref($data) eq 'HASH';
    my %result;
    if($index && $$data[0]->can($index)) {
        %result = (map {($_->$index, $_)} @$data);
    } else {
        %result = (map {($_  . "", $_)} @$data);
    }
    \%result;
}


=item validate_data_type

=cut

sub validate_data_type {
    my ($attr, $self, $value, $accessor, $associated_class, $perl_type) = @_;
    my $array_storage_type = $attr->storage_type eq 'Array';
    if ($perl_type eq 'Array') {
        confess "$accessor must be $perl_type type"
            unless (ref($value) eq 'ARRAY');
        if ($associated_class) {
            validate_associated_class($attr, $self, $_)
              for @$value;
        }
    } elsif ($perl_type eq 'Hash') {
        confess "$accessor must be $perl_type type"
          unless (ref($value) eq 'HASH');
        if ($associated_class) {
            validate_associated_class($attr, $self, $_)
              for values %$value;
        }
    } elsif ($associated_class) {
        my $transistent = $attr->transistent;    
        my $storage_key = $attr->storage_key;
        my $current_value = $transistent ? get_attribute($self, $storage_key) : ($array_storage_type ? $self->[$storage_key] : $self->{$storage_key});
        return if ($value && $current_value && $value eq $current_value);
        $attr->deassociate($self);
        if (defined $value) {
            validate_associated_class($attr, $self, $value);
        }
    }
}


=item validate_associated_class

=cut

sub validate_associated_class {
    my ($attr, $self, $value) = @_;
    my $associated_class = $attr->associated_class;
    my $name = $attr->name;
    my $value_type = ref($value)
      or confess "$name must be of the $associated_class type";    
    return &associate_the_other_end if $value_type eq $associated_class;
    return &associate_the_other_end if $value->isa($associated_class);
    confess "$name must be of the $associated_class type, is $value_type";      
}


=item pending_transation

=cut

{   my %pending_association;


=item start_association_process

Start association process (to avoid infinitive look of associating the others ends)
Takes obj reference.

=cut

    sub start_association_process {
    my ($self) = @_;
        $pending_association{$self} = 1;
    }


=item has_pending_association

Returns true is object is during association process.

=cut

    sub has_pending_association {
        my ($self) = @_;
        $pending_association{$self}; 
    }


=item end_association_process

Compleetes association process.

=cut

    sub end_association_process {
        my ($self) = @_;
        delete $pending_association{$self};
    }

}


=item associate_the_other_end

Associate current object reference to the the other end associated class.

TODO

=cut

sub associate_the_other_end {
    my ($attr, $self, $value) = @_;
    my $the_other_end = $attr->the_other_end;
    my $name = $attr->name;
    return if ! $the_other_end || has_pending_association($self);
    my $associated_class = $attr->associated_class;
    my $the_other_end_attribute = $associated_class->meta->attribute($the_other_end);

    confess "missing other end attribute on ". ref($value) . "::" . $the_other_end
        unless $the_other_end_attribute;

    confess "invalid definition for " . ref($self) ."::". $name
    . " - associatied class not defined on " . ref($value) ."::" . $the_other_end
        unless $the_other_end_attribute->associated_class;

    start_association_process($value);
    eval {
            my $association_call = 'associate_' . lc($the_other_end_attribute->perl_type) . '_as_the_other_end';
            $attr->$association_call($self, $value);
    };
    end_association_process($value);
    die $@ if $@;
}



=item associate_scalar_as_the_other_end

=cut

sub associate_scalar_as_the_other_end {
    my ($attr, $self, $value) = @_;
    my $the_other_end = $attr->the_other_end;
    $value->$the_other_end($self);
}


=item associate_hash_as_the_other_end

=cut

sub associate_hash_as_the_other_end {
    my ($attr, $self, $value) = @_;
    my $the_other_end = $attr->the_other_end;
    my $associated_class = $attr->associated_class;
    my $the_other_end_attribute = $associated_class->meta->attribute($the_other_end);
    my $item_accessor = $the_other_end_attribute->item_accessor;
    my $index_by = $the_other_end_attribute->index_by;
    if ($index_by) {
        $value->$item_accessor($self->$index_by, $self);
    } else {
        $value->$item_accessor($self . "", $self);
    }
}


=item associate_array_as_the_other_end

=cut

sub associate_array_as_the_other_end {
    my ($attr, $self, $value) = @_;
    my $the_other_end = $attr->the_other_end;
    my $associated_class = $attr->associated_class;    
    my $the_other_end_attribute = $associated_class->meta->attribute($the_other_end);
    my $other_end_accessor = $the_other_end_attribute->accessor;
    my $setter = "push_${other_end_accessor}";
    $value->$setter($self);
}


=item deassociate

Deassociates assoication values

=cut

sub deassociate {
    my ($attr, $self) = @_;
    my $transistent = $attr->transistent;    
    my $storage_key = $attr->storage_key;
    my $array_storage_type = $attr->storage_type eq 'Array';
    my $value = ($transistent ? get_attribute($self, $storage_key) : ($array_storage_type ? $self->[$storage_key] : $self->{$storage_key})) or return;
    my $the_other_end = $attr->the_other_end;
    return if ! $the_other_end || has_pending_association($value);
    start_association_process($self);
    my $associated_class = $attr->associated_class;
    my $the_other_end_attribute = $associated_class->meta->attribute($the_other_end);
    my $deassociation_call = 'deassociate_' . lc($the_other_end_attribute->perl_type) . '_as_the_other_end';
    if(ref($value) eq 'ARRAY') {
        $the_other_end_attribute->$deassociation_call($self, $_) for @$value;
    } elsif(ref($value) eq 'HASH') {
        $the_other_end_attribute->$deassociation_call($self, $value->{$_}) for(keys %$value);
    } else {
        $the_other_end_attribute->$deassociation_call($self, $value);
    }
    end_association_process($self);
}


=item deassociate_scalar_as_the_other_end

=cut

sub deassociate_scalar_as_the_other_end {
    my ($attr, $self, $the_other_end_obj) = @_;
    $the_other_end_obj or return;
    my $accessor = $attr->accessor;
    $the_other_end_obj->$accessor(undef);
    undef;
}


=item deassociate_hash_as_the_other_end

=cut

sub deassociate_hash_as_the_other_end {
    my ($attr, $self, $the_other_end_obj) = @_;
    my $accessor = $attr->accessor;
    my $value = $the_other_end_obj->$accessor;
    my $index_by = $attr->index_by;
    if ($index_by) {
        delete $value->{$self->$index_by} if exists($value->{$self->$index_by});
    } else {
        my @keys = keys %$value;
        foreach my $k (@keys) {
            if ($value->{$k} eq $self) {
                delete $value->{$k};
                return;
            }
        }
    }
    undef;
}


=item deassociate_array_as_the_other_end

=cut

sub deassociate_array_as_the_other_end {
    my ($attr, $self, $the_other_end_obj) = @_;
    my $accessor = $attr->accessor;
    my $value = $the_other_end_obj->$accessor;
    for my $i (0 .. $#{$value}) {
        if ($value->[$i] eq $self) {
            splice @$value, $i--, 1;
        }
    }
    undef;
}


=item generate_scalar_mutator_method

=cut

sub generate_scalar_mutator_method {
    shift()->generate_mutator_method;
}


=item generate_code_mutator_method

=cut

sub generate_code_mutator_method {
    shift()->generate_mutator_method;
}


=item generate_array_accessor_method

=cut

sub generate_array_accessor_method {
    my $attr = shift; 
    my $mutator = $attr->mutator;
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;
    my $on_read = $attr->on_read;
    my $array_storage_type = $attr->storage_type eq 'Array';
    $array_storage_type ?
    sub {
        my ($self, @args) = @_;
        $self->$mutator(@args) if scalar(@args) >= 1;
        my $result = $on_read ? $on_read->($self, $attr, 'accessor')
        : ($transistent ? get_attribute($self, $storage_key) : ($self->[$storage_key] ||= []));
        wantarray ? @$result : $result;
    }    
    :
    sub {
        my ($self, @args) = @_;
        $self->$mutator(@args) if scalar(@args) >= 1;
        my $result = $on_read ? $on_read->($self, $attr, 'accessor')
        : ($transistent ? get_attribute($self, $storage_key) : ($self->{$storage_key} ||= []));
        wantarray ? @$result : $result;
    };
}


=item generate_array_mutator_method

=cut

sub generate_array_mutator_method {
    shift()->generate_mutator_method;
}


=item generate_hash_accessor_method

=cut

sub generate_hash_accessor_method {
    my $attr = shift; 
    my $mutator = $attr->mutator;
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;
    my $on_read = $attr->on_read;
    my $array_storage_type = $attr->storage_type eq 'Array';
    $attr->associated_class
    ?  $attr->generate_to_many_accessor_method
    :  ($array_storage_type ?
        sub {
            my ($self, @args) = @_;
            $self->$mutator(@args) if scalar(@args) >= 1;
            my $result = $on_read
                ? $on_read->($self, $attr, 'accessor')
                : ($transistent ?  get_attribute($self, $storage_key) : ($self->[$storage_key] ||= {}));
            wantarray ? %$result : $result;
        } 
        : sub {
            my ($self, @args) = @_;
            $self->$mutator(@args) if scalar(@args) >= 1;
            my $result = $on_read
                ? $on_read->($self, $attr, 'accessor')
                : ($transistent ?  get_attribute($self, $storage_key) : ($self->{$storage_key} ||= {}));
            wantarray ? %$result : $result;
     });
}


=item generate_to_many_accessor_method

=cut

sub generate_to_many_accessor_method {
    my $attr = shift; 
    my $mutator = $attr->mutator;
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;
    my $on_read = $attr->on_read;
    my $array_storage_type = $attr->storage_type eq 'Array';
    $array_storage_type ?
    sub {
        my ($self, @args) = @_;
        $self->$mutator(@args) if scalar(@args) >= 1;
        my $result = $on_read
            ? $on_read->($self, $attr, 'accessor') 
            : ($transistent ? get_attribute($self, $storage_key) : ($self->[$storage_key] ||= {}));
        wantarray ? %$result : $result;            
    }    
    :
    sub {
        my ($self, @args) = @_;
        $self->$mutator(@args) if scalar(@args) >= 1;
        my $result = $on_read
            ? $on_read->($self, $attr, 'accessor') 
            : ($transistent ? get_attribute($self, $storage_key) : ($self->{$storage_key} ||= {}));
        wantarray ? %$result : $result;            
    };
} 


=item generate_hash_mutator_method

=cut

sub generate_hash_mutator_method {
    shift()->generate_mutator_method;
}


=item generate_hash_item_accessor_method

=cut

sub generate_hash_item_accessor_method {
    my $attr = shift;
    my $accesor =  $attr->accessor;
    my $on_change = $attr->on_change;
    my $on_read = $attr->on_read;
    sub {
        my $self = shift;
        my ($key, $value) = (@_);
        my $hash_ref = $self->$accesor();
        if(defined $value) {
            $on_change->($self, $attr, 'item_accessor', \$value, $key) or return $hash_ref->{$key}
              if ($on_change);
            $hash_ref->{$key} = $value;
        }
        $on_read ? $on_read->($self, $attr, 'item_accessor', $key) : $hash_ref->{$key};
    };
}


=item generate_hash_add_method

=cut

sub generate_hash_add_method {
    my $attr = shift;
    my $accessor = $attr->accessor;
    my $item_accessor = $attr->item_accessor;
    my $on_change = $attr->on_change;
    my $on_read = $attr->on_read;
    my $index_by = $attr->index_by;
    sub {
        my ($self, @values) = @_;
        my $hash_ref = $self->$accessor();
        foreach my $value (@values) {
            next unless ref($value);
            my $key = ($index_by ? $value->$index_by : $value . "") or confess "unknown key hash at add_$accessor";
            $attr->validate_associated_class($self, $value);
            $on_change->($self, $attr, 'item_accessor', \$value, $key) or return $hash_ref->{$key}
              if ($on_change);
            $hash_ref->{$key} = $value;
        }
        $self;
    };
}


=item generate_scalar_reset_method

=cut

sub generate_scalar_reset_method {
    my $attr = shift;
    my $mutator = $attr->mutator;
    my $index_by = $attr->index_by;
    sub {
        my ($self, ) = @_;
        $self->$mutator(undef);
    };
}


=item generate_scalar_has_method

=cut

sub generate_scalar_has_method {
    my $attr = shift;
    sub {
        my ($self, ) = @_;
        !! $attr->get_value($self);
    };
}


=item generate_hash_reset_method

=cut

sub generate_hash_reset_method {
    my $attr = shift;
    my $mutator = $attr->mutator;
    my $index_by = $attr->index_by;
    sub {
        my ($self, ) = @_;
        $self->$mutator({});
    };
}



=item generate_hash_has_method

=cut

sub generate_hash_has_method {
    my $attr = shift;
    sub {
        my ($self, ) = @_;
        my $value = $attr->get_value($self);
        !! ($value && keys %$value);
    };
}



=item generate_array_reset_method

=cut

sub generate_array_reset_method {
    my $attr = shift;
    my $mutator = $attr->mutator;
    my $index_by = $attr->index_by;
    sub {
        my ($self, ) = @_;
        $self->$mutator([]);
    };
}


=item generate_array_has_method

=cut

sub generate_array_has_method {
    my $attr = shift;
    sub {
        my ($self, ) = @_;
        my $value = $attr->get_value($self);
        !! ($value && @$value);
    };
}


=item generate_hash_remove_method

=cut

#TODO add on_remove trigger

sub generate_hash_remove_method {
    my $attr = shift;
    my $accessor = $attr->accessor;
    my $item_accessor = $attr->item_accessor;
    my $the_other_end = $attr->the_other_end;
    my $meta =  Abstract::Meta::Class::meta_class($attr->associated_class);
    my $reflective_attribute = $the_other_end && $meta ? $meta->attribute($the_other_end) : undef;
    my $index_by = $attr->index_by;
    sub {
        my ($self, @values) = @_;
        my $hash_ref = $self->$accessor();
        foreach my $value (@values) {
            next unless ref($value);
            my $key = ($index_by && ref($value) ? $value->$index_by : $value . "");
            $attr->deassociate($self);
            $reflective_attribute->set_value($hash_ref->{$key}, undef)
                if $reflective_attribute;
            delete $hash_ref->{$key};
        }
        $self;
    };
}



=item generate_array_item_accessor_method

=cut

sub generate_array_item_accessor_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    my $on_change = $attr->on_change;
    my $on_read = $attr->on_read;
    sub {
        my $self = shift;
        my ($index, $value) = (@_);
        my $hash_ref = $self->$accesor();
        if (defined $value) {
            $on_change->($self, $attr, 'item_accessor', \$value, $index) or return $hash_ref->[$index]
              if ($on_change);
            $hash_ref->[$index] = $value;
        }
        $on_read ? $on_read->($self, $attr, 'item_accessor', $index) : $hash_ref->[$index];
    };
}


=item generate_array_push_method

=cut

sub generate_array_push_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    sub {
        my $self = shift;
        my $array_ref = $self->$accesor();
        push @$array_ref, @_;
    };
}


=item generate_array_pop_method

=cut

sub generate_array_pop_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    sub {
        my $self = shift;
        my $array_ref = $self->$accesor();
        pop @$array_ref;
    };
}


=item generate_array_shift_method

=cut

sub generate_array_shift_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    sub {
        my $self = shift;
        my $array_ref= $self->$accesor();
        shift @$array_ref;
    };
}


=item generate_array_unshift_method

=cut

sub generate_array_unshift_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    sub {
        my $self = shift;
        my $array_ref = $self->$accesor();
        unshift @$array_ref, @_;
    };
}


=item generate_array_count_method

=cut

sub generate_array_count_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    sub {
        my $self = shift;
        my $array_ref = $self->$accesor();
        scalar @$array_ref;
    };
}


=item generate_array_add_method

=cut

sub generate_array_add_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    my $accessor = $attr->accessor;
    my $the_other_end = $attr->the_other_end;
    my $associated_class = $attr->associated_class;
    sub {
        my ($self, @values) = @_;
        my $array_ref = $self->$accesor();
        foreach my $value (@values) {
            $attr->validate_associated_class($self, $value, $accessor, $associated_class, $the_other_end);
            push @$array_ref, $value;
        }
        $self;
    };
}


=item generate_array_remove_method

=cut

#TODO add on_remove trigger

sub generate_array_remove_method {
    my $attr = shift;
    my $accesor = $attr->accessor;
    my $accessor = $attr->accessor;
    my $the_other_end = $attr->the_other_end;
    my $meta =  Abstract::Meta::Class::meta_class($attr->associated_class);
    my $reflective_attribute = $the_other_end && $meta ? $meta->attribute($the_other_end) : undef;
    sub {
        my ($self, @values) = @_;
        my $array_ref = $self->$accesor();
        foreach my $value(@values) {
            for my $i (0 .. $#{$array_ref}) {
                if ($array_ref->[$i] && $array_ref->[$i] eq $value) {
                    $reflective_attribute->set_value($value, undef)
                        if $reflective_attribute;
                    splice @$array_ref, $i--, 1;
                }
            }
        }
        $self;
    };
}


=item generate

Returns code reference.

=cut

sub generate {
    my ($self, $method_name) = @_;
    my $call = "generate_" . lc($self->perl_type) . "_${method_name}_method";
    $self->$call;
}


=item set_value

Sets value for attribute

=cut

sub set_value {
    my ($attr, $self, $value) = @_;
    my $array_storage_type = $attr->storage_type eq 'Array';
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;
    if($transistent) {
        set_attribute($self, $storage_key, $value);
    } elsif($array_storage_type) {
        $self->[$storage_key] = $value;
    } else {
        $self->{$storage_key} = $value;
    }
}


=item get_value

Returns value for attribute

=cut

sub get_value {
    my ($attr, $self) = @_;
    my $storage_key = $attr->storage_key;
    my $transistent = $attr->transistent;
    my $array_storage_type = $attr->storage_type eq 'Array';
    if ($transistent) {
        return get_attribute($self, $storage_key);
    } elsif($array_storage_type) {
        $self->[$storage_key];
    } else {
        return $self->{$storage_key};
    }
}


{

    my %storage;

=item get_attribute

Return object's attribute value

=cut

    sub get_attribute {
        my ($self, $key) = @_;
        my $object = $storage{$self} ||= {};
        return $object->{$key};
    }
    
    
=item set_attribute

Sets for passed in object attribue's value

=cut

    sub set_attribute {
        my ($self, $key, $value) = @_;
        my $object = $storage{$self} ||= {};
        $object->{$key} = $value;
    }


=item delete_object

Deletes passed in object's attribute

=cut

    sub delete_object {
        my ($self) = @_;
        delete $storage{$self};
    }
}


1;

__END__

=back

=head1 SEE ALSO

L<Abstract::Meta::Attribute>.

=head1 COPYRIGHT AND LICENSE

The Abstract::Meta::Attribute::Method module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
