package DBTestHarness;
use strict;
use Sys::Hostname 'hostname';

use AutoSQL::DBSQL::DBIHarness;
our @ISA=qw(AutoSQL::DBSQL::DBIHarness);
use AutoCode::AccessorMaker(
    '$' => ['drop_during_destroy']
);

our $counter=0;

sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
    my($ddd, $create_db, $schema)=
        $self->_rearrange([qw(drop_during_destroy create_db schema)], @args);
    
    $ddd=1 unless defined $ddd;
#    $ddd||=1; # unless(defined $ddd and $ddd==0);
    $self->drop_during_destroy($ddd);
    $counter++;

    defined $create_db and $self->create_test_db;
    defined $schema and $self->import_tables($schema);
}

sub _create_db_name {
    my $self=shift;
    my $host=hostname;
    my $db_name="_test_autosql_${host}_$$.$counter";
    $db_name =~ s{\W}{_}g;
    return $db_name;
}

sub create_test_db {
    my $self=shift;
    $self->dbname($self->_create_db_name);
    $self->create_db($self->_create_db_name);
}

sub DESTROY {
    my $self=shift;
    if($self->drop_during_destroy > 0){
        $self->drop_db($self->_create_db_name);
    }
}
1;

