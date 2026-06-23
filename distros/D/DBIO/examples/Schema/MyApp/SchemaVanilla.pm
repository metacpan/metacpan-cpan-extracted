package MyApp::SchemaVanilla;

use warnings;
use strict;

use base qw/DBIO::Schema/;
__PACKAGE__->load_namespaces(
  result_namespace => 'SchemaVanilla::Result',
);

1;
