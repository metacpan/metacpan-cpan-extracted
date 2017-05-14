package AutoSQL::Schema;
use strict;
use vars qw(@ISA);
use AutoCode::Schema;
our @ISA=qw(AutoCode::Schema);
use AutoSQL::TableModel;

use AutoCode::AccessorMaker('$'=>[qw(tables module_table_map)]);

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    
    my ($tables, $module_table_map)=
        $self->_rearrange( [qw(TABLES MODULE_TABLE_MAP )], @args);
    
    $self->tables($tables);
    $self->module_table_map($module_table_map);
}

# This method is to be replaced with $module_table map in schema.
our %TABLE_MODELS;
sub get_table_model {
    my ($self, $type)=@_;
    return $TABLE_MODELS{$type} if exists $TABLE_MODELS{$type};
    my $model = AutoSQL::TableModel->new(
        -schema => $self,
        -type => $type
    );
    $TABLE_MODELS{$type}=$model;
    return $model;
}

1;
