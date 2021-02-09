use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Producer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Producer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<producer>

=cut

__PACKAGE__->table("producer");

=head1 ACCESSORS

=head2 producerid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "producerid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</producerid>

=back

=cut

__PACKAGE__->set_primary_key("producerid");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 cd_to_producers

Type: has_many

Related object: L<CDTest::Schema::Result::CDToProducer>

=cut

__PACKAGE__->has_many(
  "cd_to_producers",
  "CDTest::Schema::Result::CDToProducer",
  { "foreign.producer" => "self.producerid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gTrUus9gznihHyopcAG82A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
