#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 19:54:03 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1848 $
#############################################################################

package Bio::Grep::Backend::RE;

use strict;
use warnings;

use version; our $VERSION = qv('0.10.6');
use Carp::Assert;

use autodie qw(open close seek);

use Bio::Grep::SearchResult;
use Bio::Grep::Backend::BackendI;

use base 'Bio::Grep::Backend::Agrep';

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    return $self;
}

sub _init {
    my ($self) = @_;
    my %all_features = $self->features;
    delete $all_features{GUMISMATCHES};
    delete $all_features{EVALUE};
    delete $all_features{PERCENT_IDENTITY};
    delete $all_features{ONLINE};
    delete $all_features{COMPLETE};
    delete $all_features{QUERY_FILE};
    delete $all_features{QUERY_LENGTH};
    delete $all_features{SHOWDESC};
    delete $all_features{QSPEEDUP};
    delete $all_features{HXDROP};
    delete $all_features{EXDROP};
    delete $all_features{REVCOM_DEFAULT};
    delete $all_features{NATIVE_D_A_REV_COM};
    delete $all_features{MISMATCHES};
    delete $all_features{DELETIONS};
    delete $all_features{INSERTIONS};
    delete $all_features{EDITDISTANCE};
    $self->features(%all_features);
    $self->{_line_regex} = qr{\A(.*):(.*)\z}xmso;
    return;
}

sub search {
    my ( $self, $arg_ref ) = @_;
    my $s = $self->settings;
    $self->_check_search_settings($arg_ref);
    my ( $query, $query_obj, $db_alphabet ) = $self->_bioseq_query();
    my $regex = $query;

    # regular expressions can't be Bio::Seq objects
    if ( defined $query_obj->seq ) {
        $self->{_qmapping} = { lc( $query_obj->seq ) => $query_obj };
    }
    $self->{_qmapping} = { default => $query_obj };

    if ( $s->direct_and_rev_com || $s->reverse_complement ) {
        if ( $regex !~ m{\A [gactu]+ \z}xmsi ) {
            $self->throw(
                -class => 'Bio::Root::BadParameter',
                -text =>
                    "While doing a reverse-complement the query does not look like a DNA/RNA\n"
                    . 'sequence.',
                -value => $regex,
            );
        }
        my $query_revcom_obj = Bio::Seq->new(
            -id   => $query_obj->id,
            -desc => $query_obj->desc . ' (reverse complement)',
            -seq  => $query_obj->revcom->seq
        );
        $self->{_qmapping}->{ lc $query_revcom_obj->seq } = $query_revcom_obj;
        if ( $s->direct_and_rev_com ) {
            $regex = $regex . q{|} . $query_revcom_obj->seq;
        }
        else {
            $regex = $query_revcom_obj->seq;
        }
    }

    # compile the regex
    $self->{_regex}  = qr{$regex}imsx;
    $self->{_puffer} = [];

    open my $FH, '<',
        $self->_cat_path_filename( $s->datapath, $s->database . '.dat' );
    $self->_output_fh($FH);

    my $indexfile = $s->datapath . q{/} . $s->database . '.idx';
    $self->{'_idx'} = Bio::Index::Fasta->new($indexfile);

    $self->_load_mapping();
    $self->_prepare_results;
    return 1;
}

sub _parse_next_res {
    my $self = shift;
    my $s    = $self->settings;
    if ( scalar @{ $self->{_puffer} } > 0 ) {
        return shift @{ $self->{_puffer} };
    }

    my $FH = $self->_output_fh;
    while ( my $line = <$FH> ) {
        chomp $line;
        my ( $linenumber, $complete_seq ) = $line =~ $self->{_line_regex};

        # store sequence for multiple queries (TODO)
        my $seq        = $complete_seq;
        my $found_hits = 0;
        my $seq_obj;
    HIT:
        while ( $seq =~ /$self->{_regex}/gxms ) {
            if (   $s->maxhits_isset
                && $self->_current_res_id + $found_hits > $s->maxhits )
            {
                seek $FH, 0, 2;
                last HIT;
            }
            if ( $found_hits == 0 ) {
                $seq_obj = $self->{_idx}
                    ->fetch( $self->{_mapping}->{$linenumber} );
            }
            $found_hits++;

            # get coordinates of hit
            my $subject_begin = $-[0];
            my $subject_seq = substr $seq, $-[0], $+[0] - $-[0];

            my $subject_end = $+[0];

            my ( $upstream_seq, $dummy, $downstream_seq )
                = $self->_parse_regions(
                {   complete_seq  => $complete_seq,
                    subject_begin => $subject_begin,
                    subject_end   => $subject_end,
                }
                );

            assert( $dummy eq $subject_seq ) if DEBUG;

            my $sequence = Bio::Seq->new(
                -id   => $seq_obj->id,
                -desc => $seq_obj->desc,
                -seq  => $upstream_seq . $subject_seq . $downstream_seq,
            );

            my $tmp_aln = Bio::SimpleAlign->new( -source => 'Bio::Grep' );
            $tmp_aln->add_seq(
                Bio::LocatableSeq->new(
                    -id    => 'Subject',
                    -seq   => $subject_seq,
                    -start => $subject_begin + 1,    # starts at 1, not 0
                    -end   => $subject_end,
                )
            );

            my $query_obj = $self->{_qmapping}->{ lc $subject_seq };
            if ( !defined $query_obj ) {
                $query_obj = $self->{_qmapping}->{default};
                $query_obj->seq($subject_seq);
            }
            $tmp_aln->add_seq(
                Bio::LocatableSeq->new(
                    -id    => $query_obj->id,
                    -seq   => $subject_seq,
                    -start => 1,
                    -end   => length($subject_seq),
                )
            );

            my $res = $self->_filter_result(
                Bio::Grep::SearchResult->new(
                    {   sequence    => $sequence,
                        begin       => length($upstream_seq),
                        end         => length( $upstream_seq . $subject_seq ),
                        alignment   => $tmp_aln,
                        sequence_id => $sequence->id,
                        remark      => q{},
                        query       => $query_obj,
                    }
                )
            );

            if ($res) {
                push @{ $self->{_puffer} }, $res;
            }

        }
        if ( scalar @{ $self->{_puffer} } > 0 ) {
            return shift @{ $self->{_puffer} };
        }
    }
    return;
}

