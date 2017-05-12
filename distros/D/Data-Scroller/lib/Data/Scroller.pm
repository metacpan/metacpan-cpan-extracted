package Data::Scroller;
use strict;
use warnings;
use vars qw( $VERSION @ISA );
$VERSION = '1.00';

# =============================================================================
# params for use in templates.
# =============================================================================
use constant PARAM_PAGE_LIST        => "page_list";   
use constant PARAM_PAGE_NEXT       	=> "page_next";
use constant PARAM_PAGE_PREV       	=> "page_prev";
use constant PARAM_PAGE_FIRST     	=> "page_first";
use constant PARAM_PAGE_LAST     	  => "page_last";
use constant PARAM_PAGE_NAME        => "page_name";
use constant PARAM_PAGE_TOTAL       => "page_total";
use constant PARAM_PAGE_INCREMENT   => "page_increment";

# =============================================================================
# default input parameters.
# =============================================================================
use constant PAGING_INCREMENT       => 10; # default paging increment
use constant PAGING_NAME            => "row_num"; # default paging name

# ----------------------------------------------------------------------
# constructor - takes hash of paramaters
# ----------------------------------------------------------------------
sub new
{
  my $class = shift;
  my $self = {};
  bless($self, $class);
  return undef if !$self->_init(@_);
  return $self;
}

# ----------------------------------------------------------------------
# return hashref of parameters for use in templates
# ----------------------------------------------------------------------
sub display
{
	my $self = shift;

  my $params = $self->{params};
	my $max_value = $self->{max_value};
	my $max_display = $self->{max_display};
	my $name = $self->{name};
	my $increment	= $self->{increment};
	my $selected = $self->{selected};
	my $page_increment = $self->{page_increment};

	# ----------------------------------------------------------------------
  # paging not required
	# ----------------------------------------------------------------------
  return $params if $max_value <= $increment;

	# ----------------------------------------------------------------------
	# what should the page number be for the results the user has selected?
	# ----------------------------------------------------------------------
  my $start = 1;
	$start = $self->_round($selected / $page_increment) if $selected > 0;

	# ----------------------------------------------------------------------
	# set the start and end points for display from the current page number..
	# ----------------------------------------------------------------------
	my $set_start = 1;
	my $set_end = $page_increment;
	($set_start, $set_end) = $self->_page_inc_by_one($set_start, $set_end, $start, $page_increment);

	# ----------------------------------------------------------------------
	# display extra <$page_increment> results if the selected page is the first
  # or last in a set..
	# ----------------------------------------------------------------------
	if ($start == $set_end and $set_end < $max_display) {
		$set_end += $page_increment;
	}
	elsif ($start == $set_start and $set_start >= $page_increment) {
		$set_start = ($set_start - $page_increment);
	}

	my $next = $increment;

	my @list = ();
	my $value = 0;
	my $prev = 0;
	for (my $i = $set_start; $i <= $set_end; $i++) {
		$value = ($i - 1) * $increment;
		last if ($value >= $max_value);

		my $item = {
			page_display  => $i,
			page_value    => $value,
		};

		if ($selected == $value) {
			$item->{page_current} = 1;
			$next += $value;
			if ($value > 0) {
				$prev = $value - $increment;
			}
		}
		push @list, $item;
	}

	$params->{+PARAM_PAGE_LIST} = \@list;
  $params->{+PARAM_PAGE_NAME} = $name;
  $params->{+PARAM_PAGE_TOTAL} = $max_display;
  $params->{+PARAM_PAGE_INCREMENT} = $increment;
  
	my $page_last = $self->_round(($max_display * $increment) - $increment);
  unless (($selected == $page_last)) {
    $params->{+PARAM_PAGE_LAST} = $page_last;
  }

	if ($next < $max_value) {
		$params->{+PARAM_PAGE_NEXT} = $next;
	}

	if ($selected > 0) {
    $params->{+PARAM_PAGE_FIRST} = 0;
		$params->{+PARAM_PAGE_PREV} = $prev;
	}

  return $params;
}

# ----------------------------------------------------------------------
# get methods to retrieve object properties as required
# ----------------------------------------------------------------------
sub max_value { shift->{max_value} }
sub increment { shift->{increment} }
sub max_display { shift->{max_display} }
sub name { shift->{name} }
sub selected { shift->{selected} }
sub page_increment { shift->{page_increment} }

