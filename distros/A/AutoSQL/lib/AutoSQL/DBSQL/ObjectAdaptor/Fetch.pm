package AutoSQL::DBSQL::ObjectAdaptor::Fetch;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor::Abstract;
our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor::Abstract);

sub fetch_by_dbID {
    my ($self, $dbid)=@_;
    my $where = $self->_primary_key_name .' = ?';
    my @objs = $self->_fetch_by_where($where, [$dbid]);
    return $objs[0];
}

sub fetch_by_FK {
    my ($self, $fks)=@_;
    my @fk_slots=grep!/parent_id/,
        (defined $fks and ref($fks)eq'HASH')?keys(%$fks):();
    my $where=join ' and ', map {"$_=?"} @fk_slots;
    my @values=map{$fks->{$_}}@fk_slots;
    return $self->_fetch_by_where($where, \@values);
}

# examples to use this method: fetch_by_dbID, fetch_by_condition, 
# PersonAdaptor::fetch_by_first_name
#
sub _fetch_by_where {
    my ($self, $where, $values)=@_;

    my $model=$self->model;
    my $table=$self->_table_name;
    my @slots=$self->_slots;
    push @slots, 'dbid';
    my @columns = map {($_ eq'dbid')?$self->_primary_key_name:$_} @slots;
    my $sql = 'SELECT '. join(', ', @columns) .' FROM '. $self->_table_name;
    $sql .= " WHERE $where";

    my $sth=$self->prepare($sql);
    $sth->execute(@$values);
    my @objs;
    my $vp=$self->factory->make_module($self->model->type);
    while(my @array = $sth->fetchrow_array){
        my @args;
        my $dbid;
        for(my $i=0; $i<@slots; $i++){
            push @args, "-".$slots[$i] => $array[$i];
            $dbid = $array[$i] if $slots[$i] eq 'dbid';
            
        }
        push @args, -dbID => $dbid;
        push @args, -adaptor => $self;
        # Then fetch array slots, and children.
        foreach my $slot($model->get_array_slots){
            my $slot_plural=$model->schema->get_plural($slot);
            my @slots=$self->__fetch_array_slot($slot, {parent_id=>$dbid});
            push @args, "-$slot_plural", \@slots;
        }
        my $fks={
            $self->_primary_key_name => $dbid,
            parent_id=>$dbid
        };
        foreach my $child($model->get_scalar_children){       
            my $content = ($model->_classify_value_attribute($child))[2];   
            my @children=$self->__fetch_scalar_child($content, $fks);       
            $self->warn("scalar child has more than one element")
                if(scalar(@children) > 1);                    
            push @args, '-'.$child, $children[0] if(scalar(@children)>0);   
        }                                                     
        foreach my $child($model->get_array_children){        
            my $content = ($model->_classify_value_attribute($child))[2];   
            my @children=$self->__fetch_scalar_child($content, $fks);       
            push @args, '-'. $model->schema->get_plural($child), \@children;
        }                                                     
        push @objs, $vp->new(@args);                          
    }                                                         
    return @objs;                                             
}

sub __fetch_array_slot {                                      
    my ($self, $slot, $fks)=@_;                               
    my $parent_id=$fks->{parent_id};                          
    my $primary_key_name=$self->_primary_key_name;            
    my $table_slot =$self->_slot_table_name($slot);           
                                                              
    my $sql="SELECT $slot FROM $table_slot WHERE $primary_key_name=?";      
    my $sth=$self->prepare($sql);                             
    $sth->execute($parent_id);                                
    my @slots;                                                
    while(my @array=$sth->fetchrow_array){                    
        push @slots, $array[0];                               
    }                                                         
    return @slots;                                            
}                                                             
                                                              
sub __fetch_scalar_child {                                    
    my ($self, $slot, $fks)=@_;                               
    my $parent_id=$fks->{parent_id};                          
    my $primary_key_name=$self->_primary_key_name;            
    $fks->{$primary_key_name}=$parent_id;                     
    my $child_adaptor=$self->dbadaptor->get_object_adaptor($slot);
    my @children=$child_adaptor->fetch_by_FK($fks);           
    return @children;                                         
}

1;
