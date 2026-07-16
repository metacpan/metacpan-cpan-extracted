package Schema::Create;

use base 'DBIx::Class::Schema';

use strict;
use warnings;

our $VERSION = 1;

__PACKAGE__->load_namespaces(
  default_resultset_class => "+Schema::DefaultRS");



1;