# ----------------------------------------------------------------------
# work out what the paging menu display start and end points are
# for the selected page.
# this routine uses a base increment of $page_increment, then
# increments that by one in either direction, aka google style.
# ----------------------------------------------------------------------
sub _page_inc_by_one
{
  my $self = shift;
	my ($set_start, $set_end, $start, $inc) = @_;

	if ($start <= $inc) {
		$set_end = ($start + $inc) - 1;
	}
	elsif ($start > $inc and $set_end < (($start + $inc) - 1)) {
		$set_end++;
		$set_end = $self->_page_inc_by_one($set_start, $set_end, $start, $inc);	
	}

	if ($start < ($inc + 1)) {
		$set_start = 1;
	}
	else {
		$set_start = ($set_end - $inc) + 1;
	}

	return ($set_start, $set_end);
}

# ----------------------------------------------------------------------
# round UP
# ----------------------------------------------------------------------
sub _round
{
  my ($self, $val) = @_;
  return ($val == int($val) ? $val : int($val + 1));
}

# ----------------------------------------------------------------------
# initialize paging object properties
# ----------------------------------------------------------------------
sub _init
{
  my ($self, %args) = @_;

	my $max_value = $args{max_value} || die "max_value is required"; # total records / rows
	my $increment = $args{increment} || PAGING_INCREMENT; # records to display per page
	my $max_display = $args{max_display}; # max pages to display. TODO: not yet user option
	if (!defined($max_display) || !length($max_display)) {
		# $max_display = int($max_value / $increment) + 1; # ref display page numbers
		$max_display = $self->_round(($max_value / $increment));
	}
	my $name = $args{name} || $self->PAGING_NAME;
  my $selected = $args{selected};
  if (!defined($selected) || $selected !~ /\d+/) {
    $selected = 0; # current page, default 0 = page 1
  }
  # the number of pages to increment in either direction by when incrementing paging display 
  my $page_increment = $args{page_increment} || $increment;

  my $params = $self->_init_params;

  $self->{max_value} = $max_value;
  $self->{increment} = $increment;
  $self->{max_display} = $max_display;
  $self->{name} = $name;
  $self->{selected} = $selected;
	$self->{page_increment} = $page_increment;
  $self->{params} = $params;
  $self->{initialized} = 1;

  return 1;
}

# ----------------------------------------------------------------------
# initialize the params hash ref containing the template variables
# ----------------------------------------------------------------------
sub _init_params
{
  my $self = shift;
  my $params = {};
	$params->{+PARAM_PAGE_LIST} = undef;
  $params->{+PARAM_PAGE_NAME} = undef;
  $params->{+PARAM_PAGE_TOTAL} = undef;
  $params->{+PARAM_PAGE_INCREMENT} = undef;
  $params->{+PARAM_PAGE_LAST} = undef;
  $params->{+PARAM_PAGE_NEXT} = undef;
  $params->{+PARAM_PAGE_FIRST} = undef;
  $params->{+PARAM_PAGE_PREV} = undef;
  return $params;
}

1;

__END__

=head1 NAME

Data::Scroller

=head1 SYNOPSIS

=head3 In Perl module

  my $s = Data::Scroller->new(
    max_value => $max_value,
    selected  => $selected,
    increment => $increment,
  );
  my $page_params = $s->display;

OR
  
  my $page_params = Data::Scroller->new(
    max_value => $max_value,
    selected  => $selected,
    increment => $increment,
  )->display;

You would then make the $page_params hashref returned via the display method available for use within your
templating system.

For example if you were in a Catalyst based application:

	$c->stash->{page_params} = $page_params;

You also want the current 'increment' value available in your templates, so for example you could display/change the number of pages displayed per page via your template.

	$c->stash->{page_increment} = $s->increment;

Note: when using this module within the Catalyst framework, say for the 'page' attribute of a search,
setting that attribute to 'selected' ( the currently selected page ) will not work as you expect. This is
because this module expects 'selected' to be relevant to the database row you want whereas the catalyst
'page' attribute expects it to be the display page number. A work around for this problem is as such:

