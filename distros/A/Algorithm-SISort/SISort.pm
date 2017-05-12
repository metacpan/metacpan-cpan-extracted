package Algorithm::SISort;

require 5.005_62;
use strict;
use warnings;
use Inline C => 'DATA', NAME => 'Algorithm::SISort', VERSION => '0.14';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	Sort
	Sort_inplace
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.14';

sub Sort(&@) {
	my $callback=shift;
	_sort($callback, \@_);
	return @_;
}

sub Sort_inplace(&\@) {
	my $callback=shift;
	return _sort($callback, $_[0]);
}

1;

__DATA__


=head1 NAME

Algorithm::SISort - Select And Insert sorting algorithm

=head1 SYNOPSIS

  use Algorithm::SISort qw(Sort Sort_inplace);
  
  @sorted_list = Sort {$_[0] <=> $_[1]} @unsorted_list;
  # ... or ...
  $number_of_comparisons = Sort_inplace {$_[0] <=> $_[1]} @unsorted_list;

=head1 DESCRIPTION

This module implements a sorting algorithm I saw in BIT 28 (1988) by István
Beck and Stein Krogdahl. This implementation is mainly intended to try out the
Inline module by Brian Ingerson. The algorithm is a combination of I<Straight
Insertion Sort> and I<Selection Sort>. While I<Insertion Sort> and I<Selection
Sort> both are of complexity O(n**2), I<Select and Insert Sort> should have
complexity O(n**1.5).

This module defines the functions C<Sort> and C<Sort_inplace>, which have
signatures similar to the internal C<sort> function. The difference is that a
codref defining a comparison is always required and that the two values to
compare are always passed in C<@_> and not as C<$a> and C<$b>. (Although I
might change that later.)

C<Sort> returns a sorted copy if the array, but C<Sort_inplace> sorts the array
in place (as the name suggests) and returns the number of comparisons done. 
(Note that the sorting is always done in place, C<Sort> just copies the array
before calling the internal sort routine.)

=head1 BUGS

Bug-reports are very welcome on the CPAN Request Tracker at:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-SISort

=head1 SEE ALSO

L<Inline>, L<Inline::C>, and I<A Select And Insert Sorting Algorithm> by István
Beck and Stein Krogdahl in I<BIT 28 (1988), 726-735>.

=head1 AUTHOR

Hrafnkell F. Hlodversson, keli@panmedia.dk

=head1 COPYRIGHT

Copyright 2001, Hrafnkell F Hlodversson

All Rights Reserved.  This module is free software. It may
be used, redistributed and/or modified under the terms of
the Perl Artistic License.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__C__

static int compare( SV* callback,  SV* a, SV* b) {
	int retnum,numres;
	dSP;
	SvREFCNT_inc(a);
	SvREFCNT_inc(b);
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(sp);
	XPUSHs(a);
	XPUSHs(b);
	PUTBACK;
	
	numres=call_sv(SvRV(callback), G_SCALAR);
	
	SPAGAIN;
	
	if(numres==1) {
		retnum = POPi;
	} else {
		retnum = 0;
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	return retnum;
}

int _sort (SV* callback, SV* arrayref) {
	int n; /* last element of array */
	int i, j,  step, ncompares;
	SV *min, **minp, **A_i, **A_j, **ptr;
	AV* A;
	
	if (! SvROK(arrayref))
		croak("arrayref is not a reference");
	if (! SvROK(callback))
		croak("callback is not a reference");

	ncompares=0;
	A=(AV*)SvRV(arrayref);
	
	n=av_len(A);

	for(i=0;i<=n;i++) {
		A_i=av_fetch(A,i,0);
		min  = *A_i;
		minp = A_i;
		step = 1;
		j	 = i+step;
		
		/* Select a "minimalish" element: */
		while ( j <= n ) {
			A_j=av_fetch(A,j,0);
			ncompares++;
			if( compare(callback, *A_j, min ) < 0 )  {
				min=*A_j;
				minp=A_j;
			}
			step++;
			j+=step;
		}
		
	
		/* Start insertion: */
		*minp=*A_i;
		
		j = i-1;
		A_j=av_fetch(A,j,0);
		while ( j>-1 && compare(callback, *A_j, min ) > 0 ) {
			ncompares++;
			ptr=av_fetch(A,j+1,0);
			*ptr=*A_j;
			
			j--;
			A_j=av_fetch(A,j,0);
		}
		ncompares++;
		ptr=av_fetch(A,j+1,0);
		*ptr=min;
	}

	return ncompares;

}
