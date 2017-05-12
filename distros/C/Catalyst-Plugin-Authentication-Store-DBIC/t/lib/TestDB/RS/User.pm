package TestDB::RS::User;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub auto_create {
    my ($self,$id,$password) = @_;
    return $self->create({ username => $id, password => $password });
}

1;
