
package Class::DBI::Lite::Pager;

use strict;
use warnings 'all';


sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    data_sql      => undef,
    count_sql     => undef,
    sql_args      => [ ],
    where         => undef,
    order_by      => undef,
    class         => undef,
    page_number   => 1,
    page_size     => 10,
    total_items   => 0,
    start_item    => 1,
    stop_item     => 0,
    %args,
    _fetched_once => 0,
  }, $class;

  ($s->{stop_item}) = sort { $a <=> $b } (
    $s->page_number * $s->page_size,
    $s->total_items
  );
  $s->{start_item} = ( $s->page_number - 1 ) * $s->page_size + 1;

  return $s;
}# end new()


# Public read-write properties:
sub page_number
{
  my $s = shift;
  if( @_ )
  {
    $s->{page_number} = shift;

    $s->{_fetched_once} = 0;
    ($s->{stop_item}) = sort { $a <=> $b } (
      $s->page_number * $s->page_size,
      $s->total_items
    );
    $s->{start_item} = ( $s->page_number - 1 ) * $s->page_size + 1;
  }
  else
  {
    return $s->{page_number};
  }# end if()
}# end page_number()


# Public read-only properties:
sub page_size   { shift->{page_size} }
sub total_items { shift->{total_items} }
sub total_pages { shift->{total_pages} }
sub start_item  { shift->{start_item} }
sub stop_item   { shift->{stop_item} }
sub has_prev    { shift->{page_number} > 1 }

sub has_next
{
  my $s = shift;
  $s->{total_pages} > $s->{page_number};
}# end has_next()

sub _has_more
{
  my $s = shift;
  
  if( $s->{_fetched_once} )
  {
    $s->{page_number} < $s->{total_pages};
  }
  else
  {
    $s->{total_pages} >= $s->{page_number};
  }# end if()
}# end _has_more()

*items = \&next_page;

sub next_page
{
  my $s = shift;
  
  return unless $s->_has_more;
  
  if( $s->{_fetched_once}++ )
  {
    $s->{page_number}++;
  }# end if()

  ($s->{stop_item}) = sort { $a <=> $b } (
    $s->page_number * $s->page_size,
    $s->total_items
  );
  $s->{start_item} = ( $s->page_number - 1 ) * $s->page_size + 1;
  
  my $offset = $s->_offset;
  
  if( $s->{data_sql} )
  {
    my $limit = " LIMIT $offset, @{[ $s->{page_size} ]} ";
    my $order_by = $s->{order_by} ? " ORDER BY $s->{order_by} " : "";
    my $sth = $s->{class}->db_Main->prepare( "$s->{data_sql} $order_by $limit" );
    $sth->execute( @{ $s->{sql_args} } );
    return $s->{class}->sth_to_objects( $sth );
  }
  else
  {
    return $s->{class}->search_where(
      $s->{where},
      {
        order_by  => $s->{order_by} || undef,
        limit     => $s->page_size,
        offset    => $offset,
      }
    );
  }# end if()
}# end next_page()


sub prev_page
{
  my $s = shift;
  
  return unless $s->has_prev;
  
  $s->{page_number}-- if $s->{_fetched_once}++;
  $s->{stop_item} = $s->page_number * $s->page_size;
  $s->{stop_item} = $s->total_items if $s->stop_item > $s->total_items;
  $s->{start_item} = ( $s->page_number - 1 ) * $s->page_size + 1;
  $s->{start_item} = 0 if $s->{start_item} < 0;
  
  my $offset = $s->_offset;
  
  if( $s->{data_sql} )
  {
    my $limit = " LIMIT $offset, @{[ $s->{page_size} ]} ";
    my $sth = $s->{class}->db_Main->prepare( "$s->{data_sql} $limit" );
    $sth->execute( @{ $s->{sql_args} } );
    return $s->{class}->sth_to_objects( $sth );
  }
  else
  {
    return $s->{class}->search_where(
      $s->{where},
      {
        order_by  => $s->{order_by} || undef,
        limit     => $s->page_size,
        offset    => $offset,
      }
    );
  }# end if()
}# end prev_page()


sub navigations
{
  my ($s, $padding) = @_;
  
  $padding ||= 5;
  
  # Wiggle the start and stop out of the data we have:
  my $start = $s->page_number - $padding > 0
              ? $s->page_number - $padding
              : 1;
  my $stop  = $s->page_number + $padding <= $s->total_pages
              ? $s->page_number + $padding
              : $s->total_pages;
  
  # Now:
  if( $stop - $start < ( $padding * 2 ) + 1 )
  {
    # Need to add more pages:
    if( $start == 1 && $stop < $s->total_pages )
    {
      while( ( $stop - $start < ( $padding * 2 ) ) && $stop < $s->total_pages )
      {
        $stop++;
      }# end while()
    }
    elsif( $stop == $s->total_pages && $start > 1 )
    {
      while( ( $stop - $start < ( $padding * 2 ) ) && $start > 1 )
      {
        $start--;
      }# end while()
    }# end if()
  }# end if()
  
  return ( $start, $stop );
}# end navigations()


sub _offset
{
  my $s = shift;
  $s->{page_number} == 1 ? 0 : ($s->{page_number} - 1) * $s->{page_size};
}# end _offset()

1;# return true:

