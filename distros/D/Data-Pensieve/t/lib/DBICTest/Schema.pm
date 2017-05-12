package DBICTest::Schema;

use strict;
use warnings;
use base "DBIx::Class::Schema";

__PACKAGE__->load_classes(qw/
    Revision
    RevisionData
/);

1;


