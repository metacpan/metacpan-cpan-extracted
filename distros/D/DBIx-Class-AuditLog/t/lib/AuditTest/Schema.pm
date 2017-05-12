use utf8;

package AuditTest::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_components(qw/Schema::AuditLog/);

__PACKAGE__->load_namespaces(
    default_resultset_class => "+DBIx::Class::ResultSet::AuditLog" );

# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-02-13 15:52:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4wuoDrMqhDTpIQKAkG/zEA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
