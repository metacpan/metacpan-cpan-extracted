package Test::Schema;

use 5.010_000;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components('Sims');

__PACKAGE__->load_namespaces();

1;
__END__
