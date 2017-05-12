package Data::SpreadPagination;

use strict;
use Carp;

use Data::Page;
use POSIX qw(ceil floor);
use Math::Round qw(round);

use vars qw(@ISA $VERSION);
@ISA = qw(Data::Page);
$VERSION = '0.1.2';

=head1 NAME

Data::SpreadPagination - Page numbering and spread pagination

=head1 SYNOPSIS

  use Data::SpreadPagination;
  my $pageInfo = Data::SpreadPagination->new({
    totalEntries      => $totalEntries, 
    entriesPerPage    => $entriesPerPage, 
    # Optional, will use defaults otherwise.
    # only 1 of currentPage / startEntry can be provided.
    currentPage       => $currentPage,
    startEntry        => $startEntry,
    maxPages          => $maxPages,
  });

  # General page information
  print "         First page: ", $pageInfo->first_page, "\n";
  print "          Last page: ", $pageInfo->last_page, "\n";
  print "          Next page: ", $pageInfo->next_page, "\n";
  print "      Previous page: ", $pageInfo->previous_page, "\n";

  # Results on current page
  print "First entry on page: ", $pageInfo->first, "\n";
  print " Last entry on page: ", $pageInfo->last, "\n";

  # Page range information
  my $pageRanges = $pageInfo->page_ranges;

  # Print out the page spread
  foreach my $page ($pageInfo->pages_in_spread()) {
    if (!defined $page) {
      print "... ";
    } elsif ($page == $pageInfo->current_page) {
      print "<b>$page</b> ";
    } else {
      print "$page ";
    }
  }

=head1 DESCRIPTION

The object produced by Data::SpreadPagination can be used to create
a spread pagination navigator. It inherits from Data::Page, and has
access to all of the methods from this object.

In addition, it also provides methods for creating a pagination spread,
to allow for keeping the number of pagenumbers displayed within a sensible
limit, but at the same time allowing easy navigation.

The object can easily be passed to a templating system
such as Template Toolkit or be used within a script.

=head1 METHODS

=head2 new()

  my $pageInfo = Data::SpreadPagination->new({
    totalEntries      => $totalEntries, 
    entriesPerPage    => $entriesPerPage, 
    # Optional, will use defaults otherwise.
    # only 1 of currentPage / startEntry can be provided.
    currentPage       => $currentPage,
    startEntry        => $startEntry,
    maxPages          => $maxPages,
  });

This is the constructor of the object. It requires an anonymous
hash containing the 'totalEntries', how many data units you have,
and the number of 'entriesPerPage' to display. Optionally the
'currentPage' / 'startEntry' (defaults to page/entry 1) and
'maxPages' (how many pages to display in addition to the current
page) can be added.

=cut

sub new {
  my $class = shift;
  my %params = %{shift()};

  croak "totalEntries and entriesPerPage must be supplied"
    unless defined $params{totalEntries} and defined $params{entriesPerPage};

  croak "currentPage and startEntry can not both be supplied"
    if defined $params{currentPage} and defined $params{startEntry};

  $params{currentPage} = 1
    unless defined $params{currentPage} or defined $params{startEntry};

  $params{currentPage} = int( ($params{startEntry} - 1) / $params{entriesPerPage} ) + 1
    if defined $params{startEntry};

  my $self = $class->SUPER::new($params{totalEntries}, $params{entriesPerPage}, $params{currentPage});
   
  $params{maxPages} = ceil( $params{totalEntries} / $params{entriesPerPage} ) - 1
    unless defined $params{maxPages};

  $self->{MAX_PAGES} = $params{maxPages};
  $self->_do_pagination( @params{qw(totalEntries entriesPerPage currentPage maxPages)} );

  return $self;
}

=head2 max_pages()

  print "Maximum additional pages to display is ", $pageInfo->max_pages(), "\n";

This method returns the maximum number of pages that are included in the
spread pagination in addition to the current page.

=cut

sub max_pages {
  my $self = shift;

  return $self->{MAX_PAGES};
}

=head2 page_ranges()

  $ranges = $pageInfo->page_ranges();
  for my $qtr (1..4) {
    my $range = $ranges->[$qtr-1];
    if (defined $range) {
      print "Qtr $qtr: no pages\n";
    } else {
      print "Qtr $qtr: pages " . $range->[0] . " to " . $range->[1] . "\n";
    }
  }

This method returns either an array or an arrayref (based upon context)
of the page ranges for each of the four quarters in the spread. Each range
is either undef for an empty quarter, or an array of the lower and upper
pages in the range.

=cut

sub page_ranges {
  my $self = shift;

  return wantarray ? @{ $self->{PAGE_RANGES} } : $self->{PAGE_RANGES};
}

=head2 pages_in_spread_raw()

  # Print out the page spread
  foreach my $page ($pageInfo->pages_in_spread_raw()) {
    if ($page == $pageInfo->current_page) {
      print "<b>$page</b> ";
    } else {
      print "$page ";
    }
  }

This method returns either an array or an arrayref (based upon context)
of purely the page numbers within the spread.

=cut

sub pages_in_spread_raw {
  my $self = shift;
  my $pages = [];

  for (0..3) {
    push @$pages, $self->{PAGE_RANGES}[$_][0] .. $self->{PAGE_RANGES}[$_][1]
      if defined $self->{PAGE_RANGES}[$_];

    push @$pages, $self->current_page()
      if $_ == 1;
  }
  
  return wantarray ? @{ $pages } : $pages;
}

