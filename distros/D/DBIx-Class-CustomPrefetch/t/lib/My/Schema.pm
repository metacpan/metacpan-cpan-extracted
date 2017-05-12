package My::Schema;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/Status User/);

1;
