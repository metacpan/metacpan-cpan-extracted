package AutoSQL::TableModel;
use strict;
use AutoCode::ModuleModel;
our @ISA=qw(AutoCode::ModuleModel);
use AutoCode::AccessorMaker(
    '$'=>[qw(table_name primary_key_name slots fk_slots)]);

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    
    $self->table_name(lc $self->type);
    $self->primary_key_name($self->table_name .'_id');

    my %module=%{$self->schema->_get_module_definition($self->type)};
    my @subs = grep /^[_a-zA-Z]/, keys %module;
#    my %v_attrs=%{$self->value_attribute};
   
    
 #   my @slots = grep { my ($context, $kind)=($self->_classify_value_attribute($_))[0, 1];
 #       $kind =~/^[PM]$/; }keys %v_attrs; 
#    $module{$_} =~ /^\$/} @{$self->value_attribute};
    
#    my @fk_slots = grep { ($self->_classify_value_attribute($_))[1] eq 'M';
#    }keys %v_attrs;
    
#    $module{$_} =~ /^[@%$](\.+)/} @subs;
    my @slots=grep{ 
        my ($context, $kind)=($self->_classify_value_attribute($_))[0, 1];
        $context eq'$' and $kind =~/^[PE]$/;    
    }$self->get_scalar_attributes;
    my @scalar_children=grep{
        my ($context, $kind)=($self->_classify_value_attribute($_))[0, 1];
        $kind eq 'M';
    }$self->get_scalar_attributes;
    my @array_children=grep{
        my ($context, $kind)=($self->_classify_value_attribute($_))[0, 1];
        $kind eq'M';
    }$self->get_array_attributes;
    my $type=$self->type;
#    print STDERR "Type $type 's children: scalar(@scalar_children), array(@array_children)\n";
    $self->slots(\@slots);
    
}


# figure out the table schema that was originally in schema, but now trying to
# be replaced by this..
#
#
1;
