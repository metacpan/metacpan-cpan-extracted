package TestBlogApp::Schema::Result::Discussion;
use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

TestBlogApp::Schema::Result::Discussion

=cut

__PACKAGE__->table("discussion");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 resource_id

  data_type: 'integer'
  is_nullable: 0

=head2 resource_type

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "resource_id",
  { data_type => "integer", is_nullable => 0 },
  "resource_type",
  { data_type => "varchar", is_nullable => 0, size => 50 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 blog_posts

Type: has_many

Related object: L<TestBlogApp::Schema::Result::BlogPost>

=cut

__PACKAGE__->has_many(
  "blog_posts",
  "TestBlogApp::Schema::Result::BlogPost",
  { "foreign.discussion" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;

