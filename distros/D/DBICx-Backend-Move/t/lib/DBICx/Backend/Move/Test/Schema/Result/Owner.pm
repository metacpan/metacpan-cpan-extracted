package DBICx::Backend::Move::Test::Schema::Result::Owner;
use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBICx::Backend::Move::Test::Schema::Result::Owner;

=cut

=head1 ACCESSORS

=head2 idx

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 surname

  data_type: 'varchar'
  default_value: '-'
  is_nullable: 0
  size: 80

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 15
  is_enum: work, vacation, sick

=cut

__PACKAGE__->table("owner");
__PACKAGE__->add_columns(
"idx",     { data_type => "integer", extra => { unsigned => 1 }, is_auto_increment => 1, is_nullable => 0, },
"name",    { data_type => "text",    is_nullable => 1 },
"surname", { data_type => "varchar", default_value => "-", is_nullable => 0, size => 80 },
"title",   { data_type => "varchar", is_nullable => 1, size => 15 },
"status",  { data_type => "VARCHAR", default_value => "work", is_nullable => 1, size => 255, is_enum => 1, extra => { list => [qw(work vacation sick)] } },
);
__PACKAGE__->set_primary_key('idx');


1;
