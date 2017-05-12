#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 19:54:03 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1848 $
#############################################################################

package Bio::Grep::Backend::Agrep;

use strict;
use warnings;

use Carp::Assert;
use version; our $VERSION = qv('0.10.6');

use autodie qw(open close);

use Bio::Grep::SearchResult;
use Bio::Grep::Backend::BackendI;

use base 'Bio::Grep::Backend::BackendI';

use IO::String;

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    $self->_init;
    return $self;
}

sub _init {
    my ($self) = @_;
    my %all_features = $self->features;

    # agrep implementation features
    # TODO
    delete $all_features{FILTERS};
    delete $all_features{UPSTREAM};
    delete $all_features{DOWNSTREAM};
    delete $all_features{SORT};
    delete $all_features{QUERY_FILE};
    delete $all_features{QUERY_LENGTH};
    delete $all_features{DIRECT_AND_REV_COM};
    delete $all_features{NATIVE_D_A_REV_COM};

    # not available in any agrep implemenation
    delete $all_features{MAXHITS};
    delete $all_features{GUMISMATCHES};
    delete $all_features{REVCOM_DEFAULT};
    delete $all_features{NATIVE_ALIGNMENTS};

    # no vmatch features
    delete $all_features{EVALUE};
    delete $all_features{PERCENT_IDENTITY};
    delete $all_features{COMPLETE};
    delete $all_features{ONLINE};
    delete $all_features{SHOWDESC};
    delete $all_features{QSPEEDUP};
    delete $all_features{HXDROP};
    delete $all_features{EXDROP};
    $self->features(%all_features);
    return;
}

