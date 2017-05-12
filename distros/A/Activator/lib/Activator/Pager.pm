package Activator::Pager;
use strict;

=head1 NAME

Activator::Pager - Object to assist in implementing pagination interfaces

=head1 SYNOPSIS

      use Activator::Pager;
      my $pager = new Activator::Pager( $offset, $length, $count, $total );


=head1 METHODS

=head2 new

Constructor to set internal variables.

Arguments:
  $offset       - offset of the first item in this set ( 0 indexed )
  $page_size    - number of items per page
  $set_size     - actual number of items in this set
  $total        - total items available

Returns:
 $self

Sample:

  n == highest possible offset
  p == highest possbile page

  $self = bless( {
    next_offset => 5,  -- offset of next page ( 0..n ) or undef if you are 
                          on last page
    set_size => 5,     -- constructor argument
    prev_offset => 0,  -- offset of previous page ( 0..n ) or undef if you 
                          are on first page
    cur_page => 1,     -- the current page number of $offset
    last_page => 21,   -- the last page page for the total passed in ( 1..p )
    last_offset => 100,-- the last possible offset based on number pages ( 0..n )
    total => 103,      -- constructor argument
    next_page => 2,    -- the next possible page ( 1..p ) or undef if on 
                          last page ( offset == last_offset )
    page_size => 5     -- constructor argument
    to => 5,           -- the last member number of current page ( 1..n+1 )
    from => 1,         -- the first member number of current page ( offset+1 )
    prev_page => 1,    -- the previous page ( 1..p ) or undef if on first 
                          page ( offset == 0 )
    offset => 0        -- constructor argument
  }, Activator::Pager );


NOTE: we need to document the assuption of offset not being $to

=cut

sub new {
    my ($pkg, $offset, $page_size, $set_size, $total) = @_;

    my $self = bless {}, $pkg;

    $offset ||= 0;

    if( $page_size < 0 ) { $page_size = $set_size }

    $self->{offset} = $offset;
    $self->{page_size} = $page_size;
    $self->{set_size}  = $set_size;
    $self->{total}  = $total;

    ## error, offset is greater than results?
    if( ( $offset >= $total ) || ( $page_size == 0 ) ) {
        $self->{from} = 0;
        $self->{to}   = 0;
        $self->{total} = 0;
        return $self;
    }

    ## from and to
    $self->{from} = $total > 0 ? $offset+1 : 0;
    $self->{to}   = $offset+$set_size < $total ? $offset+$set_size : $total;

    ## last page number
    #
    # Last page is total/length when evenly divisible. We mod them, if
    # there is remainder, add 1 for the last page. EG: 101/10 == 10
    # pages + 1 on the last page
    #
    # this new hotness courtesy Frank Wallingford
    # TODO: write pager tests, use this formula
    #$self->{last_page} = int(($total + ( $page_size - 1 ) ) / $page_size );

    # old and crufty
    $self->{last_page} = int($total/$page_size) + ( ($total % $page_size > 0) ? 1 : 0 );

    ## last offset
    #
    # Similar to above, we need to subtract 1 length when evenly
    # divisible so that we don't offset off the end of the available
    # results. If there is a remainder, subtract nothing.
    #WARN( qq{  ($self->{last_page} * $page_size) - ( ($total % $page_size > 0) ? 0 : $page_size)  });

    # this new hotness courtesy Frank Wallingford
    # TODO: write pager tests, use this formula
    #$self->{last_offset} = int( ( $total - 1 ) / $page_size ) + 1;

    # old and crufty
    $self->{last_offset} = int($total/$page_size) * $page_size - ( ($total % $page_size > 0) ? 0 : $page_size ); ;


    ## cur page offset
    $self->{cur_page} = int( $offset / $page_size ) + 1;

    ## prev
    if( $offset - $page_size >= 0 ) {
      $self->{prev_offset} = $offset - $page_size;
      $self->{prev_page} = ( $self->{cur_page} - 1 <= 0 ) ? undef : $self->{cur_page} - 1;
    }
    else {
      $self->{prev_offset} = undef;
      $self->{prev_page} = undef;
    }

    ## next
    if( $offset + $page_size < $total ) {
      $self->{next_offset} = $offset + $page_size;
      $self->{next_page} = int( $self->{next_offset}/$page_size ) + 1;
    }
    else {
      $self->{next_offset} = undef;
      $self->{next_page} = undef;
    }

    return $self;
  }

=head2 FUTURE WORK

Implement getter functions if anyone wants it. We just access the vars
directly at this time.

This module would be nicer if it did more magic such that I can include pagination trivially in a template.

=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

1;
