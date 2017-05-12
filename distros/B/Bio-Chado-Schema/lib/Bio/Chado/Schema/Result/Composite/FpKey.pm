package Bio::Chado::Schema::Result::Composite::FpKey;
BEGIN {
  $Bio::Chado::Schema::Result::Composite::FpKey::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Composite::FpKey::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Composite::FpKey

=cut

__PACKAGE__->table("fp_key");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 pkey

  data_type: 'varchar'
  is_nullable: 1
  size: 1024

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "pkey",
  { data_type => "varchar", is_nullable => 1, size => 1024 },
  "value",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m983SWAQ0+59Om4pCwFhQA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
