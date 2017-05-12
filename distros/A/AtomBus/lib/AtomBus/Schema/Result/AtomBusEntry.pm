package AtomBus::Schema::Result::AtomBusEntry;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table("atombus_entry");

__PACKAGE__->add_columns(
  order_id     => { data_type => "integer", is_nullable => 0,
                    is_auto_increment => 1 },
  id           => { data_type => "varchar", is_nullable => 0, size => 100 },
  feed_title   => { data_type => "varchar", is_nullable => 0, size => 255,
                    is_foreign_key => 1 },
  title        => { data_type => "text",    is_nullable => 0 },
  author_name  => { data_type => "varchar", is_nullable => 1, size => 255 },
  author_email => { data_type => "varchar", is_nullable => 1, size => 255 },
  updated      => { data_type => "varchar", is_nullable => 0, size => 100 },
  content      => { data_type => "text",    is_nullable => 0 },
);
__PACKAGE__->set_primary_key("order_id");
__PACKAGE__->add_unique_constraint("id_unique", ["id"]);

__PACKAGE__->belongs_to(
  "feed_title",
  "AtomBus::Schema::Result::AtomBusFeed",
  { title => "feed_title" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


1;

__END__
=pod

=head1 NAME

AtomBus::Schema::Result::AtomBusEntry

=head1 VERSION

version 1.0405

=head1 NAME

AtomBus::Schema::Result::AtomBusEntry

=head1 ACCESSORS

=head2 order_id

  data_type: 'integer'
  is_nullable: 0
  is_auto_increment: 1

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 feed_title

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 255

=head2 title

  data_type: 'text'
  is_nullable: 0

=head2 author_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 author_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 updated

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 content

  data_type: 'text'
  is_nullable: 0

=head1 RELATIONS

=head2 feed_title

Type: belongs_to

Related object: L<AtomBus::Schema::Result::AtomBusFeed>

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

