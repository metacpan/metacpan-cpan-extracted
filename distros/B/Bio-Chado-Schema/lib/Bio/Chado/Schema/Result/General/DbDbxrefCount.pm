package Bio::Chado::Schema::Result::General::DbDbxrefCount;
BEGIN {
  $Bio::Chado::Schema::Result::General::DbDbxrefCount::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::General::DbDbxrefCount::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::General::DbDbxrefCount - per-db dbxref counts

=cut

__PACKAGE__->table("db_dbxref_count");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 num_dbxrefs

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "num_dbxrefs",
  { data_type => "bigint", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lMUeCNVzxQf9aiG2glnOvw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
