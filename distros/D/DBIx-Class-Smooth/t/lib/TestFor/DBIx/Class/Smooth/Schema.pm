use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

sub schema_version { 1 }

use parent 'DBIx::Class::Smooth::Schema';
use experimental qw/postderef signatures/;

__PACKAGE__->load_namespaces;

1;
