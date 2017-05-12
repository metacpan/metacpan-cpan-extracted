package CatalystX::Widget::Paginator;

=head1 NAME

CatalystX::Widget::Paginator - HTML widget for digg-style paginated DBIx::ResulSet

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

use List::Util qw( min max );
use Moose;
use Moose::Util::TypeConstraints;
use POSIX qw( ceil floor );

extends 'Catalyst::Plugin::Widget::Base';
with    'Catalyst::Plugin::Widget::WithResultSet';


=head1 DESCRIPTION

This widget intended to solve the general problem with paginated results.
Assume that we have a set of objects (L<DBIx::Class::ResultSet>) and (probably)
the L<Catalyst::Request> parameter indicates the current page. Created widget
receives resultset and additional arguments, validates pagination and can be
queried about pagination and objects presented for current page.

For the correct determination of the current page widget makes taking
the following steps:

1. Checks for constructor arguments: C<page>, C<rows>. If specified, uses them.

2. Checks for already paginated resultset (see L<DBIx::Class::ResultSet>
C<rows> and C<page> attributes for details). If specified - uses them.

3. Uses the default value for C<rows> (10).

4. If attribute C<page_auto> is enabled (default), try to get request parameter
named C<page_arg> for C<page> value.

5. Uses the default value for C<page> (1).

After successful identification C<page> and C<rows> attributes, the widget
checks their validity for a specified resultset. Processing logic for non-valid
attributes defined by C<invalid> attribute.

Created instance of a widget can be queried about its attributes.
For example: C<last>, C<pages>, C<objects>, etc.

Widget is converted to a string represetning the HTML table with page numbers
as links in the cells. Design details can be configured with C<style> and
C<style_prefix> attributes.


=head1 SYNOPSIS

Typical usage pattern in the controller:

  sub index :Path :Args(0) {
      my ( $self,$c ) = @_;

      my $pg = $c->widget( 'Paginator', rs => 'Schema::User' );

      my $current = $pg->page;     # current page no
      my $first   = $pg->first;    # first page no (1)
      my $last    = $pg->last;     # last page no
      my $pages   = $pg->total;    # total pages ($last - $first + 1)
      my $total   = $pg->total;    # total objects (overall pages)
      my $objects = $pg->objects;  # objects for current page

      $c->res->body( "$pg" );      # render to nice HTML table
  }


With L<DBIx::Class::ResultSet> instance:

  my $pg = $c->widget( 'Paginator',
      rs   => $c->model('Schema::User'),
      rows => 3, page => 15
  );


