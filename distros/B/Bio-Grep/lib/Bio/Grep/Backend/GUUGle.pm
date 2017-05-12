#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 19:54:03 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1848 $
#############################################################################

package Bio::Grep::Backend::GUUGle;

use strict;
use warnings;

use version; our $VERSION = qv('0.10.6');

use autodie qw(open close);
use English qw( -no_match_vars );

use Bio::Grep::SearchResult;
use Bio::Grep::Backend::BackendI;

use base 'Bio::Grep::Backend::BackendI';

use List::Util qw(max);

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    my %all_features = $self->features;
    delete $all_features{EVALUE};
    delete $all_features{PERCENT_IDENTITY};
    delete $all_features{MISMATCHES};
    delete $all_features{DELETIONS};
    delete $all_features{INSERTIONS};
    delete $all_features{EDITDISTANCE};
    delete $all_features{ONLINE};
    delete $all_features{COMPLETE};
    delete $all_features{SHOWDESC};
    delete $all_features{QSPEEDUP};
    delete $all_features{PROTEINS};
    delete $all_features{HXDROP};
    delete $all_features{EXDROP};
    delete $all_features{NATIVE_D_A_REV_COM};
    $self->settings->gumismatches(0);
    $self->features(%all_features);
    return $self;
}

sub search {
    my ( $self, $arg_ref ) = @_;
    my $s = $self->settings;
    $self->_check_search_settings($arg_ref);

    my ( $query, $query_file, $tmp_query_file )
        = $self->_create_tmp_query_file();

    # now generate the command string
    my $eflag = q{};
    if ( $s->upstream > 0 || $s->downstream > 0 ) {
        $eflag = ' -e ' . max( $s->upstream, $s->downstream ) . q{ };
    }

    if ( $s->gumismatches > 0 && !$s->direct_and_rev_com ) {
        $self->warn( "GUUGle counts GU always as no mismatch.\n"
                . 'Set gumismatches(0) to hide this warning.' );
    }
    if ( !$s->reverse_complement && $s->query_file ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text => 'GUUGle searches only for the reverse ' . 'complement. ',
            -value => $s->reverse_complement,
        );
    }

    my $lflag = q{};
    if ( $s->maxhits_isset ) {
        $lflag = ' -l ' . $s->maxhits . q{ };
    }

    #set query_length automatically
    my $auto_query_length = 0;
    if ( !defined $s->query_length ) {
        if ($query) {
            $s->query_length( length $query );
            $auto_query_length = 1;
        }
        else {
            $self->throw(
                -class => 'Bio::Root::BadParameter',
                -text  => 'query_length not set. See -d flag in the '
                    . 'GUUGle documentation. ',
            );
        }
    }

    my $command
        = $self->_cat_path_filename( $s->execpath, 'guugle' ) 
        . $eflag
        . $lflag . ' -d '
        . $s->query_length . q{ }
        . $self->_cat_path_filename( $s->datapath, $s->database ) . q{ }
        . $tmp_query_file;

    if ( $ENV{BIOGREPDEBUG} ) {
        warn $command . "\n";
    }

    my $cmd_ok = $self->_execute_command($command);

    if ( !$cmd_ok ) {
        $self->throw(
            -class => 'Bio::Root::SystemException',
            -text  => "GUUGle call failed. Command was:\n\t$command"
        );
    }

    $self->_skip_header();
    my %query_desc_lookup;
    foreach my $query_seq ( @{ $self->_query_seqs } ) {

        # simulate how this sequence would look in guugle output
        my $query_desc = $query_seq->id;
        if ( $query_seq->desc && length($query_desc) > 0 ) {
            $query_desc .= q{ } . $query_seq->desc;
        }
        $query_desc_lookup{$query_desc} = $query_seq;
    }
    $self->{_mapping} = \%query_desc_lookup;
    $self->_prepare_results;
    if ($auto_query_length) {
        $self->settings->query_length_reset;
    }
    return 1;
}

sub get_databases {
    my $self = shift;
    return $self->_get_databases('.al1');
}

sub generate_database {
    my ( $self, @args ) = @_;

    my %args = $self->_prepare_generate_database(@args);

    if ( defined $args{skip} ) {
        return 0;
    }

    $self->_create_index_and_alphabet_file( $args{filename} );
    return 1;
}

sub _skip_header {
    my ($self)      = @_;
    my $FH          = $self->_output_fh;
    my $blank_lines = 0;
    while ( my $line = <$FH> ) {
        chomp $line;

        # skip everything before first line
        if ( $line =~ m{\A \s* \z}xms ) {
            $blank_lines++;
            return if $blank_lines == 2;
        }
    }
    return;
}

