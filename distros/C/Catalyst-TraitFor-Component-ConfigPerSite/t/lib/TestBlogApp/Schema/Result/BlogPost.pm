package TestBlogApp::Schema::Result::BlogPost;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp" );

=head1 NAME

TestBlogApp::Schema::Result::BlogPost

=cut

__PACKAGE__->table("blog_post");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 url_title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 body

  data_type: 'text'
  is_nullable: 0

=head2 author

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 posted

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 discussion

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "url_title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "body",
  { data_type => "text", is_nullable => 0 },
  "author",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "posted",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "discussion",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<TestBlogApp::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "author",
  "TestBlogApp::Schema::Result::User",
  { id => "author" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 discussion

Type: belongs_to

Related object: L<TestBlogApp::Schema::Result::Discussion>

=cut

__PACKAGE__->belongs_to(
  "discussion",
  "TestBlogApp::Schema::Result::Discussion",
  { id => "discussion" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

# Created by DBIx::Class::Schema::Loader v0.07001 @ 2010-08-05 21:13:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DH+fL73Ll8qT7jcXgL0itQ

# TODO/Notes
# We could have shared content via templates for blogs, same as for cms
# This would allow pulling blog name, title, and other branding based on templates associated with a blog when multiple blogs are reinstated


=head2 comment_count

Return the total number of comments on this post

=cut

sub comment_count {
	my ( $self ) = @_;
	return 0;
}


=head2 teaser

Return the specified number of leading paragraphs from the body text

=cut

sub teaser {
	my ( $self, $count ) = @_;
	
	$count ||= 1;
	
	my @paragraphs = split '</p>', $self->body;
	
	my $teaser = '';
	my $i = 1;
	foreach my $paragraph ( @paragraphs ) {
		$teaser .= $paragraph .'</p>';
		last if $i++ >= $count;
	}
	
	return $teaser;
}


# EOF
1;