With paginated L<DBIx::Class::ResultSet> instance:

  my $pg = $c->widget( 'Paginator',
      rs => $c->model('Schema::User')->search_rs( undef, { rows => 3, page => 15 )
  );


Handling invalid page:

  use Try::Tiny;

  my $pg = try {
      $c->widget( 'Paginator',
          rs      => 'Schema::User',
          invalid => 'raise'
      )
  } except {
      $c->detach('/error404') if /PAGE_OUT_OF_RANGE/;
      die $_;
  };


The same effect:

  my $pg = $c->widget( 'Paginator',
      rs      => 'Schema::User',
      invalid => sub { $c->detach('/error404' )
  };

Subclassing in your application:

  package YourApp::Widget::SimplePager;
  use Moose;
  extends 'CatalystX::Widget::Paginator';
  
  has '+edges'    => ( is => 'ro', default => undef );
  has '+invalid'  => ( is => 'ro', default => 'last' );
  has '+page_arg' => ( is => 'ro', default => 'page' );
  has '+prefix'   => ( is => 'ro', default => undef );
  has '+side'     => ( is => 'ro', default => 0 );
  has '+suffix'   => ( is => 'ro', default => undef );
  
  __PACKAGE__->meta->make_immutable;
  1;

Usage subclassed widget in the controller:

  $c->widget( '~SimplePager', rs => 'Schema::User' );

=head1 RENDERING

Widget renders (string representated) as HTML table with single row and
multiple columns:

  prefix | edge | side | delim |  main  |  delim | side | edge | suffix
  ----------------------------------------------------------------------
  Pages:   <<     1  2    ...    7 >8< 9    ...    40 41   >>    Total:x
  ----------------------------------------------------------------------

Table has HTML class attribute with a C<style> value. Cells HTML
class attribute consists from C<style_prefix> and block name, where
the names of the blocks the same as in example above. Current page framed
with HTML span tag, others with links.

=cut


# constructor
sub BUILD {
	my ( $self,$args ) = @_;

	# is page number valid?
	&{ $self->invalid } if $self->page > $self->last;
}

#
# types (used internally)
#
subtype __PACKAGE__ . '::Edges'
	=> as 'ArrayRef',
	=> where { $#$_==1 }
;
subtype __PACKAGE__ . '::Format'
	=> as 'CodeRef'
;
coerce __PACKAGE__ . '::Format'
	=> from 'Str',
	=> via { my $x = $_; sub { sprintf $x,@_ } }
;
subtype __PACKAGE__ . '::Invalid'
	=> as 'CodeRef'
;
coerce __PACKAGE__ . '::Invalid'
	=> from 'Str',
	=> via {
		return sub { my $self=shift; $self->_set_page( $self->first ) }
			if $_ eq 'first';
		return sub { my $self=shift; $self->_set_page( $self->last ) }
			if $_ eq 'last';
		return sub { die 'PAGE_OUT_OF_RANGE' }
			if $_ eq 'raise';
		die 'invalid value for "invalid" attribute';
	}
;
subtype __PACKAGE__ . '::NaturalInt'
	=> as 'Int',
	=> where { $_ >= 0 }
;
subtype __PACKAGE__ . '::PositiveInt'
	=> as 'Int',
	=> where { $_ > 0 }
;
coerce __PACKAGE__ . '::PositiveInt'
	=> from 'Defined',
	=> via { /^(\d+)$/ ? $1 : 1 }
;
subtype __PACKAGE__ . '::ResultSet'
	=> as 'Object',
	=> where { $_->isa('DBIx::Class::ResultSet') }
;
subtype __PACKAGE__ . '::Text'
	=> as 'CodeRef'
;
coerce __PACKAGE__ . '::Text'
	=> from 'Str',
	=> via { my $x = $_; sub { $x } }
;


=head1 CONSTRUCTOR

=head2 new( rs => $name|$instance, %options )

=head3 rs

L<DBIx::Class::ResultSet> name or instance

=head3 options

=head4 delim

Delimeter string or C<undef> (default: '...'). See L</RENDERING> for details.

=cut

has delim => ( is => 'ro', isa => 'Str | Undef', default => '...' );


=head4 edges

Two element array of strings for left and right edges respectively or C<undef>
(default: ['<<','>>']). See L</RENDERING> for details.

=cut

has edges => ( is => 'ro', isa => __PACKAGE__ . '::Edges | Undef', default => sub{ ['<<','>>'] } );


=head4 invalid

Determines the constructor behavior in the case of an invalid page.
Could be arbitrary code block or one of predefined words:

=over

=item first

Force set C<page> to C<first> (default).

=item last

Force set C<page> to C<last>.

=item raise

Raise exception C<PAGE_OUT_OF_RANGE>.

=back

=cut

has invalid => ( is => 'ro', isa => __PACKAGE__ . '::Invalid', coerce => 1, default => 'first' );


=head4 link

Code reference for build link. Receives page number as argument and returns target URI.

=cut

has link => ( is => 'ro', isa => 'CodeRef', lazy => 1, builder => '_link' );

sub _link {
	my ( $self ) = @_;

	my $c = $self->context;

	sub {
		$c->uri_for( $c->action, $c->req->captures, @{ $c->req->args },
			{ %{ $c->req->params }, $self->page_arg => shift } );
	}
}


=head4 main

Size of 'main' pages group (default: 10). See L</RENDERING> for details.

=cut

has main  => ( is => 'ro', isa => __PACKAGE__ . '::PositiveInt', default => 10 );


=head4 page

Current page number.

=cut

has page => ( is => 'ro', isa => __PACKAGE__ . '::PositiveInt', coerce => 1, lazy => 1, builder => '_page', writer => '_set_page' );

sub _page {
	my ( $self ) = @_;

	my $p = $self->resultset->{ attrs }{ page };

	$p ||= $self->context->req->param( $self->page_arg )
		if $self->page_auto;
   
	$p || 1;
}


=head4 page_arg

Name of query string parameter for page number extracting (default: 'p').

=cut

has page_arg => ( is => 'ro', isa => 'Str', default => 'p' );


=head4 page_auto

Try or not to extract C<page_arg> from L<Catalyst::Request> automatically
(default: 1).

=cut

has page_auto => ( is => 'ro', isa => 'Bool', default => 1 );


=head4 prefix

First cell content (default: 'Pages'). See L</RENDERING> for details.

=cut

has prefix => ( is => 'ro', isa => __PACKAGE__ . '::Text | Undef', coerce => 1, default => 'Pages:' );


=head4 rows

Number of objects per page (default: 10).

=cut

has rows => ( is => 'ro', isa => __PACKAGE__ . '::PositiveInt', lazy => 1, builder => '_rows' );

sub _rows {
	shift->resultset->{ attrs }{ rows } || 10;
}


=head4 side

Size of 'side' pages groups (default: 2). See L</RENDERING> for details.

=cut

has side  => ( is => 'ro', isa => __PACKAGE__ . '::NaturalInt', default => 2 );


=head4 style

CSS class name for table tag (default: 'pages'). See L</RENDERING> for details.

=cut

has style => ( is => 'rw', isa => 'Str', default => 'pages' );


=head4 style_prefix

CSS class name prefix for table cells (default: 'p_'). See L</RENDERING> for details.

=cut

has style_prefix => ( is => 'rw', isa => 'Str', default => 'p_' );


=head4 suffix

Last cell content (default: 'Total: x'). See L</RENDERING> for details.

=cut

has suffix => ( is => 'ro', isa => __PACKAGE__ . '::Text | Undef', coerce => 1, default => sub { sub { 'Total: ' . shift->total } } );


=head4 text

Code reference for page number formatting. Receives page number as argument and
returns string. Also can be just a sprintf format string (default: '%s').
See L</RENDERING> for details.

=cut

has text => ( is => 'ro', isa => __PACKAGE__ . '::Format', coerce => 1, default => '%s' );



=head1 ATTRIBUTES

=head2 first

First page number.

=cut

has first => ( is => 'ro', isa => __PACKAGE__ . '::PositiveInt', init_arg => undef, default => 1 );


=head2 last

Last page number.

=cut

has last => ( is => 'ro', isa => __PACKAGE__ . '::PositiveInt', init_arg => undef, lazy => 1, builder => '_last' );

sub _last {
	my ( $self ) = @_;
		
	ceil $self->total / $self->rows;
}


=head2 objects

Paged L<DBIx::Class::ResulSet> instance.

=cut

has objects => ( is => 'ro', isa => __PACKAGE__ . '::ResultSet', lazy => 1, builder => '_objects' );

sub _objects {
	my ( $self ) = @_;

	$self->resultset->search( undef, { page => $self->page, rows => $self->rows } );
}


=head2 pages

Total number of pages.

=cut

has pages => ( is => 'ro', isa => __PACKAGE__ . ':: PositiveInt', init_arg => undef, lazy => 1, builder => '_pages' );

sub _pages {
	my ( $self ) = @_;

	$self->last - $self->first;
}


=head2 total

Total objects count (overall pages).

=cut

has total => ( is => 'ro', isa => 'Int', lazy => 1, builder => '_total' );

sub _total {
	shift->resultset->search( undef, { map { $_ => undef } qw( page rows offset ) } )->count;
}


=head1 METHODS

=head2 format

Formatting linked page item.

=cut

sub format {
	my ( $self,$page,$text ) = @_;

	return '<span class="' . $self->style_prefix . 'current">' . &{ $self->text }( $text || $page ) . '</span>'
		if $self->page==$page;
	
	'<a href="' . &{ $self->link }( $page ). '">' . &{ $self->text }( $text || $page ) . '</a>';
}


=head2 render

Overriden L<Catalyst::Plugin::Widget> C<render> method.

=cut

sub render {
	my ( $self ) = @_;

	return '' unless $self->pages;

	# 'main' boundaries
	my $ml = $self->page - floor( ($self->main - 1) / 2);
	my $mr = $self->page + ceil ( ($self->main - 1) / 2);

	# 'main' adjustment
	$mr-- while $mr > $self->last  && $ml-- >= $self->first;
	$ml++ while $ml < $self->first && $mr++ <= $self->last;

	# 'main' range
	my @main = $ml .. $mr;

	# 'head' range
	my @head = $self->first .. min( $self->first + $self->side, $main[0] ) - 1;

	# 'tail' range
	my @tail = max( $self->last - $self->side , $main[-1] ) + 1 .. $self->last;

	# rendering
	my $r = '<table class="' . $self->style . '"><tr>';

	# 'prefix'
	$r .= '<td class="' . $self->style_prefix . 'prefix">' . &{ $self->prefix }( $self ) . '</td>'
		if $self->prefix;

	# 'prev' edge
	$r .= '<td class="' .$self->style_prefix . 'edge">' . $self->format( $self->page - 1, $self->edges->[0] ) . '</td>'
		if $self->page > $self->first && $self->edges;
	
	# 'head' side
	$r .= '<td class="'. $self->style_prefix .'side">' . $self->format( $_ ) . '</td>'
		for @head;
	
	# 'delim'
	$r .= '<td class="' . $self->style_prefix . 'delim">' . $self->delim . '</td>'
		if $self->delim && @head && $main[0] - $head[-1] > 1;

	# 'main'
	$r .= '<td class="' . $self->style_prefix . 'main">' . $self->format( $_ ) . '</td>'
		for @main;

	# 'delim'
	$r .= '<td class="' . $self->style_prefix . 'delim">' . $self->delim . '</td>'
		if $self->delim && @tail && $tail[0] - $main[-1] > 1;

	# 'tail' side
	$r .= '<td class="' . $self->style_prefix . 'side">' . $self->format( $_ ) . '</td>'
		for @tail;
	
	# 'next' edge
	$r .= '<td class="' . $self->style_prefix . 'edge">' . $self->format( $self->page + 1, $self->edges->[1] ) . '</td>'
		if $self->page < $self->last && $self->edges;

	# 'suffix'
	$r .= '<td class="' . $self->style_prefix . 'suffix">' . &{ $self->suffix }( $self ) . '</td>'
		if $self->suffix;

	# done!
	$r .= '</tr></table>';
}


=head1 AUTHOR

Oleg A. Mamontov, C<< <oleg at mamontov.net> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-widget-paginator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-Widget-Paginator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::Widget::Paginator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-Widget-Paginator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-Widget-Paginator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-Widget-Paginator>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-Widget-Paginator/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Oleg A. Mamontov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;

