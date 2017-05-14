package AutoSQL::DBSQL::DBIHarness;
use strict;
use AutoSQL::SQLGenerator;

use AutoSQL::DBSQL::DBContext;
our @ISA=qw(AutoSQL::DBSQL::DBContext);

sub create_db {
    my $self=shift;
    my ($dbh, $db_name)=$self->_dbh_dbname(@_);
    my $sql="CREATE DATABASE $db_name";
    $dbh->do("CREATE DATABASE $db_name");
    $self->debug($sql);
    $self->dbname($db_name);
    
    $self->db_handle($self->_db_locator);
}

sub drop_db {
    my $self=shift;
    my ($dbh, $db_name)=$self->_dbh_dbname(@_);
    my $sql="DROP DATABASE $db_name";
    $dbh->do($sql);
    $self->debug($sql);
}

sub _dbh_dbname {
    my $self=shift;
    my $db_name=shift||$self->dbname;
    my $dbh=$self->db_handle($self->_host_locator
   #     (defined $self->dbname)?$self->_db_locator:$self->_host_locator
    );
    return ($dbh, $db_name);
}

sub import_tables {
    my $self=shift;
    my $schema=shift;
    my @sql=AutoSQL::SQLGenerator->generate_table_sql($schema);
    my $dbh =$self->db_handle();
    foreach(@sql){
        $dbh->do($_);
    }
}

1;

__END__