sub _rnas_match {
    my ( $self, $s1, $s2 ) = @_;
    return 1 if $s1 eq $s2;
    return 0 if length $s1 != length $s2;

    # now check for wobble pairs
    for my $i ( 0 .. ( length($s1) - 1 ) ) {
        my $base_a = substr $s1, $i, 1;
        my $base_b = substr $s2, $i, 1;
        if (   $base_a ne $base_b
            && join( q{}, $base_a, $base_b ) ne 'uc'
            && join( q{}, $base_a, $base_b ) ne 'ga' )
        {
            return 0;
        }
    }
    return 1;
}

sub _get_subject_id_and_desc {
    my ( $self, $text ) = @_;
    if ( $text =~ m{(.*?)\s(.*)}xms ) {
        return ( $1, $2 );
    }
    else {
        return ( $text, q{} );
    }
}

sub _parse_next_res {
    my $self       = shift;
    my $s          = $self->settings;
    my @query_seqs = $self->_query_seqs;

    # temp variables. for parsing only
    my ($subject_id,  $subject_desc, $subject_pos,
        $subject_seq, $query_desc,   $query_pos,
        $query_seq,   $matchlength,  $upstream
    ) = ( 0, q{}, 0, 0, q{}, 0, 0, 0, 0 );

    my ( $up_seq, $down_seq ) = ( q{}, q{} );

    my $FH = $self->_output_fh;
LINE:
    while ( my $line = <$FH> ) {
        chomp $line;

        if ($line =~ m{\A
                MatchLength:\s(\d+)\s
                "(.*?)"
                \sat\s(\d+)\s
                vs\.\s
                "(.*?)"\s
                at\s(\d+)
             }xms
            )
        {
            (   $matchlength, $subject_id, $subject_pos,
                $query_desc,  $query_pos
            ) = ( $1, $2, $3, $4, $5 );
            ( $subject_id, $subject_desc )
                = $self->_get_subject_id_and_desc($subject_id);

            next LINE;
        }

        if ($line =~ m{\A
                >(.*?)
                _at_(\d+)
                _with_
                (.*?)
                _at_(\d+)
             }xms
            )
        {    # -e mode

            ( $subject_id, $subject_pos, $query_desc, $query_pos, )
                = ( $1, $2, $3, $4, );
            ( $subject_id, $subject_desc )
                = $self->_get_subject_id_and_desc($subject_id);
            next LINE;
        }

        if ( $line =~ m{ \A 5 (.*) 3 \z}xms ) {
            $subject_seq = $1;
            next LINE;
        }

        if ( $line =~ m{ \A 3 (.*) 5 \z}xms ) {
            $query_seq = $1;
            next LINE;
        }

        if ( $line =~ m{\A Maximum\snumber}xms ) {
            last LINE;
        }

        # find the query that belongs to the match
        my $query = $self->{_mapping}->{$query_desc};

        # already reverse, so just the complement here:
        $query_seq =~ tr[UTGCAutgca][AACGUaacgu];

        # -e mode
        if ( $line =~ m{ \A [gucaGUCA]+ \z }xms ) {

            # find subject in string. a little bit complicated because
            # don't know if the upstream/downstream region is as large
            # as we request
            my $qrc = lc $query->revcom->seq;
            $qrc =~ s/t/u/gxms;
            my $ql = $s->query_length || length $query->seq;
        SUBSTRING:
            for my $length ( reverse $ql .. length $query->seq ) {
            STARTPOSITION:
                for my $start (
                    reverse 0 .. max( $s->upstream, $s->downstream ) )
                {
                    my $query_start
                        = length( $query->seq ) - $query_pos + 1 - $length;
                    my $qs = substr $qrc,  $query_start, $length;
                    my $ss = substr $line, $start,       $length;

                #warn "L:$length S:$start QS:$query_start $qrc $qs $line $ss";
                    next STARTPOSITION if !( $self->_rnas_match( $ss, $qs ) );
                    $subject_pos = $start;
                    $subject_seq = $ss;
                    $query_seq   = $qs;
                    $matchlength = $length;
                    $upstream    = $start;
                    $up_seq      = substr $line, 0, $upstream;
                    $down_seq    = substr $line, $upstream + $length;

                    # now check if regions are larger than
                    # expected. can happen when up/down differ
                    if ( length($up_seq) > $s->upstream ) {
                        $up_seq = substr $up_seq,
                            length($up_seq) - $s->upstream;
                        $upstream = length $up_seq;
                    }
                    if ( length($down_seq) > $s->downstream ) {
                        $down_seq = substr $down_seq, 0, $s->downstream;
                    }
                    last SUBSTRING;
                }
            }
        }
        my $fasta = Bio::Seq->new(
            -id   => $subject_id,
            -seq  => $up_seq . $subject_seq . $down_seq,
            -desc => $subject_desc,
        );
        my $tmp_aln = Bio::SimpleAlign->new( -source => 'Bio::Grep' );
        $tmp_aln->add_seq(
            Bio::LocatableSeq->new(
                -id    => 'Subject',
                -seq   => $subject_seq,
                -start => $subject_pos,
                -end   => $subject_pos + length($subject_seq) - 1,
            )
        );
        $tmp_aln->add_seq(
            Bio::LocatableSeq->new(
                -id    => $query->id,
                -desc  => $query->desc,
                -seq   => $query_seq,
                -start => $query_pos,
                -end   => $query_pos + length($query_seq) - 1,
            )
        );
        my $res = $self->_filter_result(
            Bio::Grep::SearchResult->new(
                {   sequence    => $fasta,
                    begin       => $upstream,
                    end         => $upstream + $matchlength,
                    alignment   => $tmp_aln,
                    sequence_id => $fasta->id,
                    remark      => q{},
                    query       => $query,
                }
            )
        );
        if ($res) {
            return $res;
        }
    }
    close $FH;

    #$self->_delete_output();
    return 0;
}

