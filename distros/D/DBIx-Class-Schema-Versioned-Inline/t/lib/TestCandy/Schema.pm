package TestCandy::Schema;
use base 'DBIx::Class::Schema::Versioned::Inline';
use strict;
use warnings;

our $FIRST_VERSION = '0.001';
our $VERSION = '0.001';

__PACKAGE__->load_namespaces();

1;
