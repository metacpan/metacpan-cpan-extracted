package AutoSQL::DBSQL::ObjectAdaptor::Abstract;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoCode::AccessorMaker ('$'=>[qw(dbadaptor factory model)]);

sub _initialize {
    my ($self, @args)=@_;
    my ($dbadaptor, $dba, $type, $factory, $model)=
        $self->_rearrange([qw(DBADAPTOR DBA TYPE FACTORY MODEL)], @args);
    $dbadaptor ||= $dba;
    $self->dbadaptor($dbadaptor);
    $self->factory($factory);
    $self->model($model);
}

sub db_handle { shift->dbadaptor->db_handle; }
sub prepare { shift->dbadaptor->prepare(@_); }
sub _primary_key_name { shift->model->primary_key_name; }
sub _table_name { shift->model->table_name; }
sub _slots { shift->model->get_scalar_slots; }

sub _slot_table_name {
    my $table=shift->_table_name;
    "$table\_" . shift;
}

sub debug {
    my ($self, $msg)=@_;
    my $class=ref($self)||$self;
    print STDERR "DEBUG IN $class\n$msg\n";
}

1;

