package Data::SimplePaginator;
use strict;
use warnings;
use vars qw($VERSION);
($VERSION) = '0.5';

# Private method so we do not depend on presence of POSIX module:
sub _ceil {
        my ($i) = @_;
        my $r = sprintf("%d",$i);
        $r += 1 if( $i > $r );
        return $r;
}

=pod

=head1 NAME

Data::SimplePaginator - data pagination without assumptions (I think)

=head1 SYNOPSIS

=for test begin

 my $paginator;

=for test end

 # paginate the alphabet into groups of 10 letters each
 $paginator = Data::SimplePaginator->new(10);
 $paginator->data(A..Z);
 
 # print the second page (K..T)
 foreach( $paginator->page(2) ) {
 	print $_;
 }

=head1 DESCRIPTION

This module helps me create pagination without a lot of fuss. I looked
at other pagination modules (see also, below) and their interfaces were
cumbersome for me. 

This module will NOT...

=over

=item Keep track of the current page for you

=item Screw with your CGI or other environment 

=item Generate any HTML

=item Print to stdout

=back

If you're using Template Toolkit you probably want to use Data::Pageset
or Data::SpreadPagination because they have lots of subs that work great
with the way TT is set up. 

=head1 METHODS




=head2 new

=for test begin

 my $number_per_page = 10;
 
=for test end

 $paginator = Data::SimplePaginator->new();
 
 $paginator = Data::SimplePaginator->new($number_per_page);
 
 $paginator = Data::SimplePaginator->new($number_per_page, A..Z);

Creates a new pagination object to split up data into sets of $number_per_page.
Default items per page is 10, and default data is the empty list.

=cut

sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	my $self = {
		'size' => 10,
		'data' => [],
	};
	bless $self, $class;
	if( @_ ) {
		$self->size( shift );
	}
	if( @_ ) {
		$self->data( @_ );
	}
	return $self;
}




=head2 data

=for test begin

 my @items = ('orange','apple','banana','...');

=for test end

 $paginator->data( @items );
 
 my @all = $paginator->data;

This method lets you set new data items for the paginator. It stores
a shallow copy of the array, not a reference to it.

Return value is the current data array.

=cut

sub data {
	my ($self,@items) = @_;
	if( @items ) {
		$self->{data} = [ @items ];
	}
	return @{$self->{data}};
}




=head2 size

 $paginator->size(15);
 
 my $items_per_page = $paginator->size;
 
This method lets you set the size of the page, a.k.a. the number of items per page. 

Return value is the size of the page.

=cut

sub size {
	my ($self,@p) = @_;
	if( @p ) {
		$self->{size} = shift @p;
	}
	return $self->{size};
}




=head2 pages

 my $number_of_pages = $paginator->pages;
 
Returns the number of pages based on the data you provide and the
number of items per page that you set. 

=cut

sub pages {
	my ($self) = @_;
	my @all = $self->data;
	return _ceil(scalar(@all) / $self->size);
}


=head2 page

 my @contents = $paginator->page($number);

 my @first_page = $paginator->page(1);
 
 my @last_page = $paginator->page( $paginator->pages );
 
The first page is page 1, the last page is number of pages. 

Returns items from @list that are on the specified page. 
If you give an invalid/undefined page number or one that's out of
range for your data set, you get an empty list.  

=cut

sub page {
	my ($self,$num) = @_;
	my @all = $self->data;
	return (wantarray ? () : 0) unless defined $num;
	return (wantarray ? () : 0) if ($num < 1 || $num > $self->pages);
	my @data = splice(@all,($num - 1)*$self->size, $self->size);
	return @data;
}




=head1 EXAMPLES

use Data::SimplePaginator;

=head2 paginate the alphabet into groups of 10 letters each

 $paginator = Data::SimplePaginator->new(10,A..Z);

=head2 print just the first page, A .. J

 print "first page: ". join(" ", $paginator->page(1)) . "\n";

=head2 print every page

 foreach my $page ( 1..$paginator->pages ) {
   print "page $page: ". join(" ", $paginator->page($page)) . "\n";
 }

=head2 print just the last page, U .. Z

 print "last page: ". join(" ", $paginator->page($paginator->pages)) . "\n";

=head2 add more elements to the paginator

 $paginator->data( $paginator->data, 1..4, map { lc } A..Z, 5..8 );
 
=head2 create a pageset paginator to group pages in sets of 3

 my $pageset = Data::SimplePaginator->new(3, 1..$paginator->pages);
 
=head2 print every page, grouping into pagesets

 foreach my $setnum ( 1..$pageset->pages ) {
   print "pageset $setnum\n";
   foreach my $page ( $pageset->page($setnum) ) {
     print "  page $page: ". join(" ", $paginator->page($page)) . "\n";
   }
 }

=head2 print every page, grouping into pagesets, resetting page numbers

 foreach my $setnum ( 1..$pageset->pages ) {
   print "pageset $setnum\n";
   foreach my $page ( 1..$pageset->page($setnum) ) {
     print "  page $page: ". join(" ", $paginator->page( ($pageset->page($setnum))[$page-1])) . "\n";
   }
 }
  

=head1 SEE ALSO

The other paginators I looked at before deciding to write this one:

=over

=item HTML::Paginator

=item Data::Paginated

=item Data::Page (also: Data::Pageset, Data::SpreadPagination)

=back

=head1 AUTHOR

Jonathan Buhacoff <jonathan@buhacoff.net>

=head1 COPYRIGHT

Copyright (C) 2004-2008 Jonathan Buhacoff.  All rights reserved.

=head1 LICENSE

This library is free software and can be modified and distributed under the same
terms as Perl itself. 

=cut

1;
