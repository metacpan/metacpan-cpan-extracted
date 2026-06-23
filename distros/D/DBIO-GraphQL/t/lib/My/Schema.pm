package My::Schema;

use DBIO 'Schema';

__PACKAGE__->load_components('SQLite');
__PACKAGE__->load_namespaces;

1;
