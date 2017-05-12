package TestBlogApp::Schema::Result::User;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

TestBlogApp::Schema::Result::User

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 200

=head2 firstname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 surname

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 display_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 display_email

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 website

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 profile_pic

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 bio

  data_type: 'text'
  is_nullable: 1

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 postcode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 admin_notes

  data_type: 'text'
  is_nullable: 1

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 200 },
  "firstname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "surname",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "display_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "display_email",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "website",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "profile_pic",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "bio",
  { data_type => "text", is_nullable => 1 },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "postcode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "admin_notes",
  { data_type => "text", is_nullable => 1 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 blog_posts

Type: has_many

Related object: L<TestBlogApp::Schema::Result::BlogPost>

=cut

__PACKAGE__->has_many(
  "blog_posts",
  "TestBlogApp::Schema::Result::BlogPost",
  { "foreign.author" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 recent_blog_posts

Get recent blog posts by this user that aren't future-dated

=cut

sub recent_blog_posts {
	my( $self, $count ) = @_;
	
	$count ||= 10;
	
	my $now = DateTime->now;
	
	return $self->blog_posts->search(
		{
			posted   => { '<=' => $now },
		},
		{
			order_by => { -desc => 'posted' },
			rows     => $count,
		}
	);
}

1;

