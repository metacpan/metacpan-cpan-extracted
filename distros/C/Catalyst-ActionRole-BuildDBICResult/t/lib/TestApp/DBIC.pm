package # hide from PAUSE
  TestApp::DBIC;

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;
our $VERSION = '0.001';

__PACKAGE__->load_namespaces(default_resultset_class => 'DefaultRS');

1;


