package Data::Page::Pageset;
use Carp;
use strict;
use Data::Page::Pageset::Chunk;
use POSIX;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw( 
	total_pages
	first_pageset
	last_pageset
	current_pageset
	previous_pageset
	next_pageset
 ) );
# add this for make more version to be 1.02
our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my $class = shift;
	my $page = shift;
	my $param = shift;
		
	croak("The first is not a Data::Page object!")
		unless $page->UNIVERSAL::isa('Data::Page');
	
	my $self = bless {}, $class;
	$self->{_page} = $page;
	$self->{_total_pagesets} = [];
	$self->{_MAX_PAGESETS} = 1;
	$self->{_PAGE_PER_SET} = 2;
	
	if ( not defined $param or ref $param eq '' ){
		$self->pages_per_set( $param || 10 );

	}elsif ( defined $param->{max_pagesets} ){
		$self->max_pagesets( $param->{max_pagesets} );
	
	}elsif ( defined $param->{pages_per_set} ){
		$self->pages_per_set( $param->{pages_per_set} );
	}

	return $self;
}

sub total_pagesets {
	my $self = shift;
	if ( $_[0] ){
		$self->{_total_pagesets} = $_[0];
	}
	return ( wantarray ) ? @{$self->{_total_pagesets}} : $self->{_total_pagesets};
}

sub max_pagesets {
	my ( $self, $number ) = @_;
	if ( defined $number ){
		$number = int $number;
		croak("Fewer than one pagesets!") if $number < 1;
		return $self->{_MAX_PAGESETS} if $number == $self->{_MAX_PAGESETS};
		$self->{_MAX_PAGESETS} = $number;
		$self->pages_per_set( POSIX::ceil( $self->{_page}->last_page / $number ) );
	}
	return $self->{_MAX_PAGESETS};
}

sub pages_per_set {
	my ( $self, $number ) = @_;
	if ( defined $number ){
		$number = int $number;
		croak("Fewer than two pages per set!") if $number < 2;
		return $self->{_PAGE_PER_SET} if $number == $self->{_PAGE_PER_SET};
		$self->{_PAGE_PER_SET} = $number;
		$self->_refresh;
	}
	return $self->{_PAGE_PER_SET};
}