sub _is_tre_agrep {
    my ($self) = @_;
    my $command
        = $self->_cat_path_filename( $self->settings->execpath, 'agrep' )
        . ' -V';
    my $version_info = $self->_execute_command_and_return_output($command);
    if ( $version_info =~ m{TRE}xms ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_tre_agrep {
    my ($self) = @_;
    return $self->{_tre_agrep};
}

sub search {
    my ( $self, $arg_ref ) = @_;
    my $s = $self->settings;
    $self->_check_search_settings($arg_ref);

    $self->{_tre_agrep} = $self->_is_tre_agrep;
    if ( $self->is_tre_agrep ) {
        $self->{_line_regex} = qr{\A(\d+)\-(\d+):(\d+):(.*)\z}xmso;
    }
    else {
        $self->{_line_regex} = qr{\A(.*):(.*)\z}xmso;
    }

    my $query = $self->_prepare_query();
    $self->{_real_query} = $query;

    # now generate the command string
    my $mm = 0;
    if ( $s->mismatches_isset && $s->mismatches > 0 ) {
        $mm = $s->mismatches;
    }

    # make insertions and deletions too expensive
    my $fuzzy = "-$mm -D" . ( $mm + 1 ) . ' -I' . ( $mm + 1 );

    if ( $s->editdistance_isset ) {
        $fuzzy = q{-} . $s->editdistance;
    }

    my $show_position = q{};

    if ( $self->is_tre_agrep ) {
        $show_position = ' --show-position ';
    }

    my $command
        = $self->_cat_path_filename( $s->execpath, 'agrep' )
        . $show_position . ' -i '
        . $fuzzy . q{ }
        . $query . q{ }
        . $self->_cat_path_filename( $s->datapath, $s->database . '.dat' );

    if ( $ENV{BIOGREPDEBUG} ) {
        warn $command . "\n";
    }

    my $cmd_ok = $self->_execute_command($command);

    # delete temporary files
    #unlink($tmp_query_file) if !$query_file;

    if ( !$cmd_ok ) {
        $self->throw(
            -class => 'Bio::Root::SystemException',
            -text  => "Agrep call failed. Command was:\n\t$command"
        );
    }

    my $indexfile = $s->datapath . q{/} . $s->database . '.idx';
    $self->{'_idx'} = Bio::Index::Fasta->new($indexfile);

    $self->_load_mapping();
    $self->_prepare_results;
    return 1;
}

sub get_databases {
    my $self = shift;
    return $self->_get_databases('.map');
}

sub generate_database {
    my ( $self, @args ) = @_;

    my %args = $self->_prepare_generate_database(@args);

    if ( defined $args{skip} ) {
        return 0;
    }

    my $filename = $args{filename};

    open my $DATFILE, '>', "$filename.dat";
    open my $MAPFILE, '>', "$filename.map";
    my $in = Bio::SeqIO->new( -file => $filename, -format => $args{format} );
    my $id = 1;
    while ( my $seq = $in->next_seq() ) {
        print ${MAPFILE} $seq->id . "\n"
            or $self->_cannot_print("$filename.dat");
        print ${DATFILE} $id . q{:} . $seq->seq . "\n"
            or $self->_cannot_print("$filename.map");
        $id++;
    }
    close $DATFILE;
    close $MAPFILE;
    $self->_create_index_and_alphabet_file($filename);
    return 1;
}

sub _load_mapping {
    my ($self)  = @_;
    my $s       = $self->settings;
    my $mapfile = $s->datapath . q{/} . $s->database . '.map';

    my %mapping = ();

    open my $MAPFILE, '<', $mapfile;

    my $i = 1;
    while ( my $line = <$MAPFILE> ) {
        chomp $line;
        $mapping{ $i++ } = $line;
    }
    close $MAPFILE;

    $self->{_mapping} = \%mapping;
    return;
}

sub _parse_next_res {
    my $self  = shift;
    my $s     = $self->settings;
    my $query = $self->{_real_query};

    my $FH = $self->_output_fh;
LINE:
    while ( my $line = <$FH> ) {
        chomp $line;

        #warn $line;
        my ($sequence_id, $sequence,     $subject_begin, $subject_end,
            $subject_seq, $upstream_seq, $downstream_seq
        );
        my (@ret) = $line =~ $self->{_line_regex};

        if ( $self->is_tre_agrep ) {
            ( $subject_begin, $subject_end, $sequence_id, $sequence ) = @ret;
            my $pl = 1 + length $sequence_id;
            $subject_begin -= $pl;
            $subject_end   -= $pl;
        }
        else {
            ( $sequence_id, $sequence ) = @ret;
            $subject_begin = 0;
            if ( !defined $sequence ) {
                $self->warn(
                    "Truncated record. Record is:\n$line\n\nSkipping hit.");
                next LINE;
            }
            $subject_end = length $sequence;
            $subject_seq = $sequence;
        }
        my $id = $self->{_mapping}->{$sequence_id};

        my $seq_hit = $self->{_idx}->fetch($id);

        assert( defined $seq_hit, "Found $sequence_id:$id in Bio::Index" )
            if DEBUG;

        # take complete sequence as subject sequence for standard agrep
        $subject_seq = $seq_hit->seq;

        my $seq_query = Bio::LocatableSeq->new(
            -id    => $self->{_query_obj}->id,
            -desc  => $self->{_query_obj}->desc,
            -seq   => $self->{_query_obj}->seq,
            -start => 1,
            -end   => length $query,
        );

        my %begin_end;

        if ( $self->is_tre_agrep ) {

            # for TRE agrep, get regions
            ( $upstream_seq, $subject_seq, $downstream_seq )
                = $self->_parse_regions(
                {   complete_seq  => $subject_seq,
                    subject_begin => $subject_begin,
                    subject_end   => $subject_end,
                }
                );
            $seq_hit->seq( $upstream_seq . $subject_seq . $downstream_seq );
            %begin_end = (
                begin => length($upstream_seq),
                end   => length( $upstream_seq . $subject_seq ),
            );
        }

        my $seq_a = Bio::LocatableSeq->new(
            -id    => 'Subject',
            -seq   => $subject_seq,
            -start => $subject_begin + 1,    # starts at 1, not 0
            -end   => $subject_end,
        );

        my $alignment;

        if ( !$s->no_alignments ) {
            $alignment = $self->_get_alignment( $seq_a, $seq_query, );
        }

        my $res = Bio::Grep::SearchResult->new(
            {   sequence    => $seq_hit,
                alignment   => $alignment,
                sequence_id => $seq_hit->id,
                remark      => q{},
                query       => $self->{_query_obj},
                %begin_end,
            }
        );

        # agrep does not support multiple queries yet
        return $res;
    }
    $self->_delete_output();
    return 0;
}

sub get_sequences {
    my ( $self, $seqid ) = @_;
    return $self->_get_sequences_from_bio_index($seqid);
}

sub available_sort_modes {
    return ();
}
1;    # Magic true value required at end of module
__END__


=head1 NAME

Bio::Grep::Backend::Agrep - Agrep back-end  


=head1 SYNOPSIS

  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('Agrep');
  
  # generate a database. you have to do this only once. 
  $sbe->generate_database({ 
    file        => 'ATH1.cdna', 
    description => 'AGI Transcripts',
    datapath    => 'data',
  });
  
  # search for the reverse complement and allow 2 mismatches 
  # Don't calculate Alignments with EMBOSS
  $sbe->search({
    query   => 'GAGCCCTT',
    reverse_complement => 1, 
    mismatches         => 2,
    no_alignments      => 1,
    database           => 'ATH1.cdna',
  });
  
  my @internal_ids;
  
  # output the searchresults with nice alignments
  while ( my $res = $sbe->next_res) {
     print $res->sequence->id . "\n";
     # print $res->alignment_string() . "\n\n";
     push @internal_ids, $res->sequence_id;
  }
  
  # get the complete sequences as Bio::SeqIO object
  my $seq_io = $sbe->get_sequences(\@internal_ids);

=head1 DESCRIPTION

B<Bio::Grep::Backend::Agrep> searches for a query with agrep. 

=head1 METHODS

See L<Bio::Grep::Backend::BackendI> for inherited methods. 

=head2 CONSTRUCTOR

=over 

=item C<Bio::Grep::Backend::Agrep-E<gt>new()>

This method constructs an Agrep back-end object and should not used directly.  
Rather, a back-end should be constructed by the main class L<Bio::Grep>:

  my $sbe = Bio::Grep->new('Agrep');

=back

=head2 PACKAGE METHODS

=over

=item C<$sbe-E<gt>available_sort_modes()>

Returns all available sort modes as hash. keys are sort modes, values a short
description.

Available sort modes in Agrep:

=over

   currently none.
   
=back

=item C<$sbe-E<gt>is_tre_agrep()>

Returns 1 if C<agrep> binary is the one from the C<TRE> library, 0 otherwise.

=back

=head1 IMPORTANT NOTES

=over

=item Database

L<Bio::Grep::Backend::RE> databases are compatible with
L<Bio::Grep::Backend::Agrep> databases.

=back

=head1 DIAGNOSTICS

See L<Bio::Grep::Backend::BackendI> for other diagnostics. 

=over

=item C<Agrep call failed. Command was: ...> 

It was not possible to run agrep in function search(). Check the search
settings. C<Agrep> returns also exit(1) whenever no hit is found! If you want to
reproduce the system() call, you can set the environment variable
C<BIOGREPDEBUG>. If this variable is set, then the temporary files won't get
deleted.  C<Bio::Root::SystemException>.

=item C<Warning: Truncated record. Record is: ...>

Can occur with long sequences and the C<WuManber> or C<Glimpse> C<Agrep>
implementation. The limit of record length can be changed by modifying the parameter
Max_record in agrep.h.

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
