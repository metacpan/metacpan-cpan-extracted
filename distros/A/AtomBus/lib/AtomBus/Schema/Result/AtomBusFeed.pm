package AtomBus::Schema::Result::AtomBusFeed;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table("atombus_feed");

__PACKAGE__->add_columns(
  id =>           { data_type => "varchar", is_nullable => 0, size => 100 },
  title =>        { data_type => "varchar", is_nullable => 0, size => 255 },
  author_name =>  { data_type => "varchar", is_nullable => 1, size => 255 },
  author_email => { data_type => "varchar", is_nullable => 1, size => 255 },
  updated =>      { data_type => "varchar", is_nullable => 0, size => 100 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("title_unique", ["title"]);

__PACKAGE__->has_many(
  "atombus_entries",
  "AtomBus::Schema::Result::AtomBusEntry",
  { "foreign.feed_title" => "self.title" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;

__END__
=pod

=head1 NAME

AtomBus::Schema::Result::AtomBusFeed

=head1 VERSION

version 1.0405

=head1 NAME

AtomBus::Schema::Result::AtomBusFeed

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

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

=head1 RELATIONS

=head2 atombus_entries

Type: has_many

Related object: L<AtomBus::Schema::Result::AtomBusEntry>

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

