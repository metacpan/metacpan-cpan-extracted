package Bio::Chado::Schema::Result::Sequence::Cvtermsynonym;
BEGIN {
  $Bio::Chado::Schema::Result::Sequence::Cvtermsynonym::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Sequence::Cvtermsynonym::VERSION = '0.20000';
}

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cvtermsynonym");
__PACKAGE__->add_columns(
  "cvtermsynonym_id",
  {
    data_type => "integer",
    default_value => "nextval('cvtermsynonym_cvtermsynonym_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "cvterm_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "synonym",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  "type_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("cvtermsynonym_id");
__PACKAGE__->add_unique_constraint("cvtermsynonym_c1", ["cvterm_id", "synonym"]);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-08-16 09:31:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u0y+66oKiMPqn2BMOzIk1A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