=pod

=head1 NAME

Class::DBI::Lite::Pager - Page through your records, easily.

=head1 SYNOPSIS

=head2 Paged Navigation Through Large Datasets

  # Say we're on page 1 of a list of all 'Rock' artists:
  my $pager = app::artist->pager({
    genre => 'Rock',
  }, {
    order_by    => 'name ASC',
    page_number => 1,
    page_size   => 20,
  });

  # -------- OR -----------
  my $pager = app::artist->sql_pager({
    data_sql  => "SELECT * FROM artists WHERE genre = ?",
    count_sql => "SELECT COUNT(*) FROM artists WHERE genre = ?",
    sql_args  => [ 'Rock' ],
  }, {
    page_number => 1,
    page_size   => 20,
  });
  
  # Get the first page of items from the pager:
  my @artists = $pager->items;
  
  # Is the a 'previous' page?:
  if( $pager->has_prev ) {
    print "Prev page number is " . ( $pager->page_number - 1 ) . "\n";
  }
  
  # Say where we are in the total scheme of things:
  print "Page " . $pager->page_number . " of " . $pager->total_pages . "\n";
  print "Showing items " . $pager->start_item . " through " . $pager->stop_item . " out of " . $pager->total_items . "\n";
  
  # Is there a 'next' page?:
  if( $pager->has_next ) {
    print "Next page number is " . ( $pager->page_number + 1 ) . "\n";
  }
  
  # Get the 'start' and 'stop' page numbers for a navigation strip with 
  # up to 5 pages before and after the 'current' page:
  my ($start, $stop) = $pager->navigations( 5 );
  for( $start..$stop ) {
    print "Page $_ | ";
  }

=head2 Fetch Huge Datasets in Small Chunks

  # Fetch 300,000,000 records, 100 records at a time:
  my $pager = app::citizen->pager({
    country => 'USA'
  }, {
    order_by    => 'last_name, first_name',
    page_size   => 100,
    page_number => 1,
  });
  while( my @people = $pager->next_page ) {
    # We only got 100 people, instead of swamping the 
    # database by asking for 300M records all at once:
  }

=head1 DESCRIPTION

Paging through records should be easy.  C<Class::DBI::Lite::Pager> B<makes> it easy.

=head1 CAVEAT EMPTOR

This has been tested with MySQL 5.x and SQLite.  It should work with any database
that provides some kind of C<LIMIT index, offset> construct.

To discover the total number of pages and items, 2 queries must be performed:

=over 4

=item 1 First we do a C<SELECT COUNT(*) ...> to find out how many items there are in total.

=item 2 One or more queries to get the records you've requested.

If running 2 queries is going to cause your database server to catch fire, please consider rolling your own pager
or finding some other method of doing this.

=back

=head1 CONSTRUCTOR

=head2 new( page_number => 1, page_size => 10 )

Returns a new Pager object at the page number and page size specified.

=head1 PUBLIC PROPERTIES

=head2 page_number

Read-write.  Sets/gets the page number.

=head2 page_size

Read only.  Returns the page size.

=head2 total_pages

Read only.  Returns the total number of pages in the Pager.

=head2 total_items

Read only.  Returns the total number of records in all the pages combined.

=head2 start_item

Read only.  Returns the index of the first item in this page's records.

=head2 stop_item

Read only.  Returns the index of the last item in this page's records.

=head2 has_next

Read only.  Returns true or false depending on whether there are more pages B<after> the current page.

=head2 has_prev

Read only.  Returns true or false depending on whether there are more pages B<before> the current page.

=head1 PUBLIC METHODS

=head2 items( )

Returns the next page of results.  Same as calling C<next_page()>.  Purely for syntax alone.

=head2 next_page( )

Returns the next page of results.  If called in list context, returns an array.  If 
called in scalar context, returns a L<Class::DBI::Lite::Iterator>.

If there is not a next page, returns undef.

=head2 prev_page( )

Returns the previous page of results.  If called in list context, returns an array.  If 
called in scalar context, returns a L<Class::DBI::Lite::Iterator>.

If there is not a previous page, returns undef.

=head2 navigations( [$padding = 5] )

OK - grab a cup of coffee, then come back for the explanation.

Ready?  Good.

Say you have a C<$pager>:

  my $pager = app::album->pager(undef, {
    page_size => 10,
    page_number => 1,
  });

Then you want to make your paging navigation with at least 10 pages shown, and a
maximum of 5 pages to either side of the "current" page (like Google).

  1  2  3  4  5  6  7  8  9  10 11

On the first page you I<could> just do:

  for( 1..10 ) {
    # print a link to that page.
  }

...but...when you get toward the middle or off to the end, it gets weird.

Tah-Dah!

  my ($start, $stop) = $pager->navigations( 5 );

Now you can simply do:

  for( $start..$stop ) {
    # print a link to that page:
  }

B<It> will always do the right thing - will I<you>?

So when you're on page 7 it will look like this:

  2  3  4  5  6  7  8  9  10  11  12

Then, if there were 20 pages in your entire resultset, page 20 would look like this:

  10  11  12  13  14  15  16  17  18  19  20

Great, huh?

=head1 AUTHOR

Copyright John Drago <jdrago_999@yahoo.com>.  All rights reserved.

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as perl itself.

=cut

