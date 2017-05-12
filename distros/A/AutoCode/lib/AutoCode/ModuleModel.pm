package AutoCode::ModuleModel;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoCode::AccessorMaker (
    '$' => [qw(schema type _value_attributes _directive_attributes)],
    '@' => ['scalar_attribute', 'array_attribute', 'scalar_slot', 'array_slot',
        [qw(scalar_child scalar_children)], [qw(array_child array_children)],
        'isa']
);

use AutoCode::AttributeType;

sub _initialize {
    my ($self, @args)=@_;
    my ($schema, $type)=$self->_rearrange([qw(SCHEMA TYPE)], @args);
    defined $schema or $self->throw("NO schema!");
    $self->schema($schema);
    defined $type or $self->throw("NO type!");
    $self->type($type);

    $self->__initialize_value_attributes; # value_attribute, directive_attribute 
    $self->__initialize_directive_attributes;

}

sub __initialize_value_attributes {
    my $self=shift;
    my ($schema, $type)=($self->schema, $self->type);
    my %module =%{$schema->_get_module_definition($type)};
    
    my (%value_attrs, %directive_attrs);
    $value_attrs{$_}=$module{$_} foreach grep /^[a-zA-Z_]/, keys %module;
    $directive_attrs{$_}=$module{$_} foreach grep /^\W/, keys %module;
    $self->_value_attributes(\%value_attrs);
    $self->_directive_attributes(\%directive_attrs);
    
    # initialize_value_attributes
    $self->add_scalar_attribute($_) 
        foreach grep {$value_attrs{$_}=~/^\$/} keys %value_attrs;
    $self->add_array_attribute($_)
        foreach grep {$value_attrs{$_}=~/^\@/} keys %value_attrs;

    foreach my $attr ($self->get_scalar_attributes){
        my $kind = ($self->_classify_value_attribute($attr))[1];
        if($kind =~ /^[PE]$/){ $self->add_scalar_slot($attr);
        }elsif($kind eq 'M'){ $self->add_scalar_child($attr);
        }else{ $self->throw("$kind of Attr[$attr] is not valid kind"); }
    }
    foreach my $attr ($self->get_array_attributes){
        my $kind = ($self->_classify_value_attribute($attr))[1];
        if($kind eq 'P'){ $self->add_array_slot($attr);     }
        elsif($kind eq 'M'){ $self->add_array_child($attr); }
        else{ $self->throw("$kind of Attr[$attr] is not valid kind"); }
    }
}


sub __initialize_directive_attributes {
    my $self=shift;
    my %d_attrs=%{$self->_directive_attributes};
    if(exists $d_attrs{'@ISA'}){
        my $isa=$d_attrs{'@ISA'};
        $self->add_isa((ref($isa) eq'ARRAY')?@$isa:$isa);
    }
}

sub get_all_value_attributes {
    return keys %{shift->_value_attributes};
}

sub get_value_attribute {
    my ($self, $attr)=@_;
    my %attrs=%{$self->_value_attributes};
    return $attrs{$attr};
}

sub get_all_directive_attributes {
    keys %{shift->_directive_attributes};
}

sub get_directive_attribute {
    my ($self, $attr)=@_;
    my %attrs=%{$self->_directive_attributes};
    return $attrs{$attr};
}

sub _classify_value_attribute {
    my ($self, $attr)=@_;
    my $value = $self->get_value_attribute($attr);
    
    return AutoCode::AttributeType->classify($value);
    
}


1;
