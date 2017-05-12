package t::lib::Schema3;
use base 'DBIx::Class::Schema';
__PACKAGE__->load_namespaces;
sub deploy {
    my $self = shift;
    $self->next::method(@_);
    
    $self->resultset('User')->populate(
        [
            [ 'id', 'username', 'password', 'name' ],
            [ 1,    'bananarepublic',     'whatever',     'Banana' ],
        ]
    );
}

1;
