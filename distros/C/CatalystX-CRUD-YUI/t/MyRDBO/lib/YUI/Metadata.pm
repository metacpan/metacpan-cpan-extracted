package YUI::Metadata;

use strict;

use base 'Rose::DB::Object::Metadata';
use YUI;

sub init_db {
    my $self = shift;
    my $db   = YUI->init_db;
    $self->{db_id} = $db->{id};
    return $db;
}

1;
