package Contact::DBSQL::PersonAdaptor;
use strict;
use AutoSQL::DBSQL::ObjectAdaptor;
our @ISA=qw(AutoSQL::DBSQL::ObjectAdaptor);

use AutoCode::ModuleLoader 'ContactSchema';
sub _initialize {
    my ($self, @args)=@_;
    $self->SUPER::_initialize(@args);
}

sub _table_name {
    return 'person';
}

sub _slots {
    return qw(first_name last_name);
}

sub _object_module {
    return AutoCode::ModuleLoader->load('Person');
}

1;
