use utf8;

package AuditTestRU::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components(qw/Schema::AuditLog/);

__PACKAGE__->load_namespaces(
    result_namespace => '+AuditTestRel::Schema::Result',

    #resultset_namespace => 'AuditTestRU::Schema::ResultSet',
    default_resultset_class => "+DBIx::Class::ResultSet::AuditLog"
);

1;
