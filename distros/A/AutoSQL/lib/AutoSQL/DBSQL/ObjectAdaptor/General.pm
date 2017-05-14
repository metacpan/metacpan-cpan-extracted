package AutoSQL::DBSQL::ObjectAdaptor::General;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor::Abstract;
our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor::Abstract);

sub list_all_dbID {
    my $self=shift;
    my @ids;
    my $sql="SELECT ". $self->_primary_key_name ." FROM ". $self->_table_name;
    my $sth=$self->prepare($sql);
    while(my @array=$sth->fetchrow_array){ push @ids, $array[0]; }
    return @ids;
}

1;