sub _refresh {
	my $self = shift;
	my $number = $self->pages_per_set;
	my $page = $self->{_page};
	
	my $current_page = $page->current_page;
	my @total_pages = ( $page->first_page .. $page->last_page );
	$self->total_pages( scalar @total_pages );
	
	my @pageset;	
	while ( @total_pages ){
		my @array = splice( @total_pages, 0, $number );
		my $chunk = Data::Page::Pageset::Chunk->new( @array );
		push @pageset, $chunk;
		if ( $current_page >= $chunk->first and $current_page <= $chunk->last ){
			$chunk->is_current(1);
			$self->current_pageset( $chunk );
			$self->previous_pageset( $pageset[-2] ) if $#pageset;
		}
		$self->next_pageset( $chunk ) if ( $#pageset and $pageset[-2]->is_current );
	}
	$self->first_pageset( $pageset[0] );
	$self->last_pageset( $pageset[-1] ) if $#pageset;
	$self->total_pagesets( \@pageset );
}

1;

=head1 NAME

Data::Page::Pageset - change long page list to be shorter and well navigate

=head1 DESCRIPTION

Pages number can be very high, and it is not comfortable to show user from the first page to the last page list. Sometimes we need split the page list into some sets to shorten the page list, the form is like:

 1-6 7-12 13 14 15 16 17 18 19-24 25-30 31-36 37-41

the first two part indicats the two pagesets, and in current pageset, we provide the normal page list from the first one to the last one, and provide the rest pagesets to indicate the pages scope.

In this module, you can specify the pages_per_set or max_pagesets for fine showing.

=head1 SYNOPSIS

 use Data::Page::Pageset;
 # we use Data::Page object, so do prepare
 my $page = Data::Page->new($total_entries, $entries_per_page, $current_page);
 # create the pageset object
 my $pageset = Data::Page::Pageset->new( $page );
 my $pageset = Data::Page::Pageset->new( $page, 12 );
 my $pageset = Data::Page::Pageset->new( $page, { max_pagesets => $max_pagesets } );
 my $pageset = Data::Page::Pageset->new( $page, { pages_per_set => $pages_per_set } );

 # for using
 foreach my $chunk ( $pageset->total_pagesets ){
 	if ( $chunk->is_current ){
 		map { print "$_ " } ( $chunk->first .. $chunk->last );
 	}else{
 		print "$chunk ";
 	}
 }

=head1 METHODS

=over

=item new()

 # default page_per_set is 10
 my $pageset = Data::Page::Pageset->new( $page );

 # set the page_per_set to be 12
 my $pageset = Data::Page::Pageset->new( $page, 12 );
 # another the same by passing hashref
 my $pageset = Data::Page::Pageset->new( $page, { pages_per_set => $pages_per_set } );

 # set the max_pagesets value, default is 1
 my $pageset = Data::Page::Pageset->new( $page,	{ max_pagesets => $max_pagesets } );
 # if max_pagesets supplies, the pages_per_set setting will be ignore
 my $pageset = Data::Page::Pageset->new( $page, 
 	{ max_pagesets => $max_pagesets, pages_per_set => $pages_per_set } );

We must need $page(isa Data::Page) object.

=item max_pagesets( $number )

 # set the max_pagesets value, and the $pageset's info will changed immediately
 $pageset->max_pagesets( $number );

=item pages_per_set( $number )

 # set the pages_per_set value, and the $pageset's info will changed immediately
 $pageset->pages_per_set( $number );
 my $present_setting = $pageset->pages_per_set();

=item $pageset->total_pages

return total pages' number.

=item $pageset->total_pagesets

return the actual pagesets number.

=item $pageset->first_pageset

 my $chunk = $pageset->first_pageset;

return the first pageset, it's Data::Page::Pageset::Chunk object

=item $pageset->last_pageset

 my $chunk = $pageset->last_pageset;

return the last pageset, it's Data::Page::Pageset::Chunk object

=item $pageset->current_pageset

 my $chunk = $pageset->current_pageset;

return the current pageset which current page is in this pageset, it's Data::Page::Pageset::Chunk object

=item $pageset->previous_pageset

 my $chunk = $pageset->previous_pageset;

return the previous pageset, it's Data::Page::Pageset::Chunk object

=item $pageset->next_pageset

 my $chunk = $pageset->next_pageset;

return the next pageset, it's Data::Page::Pageset::Chunk object

=back

=head1 Data::Page::Pageset::Chunk object

a $pageset gives you some $chunk to do more stuff as you see above. Here gives the $chunk methods

=over

=item first

 # return the first page number in this chunk
 $chunk->first;

=item last

 # return the last page number in this chunk
 $chunk->last;

=item middle

 # return the middle page number in this chunk
 $chunk->middle;

=item pages

 # return the pages number in this chunk
 $chunk->pages;

=item is_current

 # return true if this $chunk contains the current_page
 $chunk->is_current;

=item as_string

 # if this chunk is from page 3 to 7, then print '3-7'
 print $chunk;
 print $chunk->as_string;
 print $chunk->as_string('-');

 # you can change default '-' as:
 print $chunk->as_string('~');

if the $chunk only contains one page, it will only return the page number.

=back

=head1 SEE ALSO

L<Data::Page|Data::Page> is what we need, L<Data::Pageset|Data::Pageset> is the similar one, L<Template::Plugin::Pageset|Template::Plugin::Pageset> is the wrapper for this to using it more converiently in TT2 tempale.

=head1 BUGS

just mail me to <me@chunzi.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Chun Sheng.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chun Sheng, <me@chunzi.org>

=cut
