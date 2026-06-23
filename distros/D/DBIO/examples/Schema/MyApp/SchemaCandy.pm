package MyApp::SchemaCandy;

use warnings;
use strict;

use base qw/DBIO::Schema/;
__PACKAGE__->load_namespaces(
  result_namespace => 'SchemaCandy::Result',
);

1;
