#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 14:21:37 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1843 $
#############################################################################

package Bio::Grep::Filter::FilterRemoveDuplicates;

use strict;
use warnings;

use Bio::Grep::Filter::FilterI;

use base 'Bio::Grep::Filter::FilterI';

use version; our $VERSION = qv('0.10.6');

use Class::MethodMaker [
    new  => [qw /new2/],
    hash => [qw /_ids/],
];

sub new {
    my $self = shift->new2;
    $self->delete(1);
    $self->supports_alphabet( dna => 1, protein => 1 );
    return $self;
}

sub filter {
    my $self = shift;
    my %ids  = $self->_ids;
    my ($id) = $self->search_result->sequence->id =~ m{\A (.*) \. \d+ \z}xms;
    if ( !defined $id ) {
        $id = $self->search_result->sequence->id;
    }
    return 0 if defined $ids{$id};
    $ids{$id} = 1;
    $self->_ids(%ids);
    return 1;
}

sub reset_filter {
    my $self = shift;
    $self->_ids_reset;
    return;
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::Grep::Filter::FilterRemoveDuplicates - Example Filter  

=head1 SYNOPSIS

 my $rd_filter =  Bio::Grep::Filter::FilterRemoveDuplicates->new(); 

 $sbe->search({
    query   => $query,
    filters => [ $rd_filter ],
 });
 
=head1 DESCRIPTION

B<Bio::Grep::Filter::FilterRemoveDuplicates> is an example filter that allows 
only unique sequence ids in search results. It is useful if you are only
interested in which genes the query was found. Deletes the result if 
the id already occurred. Ignores suffixes of the form ".xx", where xx are digit
characters (this normally represents alternative splice forms).

=head1 METHODS

See L<Bio::Grep::Filter::FilterI> for inherited methods.

=head2 CONSTRUCTOR

=over

=item C<Bio::Grep::Filter::FilterRemoveDuplicates-E<gt>new()>

This function constructs a FilterRemoveDuplicates object. 

=back

=head1 SEE ALSO

L<Bio::Grep::Filter::FilterI>
L<Bio::Grep::Backend::BackendI>

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
