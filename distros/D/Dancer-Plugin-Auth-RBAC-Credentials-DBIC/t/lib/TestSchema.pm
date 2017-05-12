package TestSchema;

use strict;
use warnings;

use SQL::Translator 0.11006;    # needed for ->deploy

use parent 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

sub deploy {
    my ($self, @args) = @_;
    $self->SUPER::deploy(@args);

    $self->populate(User => [
        { name => "Foo Bar", login => "foobar", password => "wibble" },
    ]);
    $self->populate(CustomUser => [
        { nickname => "Bar Baz", username => "barbaz", passphrase => "wobble", roles => [
            { rolename => "user" }
        ] },
    ]);
}

1;
