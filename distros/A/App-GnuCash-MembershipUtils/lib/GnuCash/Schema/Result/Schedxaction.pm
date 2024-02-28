use utf8;
package GnuCash::Schema::Result::Schedxaction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Schedxaction

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<schedxactions>

=cut

__PACKAGE__->table("schedxactions");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 name

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 enabled

  data_type: 'integer'
  is_nullable: 0

=head2 start_date

  data_type: 'text'
  is_nullable: 1
  size: 8

=head2 end_date

  data_type: 'text'
  is_nullable: 1
  size: 8

=head2 last_occur

  data_type: 'text'
  is_nullable: 1
  size: 8

=head2 num_occur

  data_type: 'integer'
  is_nullable: 0

=head2 rem_occur

  data_type: 'integer'
  is_nullable: 0

=head2 auto_create

  data_type: 'integer'
  is_nullable: 0

=head2 auto_notify

  data_type: 'integer'
  is_nullable: 0

=head2 adv_creation

  data_type: 'integer'
  is_nullable: 0

=head2 adv_notify

  data_type: 'integer'
  is_nullable: 0

=head2 instance_count

  data_type: 'integer'
  is_nullable: 0

=head2 template_act_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "name",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "enabled",
  { data_type => "integer", is_nullable => 0 },
  "start_date",
  { data_type => "text", is_nullable => 1, size => 8 },
  "end_date",
  { data_type => "text", is_nullable => 1, size => 8 },
  "last_occur",
  { data_type => "text", is_nullable => 1, size => 8 },
  "num_occur",
  { data_type => "integer", is_nullable => 0 },
  "rem_occur",
  { data_type => "integer", is_nullable => 0 },
  "auto_create",
  { data_type => "integer", is_nullable => 0 },
  "auto_notify",
  { data_type => "integer", is_nullable => 0 },
  "adv_creation",
  { data_type => "integer", is_nullable => 0 },
  "adv_notify",
  { data_type => "integer", is_nullable => 0 },
  "instance_count",
  { data_type => "integer", is_nullable => 0 },
  "template_act_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aQiFADOa0Oriv7nrPbGwng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
