package AutoSQL::DBSQL::ObjectAdaptor::Store;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor::Abstract;
our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor::Abstract);

sub store {                                                   
    my ($self, $obj)=@_;                                      
    my $verb=(defined $obj->dbID)?'_update':'_insert';        
    $self->$verb($obj);                                       
} 

sub _insert {
    my ($self, $obj, $fks)=@_;

    my $model=$self->model;
    my @fk_slots =(defined $fks and ref($fks)eq'HASH')?keys(%$fks):();
    # Filter out the useless one for this type, such as parent_id.
    @fk_slots=grep{$_ ne 'parent_id'}@fk_slots;
#    print "\@fk_slots: @fk_slots\n";
    while(my ($k, $v)=each %$fks){
        print "\t$k\t$v|\n";
    }

# STORE shared children, like Location to Person, first , before storing the o j.
    # 
    my $table=$self->_table_name;
    my @slots=$self->_slots;

    my @total_slots;

    push @total_slots, @slots, @fk_slots;
    my @methods=@slots;

    my $sql="INSERT $table (". join(',', @total_slots) .")\n";
    $sql .= "VALUES (". join(',', map{'?'}@total_slots) .")\n";
    $self->debug("Originally made in ". __PACKAGE__ ."\n$sql\n");
    my $sth=$self->prepare($sql);

    { # For each obj
        my @values=map{$obj->$_}@methods;
        push @values, map{$fks->{$_}}@fk_slots;
#        print "@values\n";
#        @values =map{"'$_'"}@values;
        $self->debug("Originally made in ". __PACKAGE__ ."\nvalues:". join('|',@values). "|\n");
        $sth->execute(@values);
        my $dbid = $sth->{mysql_insertid};
        $obj->dbID($dbid); # if $obj->can('dbid');
        $obj->adaptor($self); # if $obj->can('adaptor');

        # insert array slots.
        foreach my $slot($model->get_array_slots){
            my $slot_plural=$model->schema->get_plural($slot);
            my $get_method="get_$slot_plural";
            foreach my $v ($obj->$get_method){

                $self->__insert_array_slot($slot, $v, {parent_id=>$dbid});
            }
        }
        # insert scalar children.
        foreach my $child($model->get_scalar_children){
            my $v=$obj->$child;
            next unless defined $v;
            my $content = ($model->_classify_value_attribute($child))[2];
            $self->__insert_scalar_child($content, $v, {parent_id=>$dbid});
        }
        # insert array children.
        foreach my $child($model->get_array_children){
            my $child_plural=$model->schema->get_plural($child);
            my $get_method="get_$child_plural";
            foreach my $v($obj->$get_method){
                my $content = ($model->_classify_value_attribute($child))[2];
                $self->__insert_scalar_child($content, $v, {parent_id=>$dbid});
            }
        }
        #
        # Before leaving this method, help to stored the un-stored friend
#        foreach my $friend ($schema->find_friends($model->type)){
            # store the friend first then get the friend_id for later's joint table.
            # 
#        }
        return $dbid;
    }
                                                              
}

sub __insert_array_slot {                                     
    my($self, $slot, $value, $fks)=@_;                        
    $self->throw("no fks or fks is not hash ref")             
        unless(defined $fks and ref($fks) eq'HASH');          
    $self->throw("no parent_id in fks") unless exists $fks->{parent_id};    
    my $parent_id = $fks->{parent_id};                        
                                                              
    my $table=$self->_table_name;                             
    my $primary_key_name=$self->_primary_key_name;            
    my $table_slot =$self->_slot_table_name($slot);           
    my $sql ="INSERT $table_slot ($slot, $primary_key_name)\n";
    $sql .="VALUES (?, ?)\n";                                 
    my $sth=$self->prepare($sql);                             
    $sth->execute($value, $parent_id);                        
    my $dbid = $sth->{mysql_insertid};                        
    return $dbid;                                             
}                                                             
                                                              
sub __insert_scalar_child {                                   
    my ($self, $slot, $value, $fks)=@_;                       
    $self->throw("no fks or fks is not hash ref")             
        unless(defined $fks and ref($fks) eq'HASH');          
    $self->throw("no parent_id in fks") unless exists $fks->{parent_id};    
    my $parent_id = $fks->{parent_id};                        
                                                              
#    print "parent_id: $parent_id\n";                         
    my $table_name=$self->_table_name;                        
    my $fk="$table_name\_id";                                 
    $fks->{$fk}=$parent_id;                                   
    my $foriegn_adaptor = $self->dbadaptor->get_object_adaptor($slot);      
    my $foreign_dbid = $foriegn_adaptor->_insert($value,$fks);
                                                              
}                                                             
                                                              
sub __insert_array_child {                                    
    my ($self, $slot, $value, $fks)=@_;                       
                                                              
}                                                             
sub _update {                                                 
    my ($self, $obj)=@_;                                      
}

1;
