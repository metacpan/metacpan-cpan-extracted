#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 17:13:23 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1844 $
#############################################################################

package Bio::Grep::SearchResult;

use strict;
use warnings;

use version; our $VERSION = qv('0.10.6');

use IO::String;

use base 'Bio::Root::Root';

use Class::MethodMaker [
    new    => 'new2',
    scalar => [
        qw /sequence query begin end alignment sequence_id remark
            percent_identity evalue dG/
    ],
];

sub new {
    my $self    = shift->new2;
    my $arg_ref = shift;

    #initizialize member variables
    for my $key ( keys %{$arg_ref} ) {
        $self->$key( $arg_ref->{$key} );
    }
    return $self;
}

sub reverse_complement {
    my ($self) = @_;
    return $self->query->desc =~ m{ \(reverse\scomplement\) \z }xms;
}

sub mark_subject_uppercase {
    my $self   = shift;
    my $result = $self->sequence->seq;
    if ( !defined $self->begin || !defined $self->end ) {
        return lc $result;
    }
    else {
        return
              lc( substr $result, 0, $self->begin )
            . uc( substr $result, $self->begin, $self->end - $self->begin )
            . lc substr $result, $self->end;
    }
}

sub subject {
    my $self = shift;

    return Bio::Seq->new(
        -id  => $self->sequence->id,
        -seq => $self->sequence->subseq( $self->begin + 1, $self->end )
    );
}

sub upstream {
    my $self = shift;

    return Bio::Seq->new(
        -id  => $self->sequence->id,
        -seq => $self->sequence->subseq( 1, $self->begin )
    );
}

sub downstream {
    my $self = shift;

    return Bio::Seq->new(
        -id  => $self->sequence->id,
        -seq => $self->sequence->subseq(
            $self->end + 1,
            length $self->sequence->seq
        )
    );
}

sub alignment_string {
    my $self   = shift;
    my $result = q{};
    my $str    = IO::String->new();
    my $out    = Bio::AlignIO->new( -format => 'clustalw', -fh => $str );
    if ( !defined $self->alignment ) {
        $self->warn('No alignment calculated.');
        return q{};
    }
    $out->write_aln( $self->alignment );
    $out->close();
    $str = IO::String->new( ${ $str->string_ref } );
LINE:
    while ( my $l = <$str> ) {
        next LINE if ( $l =~ /CLUSTAL/xms || $l =~ /\A \s+ \z/xms );
        $result .= $l;
    }
    return $result;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::Grep::SearchResult - Data structure for a back-end search hit

=head1 SYNOPSIS
  
  # output the search results with nice alignments
  while ( my $res = $sbe->next_res ) {
     # $res->sequence is a Bio::Seq object with down-/upstream regions
     # see Bio::Grep::SearchSettings
     print $res->sequence->id . "\n";
     
     # $res->subject is a Bio::Seq object without down-/upstream regions 
     print $res->subject->seq . "\n";

     # print down-/upstream regions lower case, subject seq. uppercase
     print $res->mark_subject_uppercase() . "\n";
     
     # output alignment
     print $res->alignment_string() . "\n";

     # print coordinates: perldoc Bio::SimpleAlign, Bio::LocatableSeq
     $print $res->alignment->get_seq_by_pos(1)->start . "\n\n";
  }

=head1 DESCRIPTION

B<Bio::Grep::SearchResult> is the data structure for one hit in the
database.

=head1 METHODS

See L<Bio::Grep::Root> for inherited methods.

=head2 CONSTRUCTOR

=over 

=item C<new($arg_ref)>;

This function constructs a Bio::Grep::SearchResult object. Takes as argument a
hash reference that initializes the member variables below.

Only called by the back-end parser. 

    my $result = Bio::Grep::SearchResult->new(
        {   sequence         => $seq,
            begin            => $begin,
            end              => $end,
            alignment        => $alignment,
            ...
            percent_identity => $identity,
        }
    );

=back

=head2 PACKAGE METHODS

=over 

=item C<subject()>

Creates a L<Bio::Seq> object with the sequence found in the database (see 
sequence()) , but without upstream and downstream 
regions. 

=item C<upstream()>

The upstream region as L<Bio::Seq> object. See subject().

=item C<downstream()>

The downstream region as L<Bio::Seq> object. See subject().

=item C<reverse_complement()>  

Returns a true value if hit is a reverse complement hit, 0 otherwise.

=back

Some predefined methods for printing objects: 

=over 

=item C<mark_subject_uppercase()>

This function returns the sequence in a string. the substring from
C<$self-E<gt>begin> to C<$self-E<gt>end> will be in uppercase, the rest in 
lowercase.

=item C<alignment_string()>

This function returns a string with the formatted alignment. We use CLUSTALW
Format without many blank lines and CLUSTAL header. In some back-ends like
Agrep, this function will return an empty string if C<no_alignments> is true.

=back

=head2 ACCESSORS/MUTATORS

Following the Bioperl guidelines, accessors are also mutators:

  $res->sequence('CCCCC');
  print $res->sequence; # prints CCCCC

=over

=item C<sequence()>

Get/set the sequence found in database with up- and downstream regions. 
L<Bio::Seq> object.

=item C<query()>

Get the query as L<Bio::Seq> object. Useful for multiple queries. If
<direct_and_rev_com> is set, then a reverse complement hit is marked with
' (reverse complement)' in C<$query-E<gt>desc> and C<reverse_complement> (see
below) is 1.

  # DON'T DO THIS:  
  if ($query->desc =~ m{ \(reverse\scomplement\)\z}xms) {
     ...
  }

  # use reverse_complement instead:
  if ($res->reverse_complement) {
    ...
  }

=item C<alignment()>

Get/set the alignment of the match. See L<Bio::SimpleAlign> for details. There
are powerful modules for converting this module in many formats. See 
L<Bio::AlignIO> for details.

=item C<sequence_id()>

Get/set the sequence id in database. This is an internal id of the
back-end, not any id of some annotation in the sequence name. The internal id
can be used in the back-end function get_sequences()
(See L<Bio::Grep::Backend::BackendI>).

=item C<begin()>

Get/set the position of the beginning of the subject in the sequence. This 
allows retrieving upstream regions from the back-end. First position is 0.

    my $seq = $res->sequence->seq;
    my $upstream   = substr $seq, 0, $res->begin;
    my $subject    = substr $seq, $res->begin, $res->end - $res->begin;
    my $downstream = substr $seq, $res->end;

Note that C<$res-E<gt>begin> differs from C<$sbe-E<gt>settings-E<gt>upstream> 
if the available upstream region is smaller than requested!

=item C<end()>

Get/set the position of the end of the subject in the sequence. This allows
retrieving downstream regions from the back-end. See C<begin()>.

=item C<dG()>

Get/set C<dG> . See L<Bio::Grep::RNA::HybridizationI> for details.

=item C<remark()>

Get/set some additional information like filter results to this hit.

=item C<evalue()>

Get/set the evalue of this hit.

=item C<percent_identity()>

Get/set the identity in percent of this hit. 

=back

=head1 SEE ALSO

L<Bio::SimpleAlign> 
L<Bio::LocatableSeq> 
L<Bio::AlignIO> 
L<Bio::Seq>
L<Bio::SeqIO>
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
