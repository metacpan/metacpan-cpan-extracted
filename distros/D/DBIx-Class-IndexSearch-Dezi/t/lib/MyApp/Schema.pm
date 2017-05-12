package MyApp::Schema;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw[
    Person
]);

1;
