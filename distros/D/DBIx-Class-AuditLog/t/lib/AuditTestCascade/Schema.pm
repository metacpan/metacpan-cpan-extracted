use utf8;

package AuditTestCascade::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components(qw/Schema::AuditLog/);

__PACKAGE__->load_namespaces(
    default_resultset_class => "+DBIx::Class::ResultSet::AuditLog" );

1;
