package MyApp::SchemaCake;

use warnings;
use strict;

use base qw/DBIO::Schema/;
__PACKAGE__->load_namespaces(
  result_namespace => 'SchemaCake::Result',
);

1;