sub available_sort_modes {
    my ($self) = @_;
    return (
        ga => 'ascending order of dG',
        gd => 'descending order of dG',
    );
}

1;    # Magic true value required at end of module
__END__


=head1 NAME

Bio::Grep::Backend::RE - Perl Regular Expression back-end  


=head1 SYNOPSIS

  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('RE');
  
  $sbe->settings->datapath('data');
  
  # generate a database. you have to do this only once. 
  $sbe->generate_database({ 
    file        => 'ATH1.cdna', 
    description => 'AGI Transcripts',
    datapath    => 'data',
  });
  
  # search on both strands  
  # retrieve up- and downstream regions of size 30
  
  $sbe->search({
    query   => 'GAGCCCTT',
    direct_and_rev_com => 1, 
    upstream           => 30,
    downstream         => 30,
    database           => 'ATH1.cdna',
  });
  
  my @internal_ids;
  
  # output the searchresults with nice alignments
  while ( my $res = $sbe->next_res) {
     print $res->sequence->id . "\n";
     print $res->mark_subject_uppercase() . "\n";
     print $res->alignment_string() . "\n\n";
     push @internal_ids, $res->sequence_id;
  }
  
  # get the complete sequences as Bio::SeqIO object
  my $seq_io = $sbe->get_sequences(\@internal_ids);

  # sequences with at least 10 As
  $sbe->search({ query => '[A]{10,}' });
 
  # some SNPs
  $sbe->search({query => '[CG]TGC[AT]CTCTTCT[CG]TCA'});

=head1 DESCRIPTION

B<Bio::Grep::Backend::RE> searches for a query with a
Perl Regular Expression. 

Internally, it pre-compiles the specified regex (with the appended modifiers
i, m, s and x), matches it against every line in the database with the looping
modifier g, and then returns the positions retrieved with $- and $+. The
C<substr> function is then used to extract the sequences.

This back-end does not perform any sanity checks of the regular expressions,
so do NOT provide this back-end in a web service.

=head1 METHODS

See L<Bio::Grep::Backend::BackendI> for inherited methods. 

=head2 CONSTRUCTOR

=over 

=item C<Bio::Grep::Backend::RE-E<gt>new()>

This method constructs a C<RE> back-end object and should not used directly.  
Rather, a back-end should be constructed by the main class L<Bio::Grep>:

  my $sbe = Bio::Grep->new('RE');

=back

=head2 PACKAGE METHODS

=over 

=item C<$sbe-E<gt>available_sort_modes()>

Returns all available sort modes as hash. keys are sort modes, values a short
description.

   $sbe->sort('ga');

Available sort modes in C<RE>:

=over

            ga  : 'ascending order of dG'
            gd  : 'descending order of dG'

=back

Note that 'ga' and 'gd' require that search results have dG set. 
L<Bio::Grep::RNA> ships with filters for free energy calculation. Also note that
these two sort options require that we load all results in memory.

=back

=head1 IMPORTANT NOTES

=over

=item Code Quality

B<BETA RELEASE!> 

=item C<reverse_complement> 

C<reverse_complement> (and C<direct_and_rev_com> ) are supported, but are
only available for DNA/RNA queries, not for regular expressions.

=item Regular Expression modifiers

The i,m,s and x modifiers are added to the regex. 

=item RNA

Be careful with RNA sequences: U is not the same as T in this back-end!

=item C<maxhits>

When C<maxhits> is defined, the sliding window stops when I<maxhits>
hits were found.

=item Database

L<Bio::Grep::Backend::RE> databases are compatible with
L<Bio::Grep::Backend::Agrep> databases.

=back

=head1 DIAGNOSTICS

See L<Bio::Grep::Backend::BackendI> for other diagnostics. 

=over

=item C<While doing a reverse-complement the query does not look like a...>

Either C<reverse_complement> or C<direct_and_rev_com> is set and the query
does not match the regular expression C<m{\A [gactu]+ \z}xmsi>. C<Bio::Root::BadParameter>.

=item C<Query not defined.>

You forgot to define C<$sbe-E<gt>settings-E<gt>query>. C<Bio::Root::BadParameter>.

=back

=head1 SEE ALSO

L<Bio::Grep::Backend::BackendI>
L<Bio::Grep::SearchSettings>
L<Bio::SeqIO>
L<Bio::Index::Fasta>

=head1 AUTHOR

Markus Riester, E<lt>mriester@gmx.deE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2009 by M. Riester. 

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
