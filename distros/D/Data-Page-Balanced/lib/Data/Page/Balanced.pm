# $Id: Balanced.pm 2 2007-10-27 22:08:58Z kim $

package Data::Page::Balanced;

use warnings;
use strict;
use Carp;
use POSIX qw(ceil floor);
use base qw(Class::Accessor::Chained::Fast Data::Page);
use version; our $VERSION = qv('1.0.0');

__PACKAGE__->mk_accessors(qw(flexibility));

sub new {
	my ($class, $arg_ref) = @_;
	my $self = {};
	
	croak('total_entries and entries_per_page must be supplied.')
		if  !defined $arg_ref->{'total_entries'}
		||  !defined $arg_ref->{'entries_per_page'};
	
	croak( sprintf 'There must be at least one entry per page. %d is too small.', $arg_ref->{'entries_per_page'} )
		if $arg_ref->{'entries_per_page'} < 1;
	
	bless $self, $class;

	# flexibility can be 0, which is false, so can't use ||-assignment
	my $flexibility = exists $arg_ref->{flexibility} ? $arg_ref->{flexibility} : floor($arg_ref->{entries_per_page} / 2);
	
	$self->_flexibility_accessor(       $flexibility                    );
	$self->_total_entries_accessor(     $arg_ref->{total_entries}       );
	$self->_current_page_accessor(      $arg_ref->{current_page} || 1   );
	$self->_entries_per_page_accessor(  $arg_ref->{entries_per_page}    );
	$self->_entries_per_page_accessor(  $self->_get_balanced_epp()      );
	
	return $self;
}

# Calculate the entries_per_page (expected_epp) within the limits of the flexibility
sub _get_balanced_epp {
	my ($self) = @_;
	
	my $flexibility         = $self->flexibility();
	my $total_entries       = $self->total_entries();
	my $entries_per_page    = $self->entries_per_page();
	
	return $entries_per_page
		if $flexibility     == 0
		|| $total_entries   == 0;
	
	return $entries_per_page
	    if $total_entries < $entries_per_page;
		
	my $pages           = ceil($total_entries / $entries_per_page);
	my $expected_epp    = $total_entries / $pages;
	
	ENTRIES: while ( $expected_epp < $entries_per_page ) {
		$pages--;
		
		if ( $pages < 1 ) {
		    $pages = 1;
		}
		
		$expected_epp = $total_entries / $pages;
		
		if ( $expected_epp > $entries_per_page + $flexibility ) {
			$expected_epp = $entries_per_page;
			last ENTRIES;
		}
	}
	
	return ceil($expected_epp);
}

sub total_entries {
	my ($self, $total_entries) = @_;
	
	if ( defined $total_entries ) {
		my $accessor = $self->_total_entries_accessor($total_entries);
		$self->_entries_per_page_accessor( $self->_get_balanced_epp() );
		return $accessor;
	}

	return $self->_total_entries_accessor();
}

sub entries_per_page {
	my ($self, $entries_per_page) = @_;
	
	if ( defined $entries_per_page ) {
		croak( sprintf 'There must be at least one entry per page. %d is too small.', $entries_per_page )
		    if $entries_per_page < 1;
		
		$self->_entries_per_page_accessor($entries_per_page);
		return $self->_entries_per_page_accessor( $self->_get_balanced_epp() );
	}
	
	return $self->_entries_per_page_accessor();
}

sub flexibility {
	my ($self, $flexibility) = @_;
	
	if ( defined $flexibility ) {
		my $accessor = $self->_flexibility_accessor($flexibility);
		$self->_entries_per_page_accessor( $self->_get_balanced_epp() );
		return $accessor;
	}

	return $self->_flexibility_accessor();
}


1;
__END__

=head1 NAME

Data::Page::Balanced - A data pager that will balance the number of entries per page.


=head1 VERSION

This document describes Data::Page::Balanced version 1.0.0


=head1 SYNOPSIS

    use Data::Page::Balanced;

    my $pager = Data::Page::Balanced->new({
        total_entries => 67,
        entries_per_page => 25
    });
    
    print $pager->last_page() # 2
    print $pager->entries_per_page() # 34
  
  
=head1 DESCRIPTION

This module behaves like L<Data::Page> except that it balances the number of entries per page so there is no last page with only a few entries. If, for example, you have 26 entries and want 25 entries per page, a normal pager would give you two pages with 25 entries on the first and 1 on the last. Data::Page::Balanced will instead give you one page with 26 entries.

The benefit of a balanced number of entries per page is greater when the number of pages is small, with the ideal case being when there are two pages with only one entry on the last, in which case Data::Page::Balanced will fold it over to the first page. This saves the user from having to navigate to a page with only one entry, making it easier for him or her to see all the entries at once.

The default flexibility is C<floor(entries_per_page/2)>, which means that in the example with 25 entries per page, the calculated entries per page can go up to 37 (25 + 12). The flexibility can be changed both at initialization and later on.


=head1 SUBROUTINES/METHODS 

=head2 new

    my $pager = Data::Page::Balanced->new({
        total_entries => 67,
        entries_per_page => 25,
        current_page => 1,
        flexibility => 12
    });

This constructs a new pager object. The C<total_entries> and C<entries_per_page> arguments are mandatory, since they are used to calculate the actual number of entries per page.

The C<current_page> and C<flexibility> arguments are optional.

All arguments are given as name-value pairs in an anonymous hash.

=head2 total_entries

    $pager->total_entries(100); # Sets the total entries to 100
    $pager->total_entries();    # Returns the current total entries

This will get or set the total entries. I<Changing this will re-calculate the number of entries per page.>

=head2 entries_per_page

    $pager->entries_per_page(23); # Sets the entries per page to 23
    $pager->entries_per_page();   # Returns the current entries per page

This will get or set the entries per page. I<Since changing this will re-calculate the number of entries per page according to the flexibility, in most cases what you set is not what you later will get.>

=head2 flexibility

    $pager->flexibility(12); # Sets the flexibility to 12
    $pager->flexibility();   # Returns the current flexibility

This will get or set the flexibility value. I<Changing this will re-calculate the number of entries per page.>


=head1 DIAGNOSTICS

=over

=item C<< total_entries and entries_per_page must be supplied. >>

The C<total_entries> and C<entries_per_page> arguments has to be supplied when initializing a new object.

=item C<< There must be at least one entry per page. %d is too small. >>

The number of entries per page is not allowed to be smaller than 1.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Data::Page::Balanced requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Data::Page> L<Class::Accessor::Chained::Fast>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-page-balanced@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kim Ahlström  C<< <kim.ahlstrom@gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Kim Ahlström C<< <kim.ahlstrom@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
