use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::CDToProducer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::CDToProducer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cd_to_producer>

=cut

__PACKAGE__->table("cd_to_producer");

=head1 ACCESSORS

=head2 cd

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 producer

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 attribute

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cd",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "producer",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "attribute",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cd>

=item * L</producer>

=back

=cut

__PACKAGE__->set_primary_key("cd", "producer");

=head1 RELATIONS

=head2 cd

Type: belongs_to

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->belongs_to(
  "cd",
  "CDTest::Schema::Result::CD",
  { cdid => "cd" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 producer

Type: belongs_to

Related object: L<CDTest::Schema::Result::Producer>

=cut

__PACKAGE__->belongs_to(
  "producer",
  "CDTest::Schema::Result::Producer",
  { producerid => "producer" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Aubeu74j5b45x4ijKxAaYw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
