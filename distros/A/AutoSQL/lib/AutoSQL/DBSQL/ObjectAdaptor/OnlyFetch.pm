package AutoSQL::DBSQL::ObjectAdaptor::OnlyFetch;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor::Fetch;
our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor::Fetch);

sub _only_fetch_by_where {
    my ($self, $slot, $where, $values)=@_;
    my $sql = "SELECT $slot FROM ". $self->_table_name ." WHERE $where";
    print STDERR ref($self) ."::_only_fetch_by_where $sql\n";
    my $sth=$self->prepare($sql);
    $sth->execute(@$values);
    my @rets;
    while(my @array = $sth->fetchrow_array){
        push @rets, $array[0];
    }
    return @rets;
}

sub _only_fetch_array_slot_by_where {
    ;
}


1;