my $catalyst_attributes = {
	page => $selected == 0 ? $selected : int(($selected / 10) + 1),
};

=head3 In Template

Here is an example of how to set up paging in your templates assuming Template::Toolkit and Catalyst:

	[% IF page_params %]
		<br />
		<div>
		  [% IF page_params.page_first || page_params.page_first == 0 %]
		    <a class="paging" href="[% base _ c.namespace _ '/list?page=' _ page_params.page_first _ '&order=' _ order _ '&o2=' _ o2%]">&laquo; first</a>
		  [% END %]
		  [% IF page_params.page_prev || page_params.page_prev == 0 %]
		    <a class="paging" href="[% base _ c.namespace _ '/list?page=' _ page_params.page_prev _ '&order=' _ order _ '&o2=' _ o2 %]">&laquo; prev</a>
		  [% END %]
		  [% FOR p IN page_params.page_list %]
		    [% IF p.page_current %]
		      <span class="paging">[% p.page_display %]</span>
		    [% ELSE %]
		      <a class="paging" href="[% base _ c.namespace _ '/list?page=' _ p.page_value _ '&order=' _ order _ '&o2=' _ o2 %]">[% p.page_display %]</a>
		    [% END %]
		  [% END %]
		  [% IF page_params.page_next %]
		    <a class="paging" href="[% base _ c.namespace _ '/list?page=' _ page_params.page_next _ '&order=' _ order _ '&o2=' _ o2 %]">next &raquo;</a>
		  [% END %]
		  [% IF page_params.page_last %]
		    <a class="paging" href="[% base _ c.namespace _ '/list?page=' _ page_params.page_last _ '&order=' _ order _ '&o2=' _ o2 %]">last &raquo;</a>
		  [% END %]
		</div>
	[% END %]

As you can see, you can simply add any additional parameters you wish to the paging links via your template.

=head1 DESCRIPTION

Handle navigation of data over multiple pages in a 'rolling' pageset fashion, similar to that of google.

An alternative to Data::Page by Leon Brocard ( written long before I'd heard of that :)

=head1 REQUIRED INPUT PARAMETERS

=head3 max_value

The total number of elements, eg; table rows, to be displayed. Required.

=head1 OPTIONAL INPUT PARAMETERS

=head3 selected
  
The input parameter passed in from templates that indicates the new page currently being requested. Default 0 ( page 1 ).

=head3 increment

Indicates the number of elements to display per page. Default 10.

=head3 page_increment

The maximum number of pages to increment by in either direction for rolling page number display.
Default $increment.

=head3 name

The name of the input parameter passed in from templates that indicates the current selected page.
Default 'row_num'.

=head1 METHODS

=head2 new( %args )

  %args = (
    max_value      => $max_value,
    selected       => $selected,
    increment      => $increment,
    page_increment => $page_increment,
    name           => $name
  );

Constructor. Takes hash of both required and optional input parameters as arguments. For full descriptions of the available input options see the 'REQUIRED INPUT PARAMETERS' and 'OPTIONAL INPUT PARAMETERS' sections.

=head2 display()

Determines the appropriate "set" of page numbers / links to display for the given arguments and returns a hashref of parameters for use in your template with the following structure:

  $page_params = {
    'page_increment' => $page_increment,
    'page_name' => $page_name,
    'page_list' => [
      {
        'page_value' => $page_value,
        'page_display' => $page_number,
        'page_current' => $boolean
      },
    ],
    'page_first' => $page_first,
    'page_last' => $page_last,
    'page_prev' => $page_prev,
    'page_next' => $page_next,
    'page_total' => $page_total,
  };

=head2 max_value()

return value of max_value config param.

=head2 increment()

return value of increment config param.

=head2 max_display()

return value of max_display config param.

=head2 name()

return value of name config param.

=head2 selected()

return value of selected param.

=head2 page_increment()

return value of page_increment config param.

=head1 AUTHOR

Ben Hare for Fotango Ltd, London, <benhare@gmail.com>, www.fotango.com, (c) 2004/5.

Based on 'Paging.pm', originally conceived and written by <john.ormandy@gmail.com>.

=head1 COPYRIGHT

Copyright (c) 2004/5 Fotango, London

This module is free software. You can redistribute it or modify it under the same terms as Perl itself.

=cut
