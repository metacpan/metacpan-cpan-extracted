package AutoSQL::DBSQL::ObjectAdaptor;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor::Abstract;
our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor::Abstract);

sub remove_by_dbID {                                          
    my ($self, $dbid)=@_;                                     
    my $where = $self->_primary_key_name .' = ?';             
    $self->_remove_by_where($where, $dbid);                   
}                                                             
                                                              
sub remove_all {                                              
    shift->_remove_by_where('1');                             
}                                                             
                                                              
sub _remove_by_where {                                        
    my ($self, $where, @values)=@_;                           
    my $sql="DELETE FROM ". $self->_table_name ;              
    $sql .= " WHERE $where";                                  
    my $sth=$self->prepare($sql);                             
    $sth->execute(@values);                                   
}                                                             
                                                              
                                                              
1;