sub get_sequences {
    my ( $self, $seqid ) = @_;
    return $self->_get_sequences_from_bio_index($seqid);
}

sub available_sort_modes {
    my ($self) = @_;

    # get sort modes from superclass
    return ( $self->SUPER::available_sort_modes() );
}
1;    # Magic true value required at end of module
__END__


=head1 NAME

Bio::Grep::Backend::GUUGle - GUUGle back-end  


=head1 SYNOPSIS

  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('GUUGle');
  
  # generate a GUUGle Bio::Grep database. you have to do this only once.
  # GUUGle does not create a persistent index right now.
  # This function generates an fast index for $sbe->get_sequences
  # and files with a description and the alphabet (only DNA/RNA allowed)
  $sbe->generate_database({ 
    file        => 'ATH1.cdna', 
    description => 'AGI Transcripts',
    datapath    => 'data',
  });
 
  # search on both strands (GU allowed) 
  # retrieve up- and downstream regions of size 30
  $sbe->search({
    query   => 'AGAGCCCT',
    direct_and_rev_com => 1, 
    upstream           => 30,
    downstream         => 30,
    gumismatches       => 0,
    database           => 'ATH1.cdna',
  });

  my @internal_ids;

  # output all informations we have!
  while ( my $res = $sbe->next_res ) {
     print $res->sequence->id . "\n";
     print $res->mark_subject_uppercase() . "\n";
     print $res->alignment_string() . "\n\n";
     push @internal_ids, $res->sequence_id;
  }
  
  # get the complete sequences as Bio::SeqIO object
  my $seq_io = $sbe->get_sequences(\@internal_ids);
  
  # search for targets (GU allowed)
  $sbe->search({
    query   => 'GAGCCCTTGGGGGGG',
    reverse_complement => 1, 
    gumismatches       => 0,
  });

=head1 DESCRIPTION

B<Bio::Grep::Backend::GUUGle> searches for a query in a C<GUUGle> suffix 
array. 


=head1 METHODS

See L<Bio::Grep::Backend::BackendI> for inherited methods. 

=head2 CONSTRUCTOR

=over 

=item C<Bio::Grep::Backend::GUUGle-E<gt>new()>

This method constructs a C<GUUGle> back-end object and should not used 
directly. Rather, a back-end should be constructed by the main class 
L<Bio::Grep>:

  my $sbe = Bio::Grep->new('GUUGle');

=back

=head2 PACKAGE METHODS

=over

=item C<$sbe-E<gt>available_sort_modes()>

Returns all available sort modes as hash. keys are sort modes, values a short
description.

   $sbe->sort('ga');

Available sort modes in C<GUUGle>:

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

=item C<reverse_complement>

C<GUUGle> always searches for the reverse complement. If you specify
a query file, C<Bio::Grep> throws an exception if C<reverse_complement> is 
not set.

=item C<mismatches>

C<GUUGle> only allows search for exact matches. It counts GU as no
mismatch.

=item C<maxhits>

When "maxhits" is defined, this back-end returns the I<maxhits> first
hits.

=back

=head1 DIAGNOSTICS

See L<Bio::Grep::Backend::BackendI> for other diagnostics. 

=over

=item C<GUUGle call failed. Command was: ...> 

It was not possible to run C<GUUGle> in function search(). Check the search
settings. If you want to reproduce the system() call, you can set the 
environment variable C<BIOGREPDEBUG>. If this variable is set, then the temporary
files won't get deleted. C<Bio::Root::SystemException>.

=item C<GUUGle searches only for the reverse complement.> 

You have specified a query file and C<reverse_complement> is not set. 
C<Bio::Root::BadParameter>.

=item C<query_length not set. See -d flag in the...>

You have specified a query file and forgot to set C<query_length>.
C<Bio::Root::BadParameter>.

=back

=head1 SEE ALSO

L<Bio::Grep::Backend::BackendI>
L<Bio::Grep::SearchSettings>
L<Bio::Seq>


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
