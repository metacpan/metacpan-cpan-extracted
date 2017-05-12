package TestBlogApp::Controller::Blog;
use strict;
use base 'Catalyst::Controller';

use Encode;
use DateTime;

=head1 NAME

TestBlogApp::Controller::Blog

=head1 DESCRIPTION

Controller for TestBlogApp blogs.

=head1 METHODS

=cut

=head2 base

Set up path and stash some useful info.

=cut

sub base : Chained( '/' ) : PathPart( 'blog' ) : CaptureArgs( 0 ) {
	my ( $self, $c ) = @_;
	
	# Stash the current date
	$c->stash->{ now } = DateTime->now;
	
	# Stash the upload_dir setting
	$c->stash->{ upload_dir } = $c->config->{ upload_dir };
	
	# Stash the name of the controller
	$c->stash->{ controller } = 'Blog';
}


=head2 get_posts

Get a page's worth of posts

=cut

sub get_posts {
	my ( $self, $c, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $posts = [$c->model( 'DB::BlogPost' )->search(
		{
			posted   => { '<=' => \q{current_timestamp} },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	)];
	
	return $posts;
}


=head2 get_posts_for_year

Get a year's worth of posts, broken down by months (for archive widget)

=cut

sub get_posts_for_year {
	my ( $self, $c, $year ) = @_;
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			-and => [
				posted   => { '<=' => \'current_timestamp' },
				-nest    => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
			],
		},
		{
			order_by => { -desc => 'posted' },
		},
	);
	
	my $by_months = {};
	foreach my $post ( @posts ) {
		my $month = $post->posted->month;
		push @{ $by_months->{ $month } }, $post;
	}
	
	my $months = ();
	foreach my $month ( sort {$a<=>$b} keys %$by_months ) {
		push @$months, $by_months->{ $month };
	}
	
	return $months;
}


=head2 get_post

=cut

sub get_post {
	my ( $self, $c, $post_id ) = @_;
	
	return $c->model( 'DB::BlogPost' )->find({
		id => $post_id,
	});
}


=head2 get_posts_by_author

Get a page's worth of posts by a particular author

=cut

sub get_posts_by_author {
	my ( $self, $c, $username, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $author = $c->model( 'DB::User' )->find({
		username => $username,
	});
	
	my @posts = $c->model( 'DB::BlogPost' )->search(
		{
			author   => $author->id,
			posted   => { '<=' => \'current_timestamp' },
		},
		{
			order_by => { -desc => 'posted' },
			page     => $page,
			rows     => $count,
		},
	);
	
	return \@posts;
}


=head2 view_posts

Display a page of blog posts.

=cut

sub view_posts : Chained( 'base' ) : PathPart( 'page' ) : OptionalArgs( 2 ) {
	my ( $self, $c, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $posts = $self->get_posts( $c, $page, $count );
	
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ blog_posts } = $posts;
}


=head2 view_recent

Display recent blog posts.

=cut

sub view_recent : Chained( 'base' ) : PathPart( '' ) : Args( 0 ) {
	my ( $self, $c ) = @_;
	
	$c->go( 'view_posts', [ 1, 10 ] );
}

=head2 view_month

Display blog posts from a specified month.

=cut

sub view_month : Chained( 'base' ) : PathPart( '' ) : Args( 2 ) {
	my ( $self, $c, $year, $month ) = @_;
	
	my @blog_posts = $c->model( 'DB::BlogPost' )->search(
		-and => [
			posted => { '<=' => \'current_timestamp' },
			-nest  => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
			-nest  => \[ 'month(posted) = ?', [ plain_value => $month ] ],
		],
	);
	$c->stash->{ blog_posts } = \@blog_posts;
	
	my $one_month = DateTime::Duration->new( months => 1 );
	my $date = DateTime->new( year => $year, month => $month );
	my $prev = $date - $one_month;
	my $next = $date + $one_month;
	
	$c->stash->{ date      } = $date;
	$c->stash->{ prev      } = $prev;
	$c->stash->{ next      } = $next;
	$c->stash->{ prev_link } = $c->uri_for( $prev->year, $prev->month );
	$c->stash->{ next_link } = $c->uri_for( $next->year, $next->month );
	
	$c->stash->{ template  } = 'blog/view_posts.tt';
}


=head2 view_year

Display summary of blog posts in a year.

=cut

sub view_year : Chained( 'base' ) : PathPart( '' ) : Args( 1 ) {
	my ( $self, $c, $year ) = @_;
	
	$c->stash->{ months } = $self->get_posts_for_year( $c, $year );
	$c->stash->{ year   } = $year;
}


=head2 view_posts_by_author

Display a page of blog posts by a particular author.

=cut

sub view_posts_by_author : Chained( 'base' ) : PathPart( 'author' ) : OptionalArgs( 3 ) {
	my ( $self, $c, $author, $page, $count ) = @_;
	
	$page  ||= 1;
	$count ||= 10;
	
	my $posts = $self->get_posts_by_author( $c, $author, $page, $count );
	
	$c->stash->{ author     } = $author;
	$c->stash->{ page_num   } = $page;
	$c->stash->{ post_count } = $count;
	
	$c->stash->{ blog_posts } = $posts;
	
	$c->stash->{ template   } = 'blog/view_posts.tt';
}


=head2 view_post

View a specified blog post.

=cut

sub view_post : Chained( 'base' ) : PathPart( '' ) : Args( 3 ) {
	my ( $self, $c, $year, $month, $url_title ) = @_;
	
	# Stash the post
	$c->stash->{ blog_post } = $c->model( 'DB::BlogPost' )->search({
		url_title => $url_title,
		-nest => \[ 'year(posted)  = ?', [ plain_value => $year  ] ],
		-nest => \[ 'month(posted) = ?', [ plain_value => $month ] ],
	})->first;
	
	unless ( $c->stash->{ blog_post } ) {
		$c->flash->{ error_msg } = 'Failed to find specified blog post.';
		$c->go( 'view_recent' );
	}
	

}



=head2 search

Search the news section.

=cut

sub search {
	my ( $self, $c ) = @_;
	
	if ( $c->request->param( 'search' ) ) {
		my $search = $c->request->param( 'search' );
		my $blog_posts = ();
		my @results = $c->model( 'DB::BlogPost' )->search({
			-and => [
				posted    => { '<=' => \'current_timestamp' },
				-or => [
					title => { 'LIKE', '%'.$search.'%'},
					body  => { 'LIKE', '%'.$search.'%'},
				],
			],
		});
		foreach my $result ( @results ) {
			# Pull out the matching search term and its immediate context
			my $match = '';
			if ( $result->title =~ m/(.{0,50}$search.{0,50})/i ) {
				$match = $1;
			}
			elsif ( $result->body =~ m/(.{0,50}$search.{0,50})/i ) {
				$match = $1;
			}
			# Tidy up and mark the truncation
			unless ( $match eq $result->title or $match eq $result->body ) {
				$match =~ s/^\S*\s/... /;
				$match =~ s/\s\S*$/ .../;
			}
			if ( $match eq $result->title ) {
				$match = substr $result->body, 0, 100;
				$match =~ s/\s\S+\s?$/ .../;
			}
			# Add the match string to the page result
			$result->{ match } = $match;
			warn $result->{ match };
			
			# Push the result onto the results array
			push @$blog_posts, $result;
		}
		$c->stash->{ blog_results } = $blog_posts;
	}
}


1;

