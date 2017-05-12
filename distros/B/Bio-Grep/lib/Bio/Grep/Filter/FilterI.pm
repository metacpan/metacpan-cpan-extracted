#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 14:21:37 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1843 $
#############################################################################

package Bio::Grep::Filter::FilterI;

use strict;
use warnings;

use version; our $VERSION = qv('0.10.6');

use base 'Bio::Root::Root';

use Class::MethodMaker [
    new      => 'new2',
    scalar   => [qw /search_result message delete/],
    hash     => [qw /supports_alphabet/],
    abstract => [qw /filter new reset_filter /],
];

1;    # Magic true value required at end of module
__END__


=head1 NAME

Bio::Grep::Filter::FilterI - Superclass for all filter modules   

=head1 SYNOPSIS

   package MyFilter;
   
   use strict;
   use warnings;
   
   use Bio::Grep::Filter::FilterI;
   
   use base 'Bio::Grep::Filter::FilterI';
   
   use Class::MethodMaker
    [ new => [ qw / new2 / ],
      ... # here some local variables, see perldoc Class::MethodMaker
    ];
   
   sub new {
      my $self = shift->new2;
      $self->delete(1); # a filter that actually filters, not only adds
                        # remarks to $self->search_result->remark

      $self->supports_alphabet( dna => 1, protein => 1);
      $self;
   }
   
   sub filter {
      my $self = shift;
      # code that examines $self->search_result
      # and returns 0 (not passed) or 1 (passed)
      ...
      $self->message('passed');
      return 1;
   }   
   
   sub reset_filter {
      my $self = shift;
      # if you need local variables, you can clean up here
   }

   1;# Magic true value required at end of module


=head1 DESCRIPTION

B<Bio::Grep::Filter::FilterI> is the superclass for all filter modules. 
Don't use this directly. 

A Filter module implements a filter function that
returns 1 if query and subject pass the filter, 0 otherwise.
If the member variable "delete" is 1, then this subject won't
be in the search results of the back-end.


=head1 METHODS

See L<Bio::Grep::Root> for inherited methods.

=head2 ACCESSORS/MUTATORS

Following the Bioperl guidelines, accessors are also mutators:

  $filter->delete(1);
  if ($filter->delete) {
    ...
  }

=over

=item C<$filter-E<gt>delete()>

Get/set delete. If this is 0, then the search result will not be deleted  
(but you will still have the filter message). 
Otherwise, this hit won't be included in the search results of the back-end. 
Default is 1.

=back

=head2 ABSTRACT METHODS

Every filter must implement these methods:

=over

=item C<new()>

This function constructs a filter object.

=item C<$filter-E<gt>supports_alphabet()>

Get supported alphabets. Returns a hash. Keys are the supported alphabets.

    my $can_filter_proteins = $filter->supports_alphabet_exists('protein');

=back

=head2 INTERNAL METHODS

Only L<Bio::Grep::Backend::BackendI> should call them directly.

=over

=item C<$filter-E<gt>filter()>

This function returns 1 if query and subject pass the filter, 0 otherwise. You
have to set the search result with the function
C<$filter-E<gt>search_result> before. L<Bio::Grep::Backend::BackendI>
takes care of that.

=item C<$filter-E<gt>reset_filter()>

Get/set reset_filter. A flag needed by some Filters like
L<Bio::Grep::Filter::FilterRemoveDuplicates> to tell them, it
is a new search, forget everything. 

=item C<$filter-E<gt>message()>

Get/set the message. This is a string with the reason for rejecting the search
result. 

=item C<$filter-E<gt>search_result()>

Get/set the search_result. A L<Bio::Grep::SearchResult>
object. 

=back

=head1 MOTIVATION

You might wonder why or when you should write a Filter object instead of 
filtering in the while loop:

=over

=item Code reuse:

Is it likely that you need the code (or parts of it) in other projects? Do you
think other people may find your code useful? Good candidates here are parsers 
for other programs (that perform thermodynamic calculations for example).

=item Debugging:

It is easier to debug and test modular code than whole scripts. Additionally,
the code in your script is easier to understand and maintain.

=back

=head1 SEE ALSO

L<Bio::Grep::Backend::BackendI>
L<Bio::Grep::SearchResult>

=head1 AUTHOR

Markus Riester, E<lt>mriester@gmx.deE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2009 by M. Riester. 

Based on Weigel::Search v0.13, Copyright (C) 2005-2006 by Max Planck 
Institute for Developmental Biology, Tuebingen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