=head2 pages_in_spread()

  # Print out the page spread
  foreach my $page ($pageInfo->pages_in_spread()) {
    if (!defined $page) {
      print "... ";
    } elsif ($page == $pageInfo->current_page) {
      print "<b>$page</b> ";
    } else {
      print "$page ";
    }
  }

This method returns either an array or an arrayref (based upon context)
of the page numbers within the spread. Breaks in the sequence are
indicated with undef's.

=cut

sub pages_in_spread {
  my $self = shift;
  my $ranges = $self->{PAGE_RANGES};
  my $pages = [];

  if (!defined $ranges->[0]) {
    push @$pages, undef if $self->current_page > 1;
  } else {
    push @$pages, $ranges->[0][0] .. $ranges->[0][1];
    push @$pages, undef if defined $ranges->[1] and ($ranges->[1][0] - $ranges->[0][1]) > 1;
  }

  push @$pages, $ranges->[1][0] .. $ranges->[1][1] if defined $ranges->[1];
  push @$pages, $self->current_page;
  push @$pages, $ranges->[2][0] .. $ranges->[2][1] if defined $ranges->[2];

  if (!defined $ranges->[3]) {
    push @$pages, undef if $self->current_page < $self->last_page;
  } else {
    push @$pages, undef if defined $ranges->[2] and ($ranges->[3][0] - $ranges->[2][1]) > 1;
    push @$pages, $ranges->[3][0] .. $ranges->[3][1];
  }

  return wantarray ? @{ $pages } : $pages;
}

# Carry out the pagination calculations
# Algorithm description reverse-engineered from Squirrelmail
# Reimplemented from description only by Alex Gough
sub _do_pagination {
    my $self= shift;
    my $total_entries = $self->total_entries;
    my $entries_per_page = $self->entries_per_page;
    my $current_page = $self->current_page;
    my $max_pages = $self->max_pages;

    # qNsizes
    my @q_size = ();
    my ($add_pages, $adj);

    # step 2
    my $total_pages = ceil($total_entries / $entries_per_page);
    my $visible_pages = $max_pages < ($total_pages-1)
	? $max_pages
	: $total_pages - 1;
    if ($total_pages - 1 <= $max_pages) {
	@q_size = ($current_page - 1, 0, 0, $total_pages - $current_page);
    }
    else {
	@q_size = (floor($visible_pages / 4),
		   round($visible_pages / 4),
		   ceil($visible_pages / 4),
		   round( ($visible_pages - round($visible_pages/4) )/3) );
	if ($current_page - $q_size[0] < 1) {
	    $add_pages = $q_size[0] + $q_size[1] - $current_page +1;
	    @q_size = ($current_page -1, 0, $q_size[2] + ceil($add_pages/2),
		       $q_size[3] + floor($add_pages /2));
	}
	elsif ($current_page - $q_size[1] - ceil($q_size[1] / 3)<=$q_size[0]) {
	    $adj = ceil((3*($current_page - $q_size[0] - 1))/4);
	    $add_pages = $q_size[1] - $adj;
	    @q_size = ($q_size[0], $adj, $q_size[2] + ceil($add_pages/2),
		       $q_size[3] + floor($add_pages/2));
	}
	elsif ($current_page + $q_size[3] >= $total_pages) {
	    $add_pages = $q_size[2] + $q_size[3] - $total_pages +$current_page;
	    @q_size = ($q_size[0] + floor($add_pages / 2),
		       $q_size[1] + ceil($add_pages / 2), 0,
		       $total_pages - $current_page);
	}
	elsif ($current_page + $q_size[2] >= $total_pages - $q_size[3]) {
	    $adj = ceil((3*($total_pages - $current_page - $q_size[3]))/4);
	    $add_pages = $q_size[2] - $adj;
	    @q_size = ($q_size[0] + floor($add_pages/2),
		       $q_size[1] + ceil($add_pages/2), $adj, $q_size[3]);
	}
    }
    # step 3 (PROFIT)
    $self->{PAGE_RANGES} = [ $q_size[0] == 0 ? undef
			     : [1,$q_size[0]],
			     $q_size[1] == 0 ? undef
			     : [$current_page - $q_size[1], $current_page-1],
			     $q_size[2] == 0 ? undef
			     : [$current_page+1, $current_page+$q_size[2]],
			     $q_size[3] == 0 ? undef
			     : [$total_pages - $q_size[3] + 1, $total_pages],
			    ];

}

=head1 BUGS

Hopefully there aren't any nasty bugs lurking in here anywhere.
However, if you do find one, please report it via RT.

=head1 ALGORITHM

The algorithm used to create the pagination spread was reverse-engineered
out of Squirrelmail by myself, and then reimplemented from description
only by Alex Gough.

=head1 THANKS, MANY

Alex Gough for implementing the central algorithm from my description.

=head1 AUTHOR

Jody Belka C<knew@cpan.org>

=head1 SEE ALSO

L<Data::Page>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jody Belka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

<<QUOTE;
Then there are Damian modules.... *sigh* ... that's not about being less-lazy -- that's about 
being on some really good drugs -- you know, there is no spoon. - flyingmoose 
QUOTE
