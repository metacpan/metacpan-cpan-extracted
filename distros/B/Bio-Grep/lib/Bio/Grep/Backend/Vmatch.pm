#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 19:54:03 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1848 $
#############################################################################

package Bio::Grep::Backend::Vmatch;

use strict;
use warnings;

use version; our $VERSION = qv('0.10.6');

use autodie qw(open close);
use English qw( -no_match_vars );

use Bio::Grep::SearchResult;
use Bio::Grep::Backend::BackendI;

use base 'Bio::Grep::Backend::BackendI';

use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use IO::String;
use Carp::Assert;

use Readonly;

# The VMATCH output columns
Readonly my $COL_LENGTH   => 0;
Readonly my $COL_ID       => 1;
Readonly my $COL_POS      => 2;
Readonly my $COL_STRAND   => 3;
Readonly my $COL_QUERY    => 5;
Readonly my $COL_EVALUE   => 8;
Readonly my $COL_IDENTITY => 10;

sub new {
    my $self = shift;
    $self = $self->SUPER::new;
    my %all_features = $self->features;
    delete $all_features{GUMISMATCHES};
    delete $all_features{DELETIONS};
    delete $all_features{INSERTIONS};
    delete $all_features{REVCOM_DEFAULT};
    $self->features(%all_features);
    return $self;
}

sub search {
    my ( $self, $arg_ref ) = @_;
    my $s = $self->settings;
    $self->_check_search_settings($arg_ref);

    my ( $query, $query_file, $tmp_query_file )
        = $self->_create_tmp_query_file();
    $self->_check_search_settings_vmatch($query_file);

    my $command = $self->_generate_vmatch_command( $query, $query_file,
        $tmp_query_file );
    if ( $ENV{BIOGREPDEBUG} ) {
        warn $command . "\n";
    }

    my $cmd_ok = $self->_execute_command($command);

    if ( !$cmd_ok ) {
        $self->throw(
            -class => 'Bio::Root::SystemException',
            -text  => "Vmatch call failed. Command was:\n\t$command"
        );
    }

    $self->_create_query_desc_lookup();

    $self->_prepare_results;
    return 1;
}

sub _generate_vmatch_command {
    my ( $self, $query, $query_file, $tmp_query_file ) = @_;
    my $s = $self->settings;

    my @params;

    my %flags = (
        'online'   => 'online',
        'complete' => 'complete',
    );

    for my $option ( keys %flags ) {
        my $option_isset = $option . '_isset';
        if ( $s->$option_isset && $s->$option ) {
            push @params, " -$flags{$option} ";
        }
    }

    my $auto_query_length = 0;
    if ( !defined $s->query_length && !$s->complete && !$query_file ) {
        $s->query_length( length $query );
        $auto_query_length = 1;
    }

    # dg sorting done by BackendI, not vmatch
    if ( $s->sort_isset && substr( $s->sort, 0, 1 ) ne 'g' ) {
        push @params, ' -sort ' . $s->sort;
    }

    if ( $s->qspeedup_isset ) {
        if ( $s->complete_isset ) {
            $self->throw(
                -class => 'Bio::Root::BadParameter',
                -text  => q{You can't combine qspeedup and complete.},
            );
        }

        push @params, ' -qspeedup ' . $s->qspeedup . q{ };
    }

    if ( $s->direct_and_rev_com ) {
        push @params, ' -p -d ';
    }
    elsif ( $s->query_file && $s->reverse_complement ) {
        push @params, ' -p ';
    }

    my %arguments = (
        'mismatches'   => q{h},
        'editdistance' => q{e},
        'query_length' => q{l},
        'maxhits'      => 'best',
        'showdesc'     => 'showdesc',
        'hxdrop'       => 'hxdrop',
        'exdrop'       => 'exdrop',
    );

    for my $option ( keys %arguments ) {
        my $option_isset = $option . '_isset';
        if ( $s->$option_isset && $s->$option ) {
            push @params, " -$arguments{$option} " . $s->$option;
        }
    }

    if ($auto_query_length) {
        $s->query_length_reset;
    }
    return
          $self->_cat_path_filename( $s->execpath, 'vmatch' ) . ' -q '
        . $tmp_query_file
        . join( q{ }, @params ) . ' -s '
        . $self->_cat_path_filename( $s->datapath, $s->database );
}

###########################################################################
# Usage      : _create_query_desc_lookup();
# Purpose    : create a lookup hash where the keys are query descriptions
#              like the ones the Vmatch output. The values are the
#              corresponding Bio::Seq objects
# Returns    : nothing
# Parameters : none

sub _create_query_desc_lookup {
    my ($self) = @_;
    if ( $self->settings->showdesc_isset ) {
        my %query_desc_lookup;
        foreach my $query_seq ( @{ $self->_query_seqs } ) {

            # simulate how this sequence would look in vmatch output
            my $query_desc = $query_seq->id;

            if ( $query_seq->desc && length($query_desc) > 0 ) {
                $query_desc .= q{ } . $query_seq->desc;
            }
            $query_desc = substr $query_desc, 0, $self->settings->showdesc;
            $query_desc =~ s/\s/_/gxms;
            $query_desc_lookup{$query_desc} = $query_seq;
        }
        $self->{_mapping} = \%query_desc_lookup;
    }
    return;
}

###########################################################################
# Usage      : _check_search_settings_vmatch()
# Purpose    : extends _check_search_settings() with some Vmatch specific
#              tests.
# Returns    : nothing
# Parameters : none
# Throws     : Bio::Root::BadParameter

sub _check_search_settings_vmatch {
    my ( $self, $query_file ) = @_;
    my $s = $self->settings;
    if ( ( $s->upstream > 0 || $s->downstream > 0 ) && $s->showdesc_isset ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text => q{You can't use showdesc() with upstream or downstream.},
        );
    }
    if ( $query_file && !$s->complete && !$s->query_length_isset ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'You have to specify complete or querylength. See '
                . 'the flags -complete and -l in the Vmatch documentation.',
        );
    }
    return 1;
}

sub get_databases {
    my $self = shift;
    return $self->_get_databases('.al1');
}

###########################################################################
# Usage      : generate_database()
# Purpose    : calling mkvtree to generate the suffix arrays
# Returns    : 1
# Parameters : hashref with mandatory argument 'file'. optional parameters
#              are format (not needed here), description, copy (instead of
#              symlink), datapath and the mkvtree parameters prefix_length
#              (-pl) and verbose (-v)
# Throws     : Bio::Root::BadParameter,
#              Bio::Root::SystemException

sub generate_database {
    my ( $self, @args ) = @_;
    my %args = $self->_prepare_generate_database(@args);

    if ( defined $args{skip} ) {
        return 0;
    }

    my $alphabet = $self->_guess_alphabet_of_file( $args{filename} );
    my $alphabet_specific_arguments = q{};

    my $verbose = q{};
    if ( defined $args{verbose} ) {
        $verbose = ' -v ';
    }

    my $pl = ' -pl ';
    if ( defined $args{prefix_length} ) {
        $pl .= $args{prefix_length} . q{ };
    }

    if ( $alphabet eq 'protein' ) {
        $alphabet_specific_arguments = ' -protein ';
    }
    elsif ( $alphabet eq 'dna' || $alphabet eq 'rna' ) {
        $alphabet_specific_arguments = ' -dna ';
    }
    else {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Unsupported alphabet of file.',
            -value => $alphabet,
        );
    }
    my $command
        = $self->_cat_path_filename( $self->settings->execpath, 'mkvtree' )
        . ' -db '
        . $args{basefilename}
        . $alphabet_specific_arguments
        . $pl
        . ' -allout '
        . $verbose;

    if ( $ENV{BIOGREPDEBUG} ) {
        warn $command . "\n";
    }
    my $output_dir = $self->settings->datapath;
    system qq{ cd $output_dir ; exec $command };
    if ($CHILD_ERROR) {
        $self->throw(
            -class => 'Bio::Root::SystemException',
            -text  => 'mkvtree call failed. Cannot generate suffix array. '
                . "Command was:\n\t$command",
        );
    }
    return 1;
}

###########################################################################
# Usage      : _parse_next_res()
# Purpose    : Assumes that the output filehandle points to the beginning of
#              a hit. This method then parses this hit.
# Returns    : SearchResult object or 0 (end of file)
# Parameters : none

sub _parse_next_res {
    my $self                = shift;
    my @query_seqs          = $self->_query_seqs;
    my $s                   = $self->settings;
    my @results             = ();
    my $alignment_in_output = 0;
    my $skip_next_alignment = 0;
    my $skipped_lines       = 0;
    my $subject;
    my $tmp_aln;

    my ( $command, $output );

    my $FH = $self->_output_fh;
LINE:
    while ( my $line = <$FH> ) {
        chomp $line;
        $line =~ s/\s+/ /gxms;
        if ( $line !~ /\s/xms ) {
            $skipped_lines++;
            next LINE if $skipped_lines != 2;

            # we are here? this means the parser is at the end of one hit
            # so store the alignment (we did not know the alignment when we
            # had to create the search result object)
            $results[-1]->alignment($tmp_aln);

            # without showdesc, we fetch the sequence with vsubseqselect
            # with, we need to extract the sequence out of the vmatch output
            # (the alignment)
            if ( $s->showdesc_isset ) {
                my $real_subject
                    = $results[-1]->alignment->get_seq_by_pos(1)->seq;

                # remove gaps out of alignment
                $real_subject =~ s{-}{}gxms;
                $results[-1]->sequence->seq($real_subject);
            }

            my $res = $self->_filter_result( $results[-1] );
            return $res if $res;
            $alignment_in_output = 0;
            next LINE;
        }

        $skipped_lines = 0;

        my @fields = split q{ }, $line;
        if ( $line =~ m{\A Sbjct: }xms && !$skip_next_alignment ) {
            $alignment_in_output = 1;
        }

        next
            if !(      $fields[$COL_LENGTH] =~ m{\A \d+ \z}xms
                    || $alignment_in_output
            );
        $skip_next_alignment = 0;

        if ( $line =~ m{\A Sbjct: \s (.*) \z}xms ) {
            $subject = $1;
        }
        if ( $line =~ m{\A Query: \s (.*) \z}xms ) {

            # updates or creates the alignment
            $self->_parser_create_alignment_obj(
                {   query     => $1,
                    subject   => $subject,
                    alignment => $tmp_aln,
                    results   => \@results
                }
            );

            next LINE;
        }
        next LINE if $alignment_in_output;

        $tmp_aln = Bio::SimpleAlign->new( -source => 'VMATCH' );

        $self->_parser_untaint_data( \@fields );

        my ( $fasta, $upstream )
            = $self->_parser_create_sequence_obj( \@fields );
        my $internal_seq_id = $fields[$COL_ID];
        if ( $s->showdesc_isset ) {
            $internal_seq_id = $fasta->id;
        }

        my $query;
        if ( $s->showdesc_isset ) {
            $query = $self->{_mapping}->{ $fields[$COL_QUERY] };
        }
        else {
            $query = $query_seqs[ $fields[$COL_QUERY] ];
        }

        my $rct = q{};
        my $rcs = $query->seq;
        if ( $s->direct_and_rev_com && $fields[$COL_STRAND] eq q{P} ) {
            $rct = ' (reverse complement)';
            $rcs = $query->revcom->seq;
        }
        my $result = Bio::Grep::SearchResult->new(
            {   sequence         => $fasta,
                begin            => $upstream,
                end              => $upstream + $fields[$COL_LENGTH],
                alignment        => Bio::SimpleAlign->new(),
                sequence_id      => $internal_seq_id,
                remark           => q{},
                evalue           => $fields[$COL_EVALUE],
                percent_identity => $fields[$COL_IDENTITY],
                query            => Bio::Seq->new(
                    -id   => $query->id,
                    -desc => $query->desc . $rct,
                    -seq  => $rcs,
                ),
            }
        );
        push @results, $result;
    }
    $self->_delete_output();
    return 0;
}

###########################################################################
# Usage      : _parser_create_sequence_obj()
# Purpose    : creates a Bio::Seq object for $res->sequence, returns true
#              upstream size (corrects upstream when available upstream
#              region too small)
# Returns    : Bio::Seq object and $upstream
# Parameters : ref to @fields array (containing the Vmatch output)

sub _parser_create_sequence_obj {
    my ( $self, $fields ) = @_;
    my $upstream = $self->settings->upstream;
    my $seq_obj;
    if ( !$self->settings->showdesc_isset ) {
        my $start = $fields->[$COL_POS] - $upstream;

        # maybe the defined upstream region is larger than available
        # so check this and store in local variables
        if ( $start < 0 ) {
            $upstream = $upstream + $start;
            $start    = 0;
        }

        my $length = $upstream + $fields->[$COL_LENGTH];
        $length += $self->settings->downstream;

        $seq_obj
            = $self->_get_subsequence( $length, $fields->[$COL_ID], $start );
    }
    else {
        my ( $seq_id, $seq_desc )
            = $fields->[$COL_ID] =~ m{\A (.+?) _ (.*) \z}xms;
        if ( !defined $seq_id ) {
            $seq_id = $fields->[$COL_ID];
        }
        $seq_desc =~ s{_}{ }gxms;
        $seq_obj = Bio::Seq->new( -id => $seq_id, -desc => $seq_desc );
    }
    return ( $seq_obj, $upstream );
}

sub _parser_create_alignment_obj {
    my ( $self, $args ) = @_;

    my ( $query_pos, $subject_pos );

    if ( $args->{query} =~ s{\s+ (\d+) \s* \z}{}xms ) {
        $query_pos = $1;
    }
    if ( $args->{subject} =~ s{\s + (\d+) \s* \z}{}xms ) {
        $subject_pos = $1;
    }
    assert( defined $query_pos )   if DEBUG;
    assert( defined $subject_pos ) if DEBUG;

    if ( !$args->{alignment}->no_sequences ) {
        $args->{alignment}->add_seq(
            Bio::LocatableSeq->new(
                -id    => 'Subject',
                -seq   => $args->{subject},
                -start => ( $subject_pos - length $args->{subject} ) + 1,
                -end   => $subject_pos
            )
        );
        $args->{alignment}->add_seq(
            Bio::LocatableSeq->new(
                -id    => $args->{results}->[-1]->query->id,
                -seq   => $args->{query},
                -start => ( $query_pos - length $args->{query} ) + 1,
                -end   => $query_pos
            )
        );
    }
    else {
        my $s1 = $args->{alignment}->get_seq_by_pos(1);
        my $s2 = $args->{alignment}->get_seq_by_pos(2);
        $s1->seq( $s1->seq . $args->{subject} );
        $s2->seq( $s2->seq . $args->{query} );
        $args->{alignment} = Bio::SimpleAlign->new( -source => 'VMATCH' );
        $args->{alignment}->add_seq($s1);
        $args->{alignment}->add_seq($s2);
        $s1->end($subject_pos);
        $s2->end($query_pos);
    }
    return;
}

sub _parser_untaint_data {
    my ( $self, $fields ) = @_;

    ( $fields->[$COL_LENGTH] ) = $fields->[$COL_LENGTH] =~ m{ (\d+) }xms;
    ( $fields->[$COL_POS] )    = $fields->[$COL_POS]    =~ m{ (\d+) }xms;
    ( $fields->[$COL_STRAND] ) = $fields->[$COL_STRAND] =~ m{ ([DP]) }xms;

    if ( $self->settings->showdesc_isset ) {

        # not numerical with showdesc on
        # don't worry about this unclean untainting, we don't use that
        # description in dangerous ways
        ( $fields->[$COL_ID] )    = $fields->[$COL_ID]    =~ m{ (.+) }xms;
        ( $fields->[$COL_QUERY] ) = $fields->[$COL_QUERY] =~ m{ (.+) }xms;
    }
    else {
        ( $fields->[$COL_ID] )    = $fields->[$COL_ID]    =~ m{ (\d+) }xms;
        ( $fields->[$COL_QUERY] ) = $fields->[$COL_QUERY] =~ m{ (\d+) }xms;
    }
    return;
}

sub _get_subsequence {
    my ( $self, $length, $id, $start ) = @_;
    my $command
        = $self->_cat_path_filename( $self->settings->execpath,
        'vsubseqselect' )
        . " -seq $length $id $start "
        . $self->_cat_path_filename( $self->settings->datapath,
        $self->settings->database );
    my $output = $self->_execute_command_and_return_output($command);

    if ( $ENV{BIOGREPDEBUG} ) {
        warn $command . "\n";
    }
    if ( $output =~ m{(\d+).*must\sbe\ssmaller\sthan\s (\d+)}xms ) {
        return $self->_get_subsequence( $length - ( $1 - $2 + 1 ), $id,
            $start );
    }
    my $stringio = IO::String->new($output);
    my $in       = Bio::SeqIO->new(
        '-fh'     => $stringio,
        '-format' => 'fasta'
    );
    return $in->next_seq();
}

sub get_sequences {
    my ( $self, $seqid ) = @_;
    my $s = $self->settings;
    $self->is_arrayref_of_size( $seqid, 1 );
    $self->_check_search_settings();
    my ( $tmp_fh, $tmpfile );

    my $seq_query = q{};

    if ( @{$seqid}[0] =~ m{\A \d+ \z}xms ) {
        ( $tmp_fh, $tmpfile )
            = tempfile( 'vseqselect_XXXXXXXXXXXXX', DIR => $s->tmppath );

        for my $sid ( @{$seqid} ) {
            print ${tmp_fh} $sid . " \n "
                or $self->_cannot_print($tmpfile);
        }
        close $tmp_fh;
        $seq_query = ' -seqnum ' . $tmpfile;
    }
    else {
        my $seq_desc = $self->is_sentence( @{$seqid}[0] );
        $seq_query = ' -matchdesc "' . $seq_desc . q{"};
    }

    my $command
        = $self->_cat_path_filename( $s->execpath, 'vseqselect' )
        . $seq_query . q{ }
        . $self->_cat_path_filename( $s->datapath, $s->database );

    if ( $ENV{BIOGREPDEBUG} ) {
        warn $command . "\n";
    }

    my $output = $self->_execute_command_and_return_output($command);
    if ( $CHILD_ERROR && $output !~ m{\A \> }xms ) {
        $self->throw(
            -class => 'Bio::Root::SystemException',
            -text  => 'vseqselect call failed. Cannot fetch sequences. '
                . "Command was:\n\t$command\n$output",
        );
    }
    my $stringio = IO::String->new($output);
    my $out      = Bio::SeqIO->new(
        '-fh'     => $stringio,
        '-format' => 'fasta'
    );
    return $out;
}

sub available_sort_modes {
    my ($self) = @_;
    return (
        $self->SUPER::available_sort_modes(),
        la  => 'ascending order of length',
        ld  => 'descending order of length',
        ia  => 'ascending order of first position',
        id  => 'descending order of first position',
        ja  => 'ascending order of second position',
        jd  => 'descending order of second position',
        ea  => 'ascending order of Evalue',
        ed  => 'descending order of Evalue',
        sa  => 'ascending order of score',
        sd  => 'descending order of score',
        ida => 'ascending order of identity',
        idd => 'descending order of identity'
    );
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::Grep::Backend::Vmatch - Vmatch back-end  

=head1 SYNOPSIS

  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('Vmatch');
  
  # generate a Vmatch suffix array. you have to do this only once.
  $sbe->generate_database({ 
    file          => 'ATH1.cdna', 
    description   => 'AGI Transcripts',
    datapath      => 'data',
    prefix_length => 3,
  });
 
  # search for the reverse complement and allow 4 mismatches
  # parse the description (max. 100 chars) directly out of the
  # Vmatch output instead of calling vsubseqselect for every
  # search result

  $sbe->search({
    query   => 'UGAACAGAAAGCUCAUGAGCC',
    reverse_complement => 1,
    mismatches         => 4,
    showdesc           => 100,
    database           => 'ATH1.cdna',
  });

  # output the searchresults with nice alignments
  while ( my $res = $sbe->next_res ) {
     print $res->sequence->id . "\n";
     print $res->mark_subject_uppercase() . "\n";
     print $res->alignment_string() . "\n\n";

     # sequence_id now contains the gene id (e.g. At1g1234),
     # not the Vmatch internal id 
     # To retrieve the complete sequences, one has to
     # call get_sequences for every gene id
     my $seq_io = $sbe->get_sequences([$res->sequence_id]);
     my $sequence = $seq_io->next_seq;
  }
  
  # for retrieving up- and downstream regions,
  # Vmatch internal sequence ids are required
  # (no showdesc possible)

  $sbe->search({
    query   => 'AGAGCCCT',
    reverse_complement => 1,
    mismatches         => 1,
    upstream           => 30,
    downstream         => 30,
  });
 
  my @internal_ids;
  while ( my $res = $sbe->next_res ) {
    # vsubseqselect is called now for every result ...
    push @internal_ids, $res->sequence_id;
  }

  # ... but one can retrieve all complete sequences with
  # just one call of vseqselect
  my $seq_io = $sbe->get_sequences(\@internal_ids);

  # search for multiple patterns 
  $sbe->search({
    query_file   => 'Oligos.fasta',
    mismatches   => 1,
    complete     => 1,
    showdesc     => 100,
  });
  
  while ( my $res = $sbe->next_res ) {
    print $res->query->id . " found in " . 
          $res->sequence->id . "\n";
  }

=head1 DESCRIPTION

B<Bio::Grep::Backend::Vmatch> searches for a query in a C<Vmatch> suffix array. 


=head1 METHODS

See L<Bio::Grep::Backend::BackendI> for inherited methods. 

=head2 CONSTRUCTOR

=over 

=item C<Bio::Grep::Backend::Vmatch-E<gt>new()>

This method constructs a C<Vmatch> back-end object and should not used 
directly. Rather, a back-end should be constructed by the main class 
L<Bio::Grep>:

  my $sbe = Bio::Grep->new('Vmatch');

=back

=head2 PACKAGE METHODS

=over

=item C<$sbe-E<gt>available_sort_modes()>

Returns all available sort modes as hash. keys are sort modes, values a short
description.

   $sbe->sort('ga');

Available sort modes in C<Vmatch>:

=over

            ga  : 'ascending order of dG'
            gd  : 'descending order of dG'
            la  : 'ascending order of length'
            ld  : 'descending order of length'
            ia  : 'ascending order of first position'
            id  : 'descending order of first position'
            ja  : 'ascending order of second position'
            jd  : 'descending order of second position'
            ea  : 'ascending order of Evalue'
            ed  : 'descending order of Evalue'
            sa  : 'ascending order of score'
            sd  : 'descending order of score'
            ida : 'ascending order of identity'
            idd : 'descending order of identity'


=back

Note that 'ga' and 'gd' require that search results have dG set. 
L<Bio::Grep::RNA> ships with filters for free energy calculation.  Also note 
that these two sort options require that we load all results in memory.

=item C<$sbe-E<gt>get_sequences()>

Takes as argument an array reference. If first array element is an integer, 
then this method assumes that the specified sequence ids are C<Vmatch> internal 
ids. Otherwise it will take the first array element as query.

    # get sequences 0,2 and 4 out of suffix array
    $sbe->get_sequences([0,2,4]);

    # get sequences that start with At1g1
    $sbe->get_sequences(['At1g1', 'ignored']);

The internal ids are stored in C<$res-E<gt>sequence_id>. If you have specified
C<showdesc>, then C<sequence_id> will contain the gene id (e.g. At1g1234),
NOT the C<Vmatch> internal id.

=back

=head1 IMPORTANT NOTES

=over

=item C<maxhits>

When C<maxhits> is defined, this back-end returns the I<maxhits> best
hits (those with smallest E-values).

=back

=head1 DIAGNOSTICS

See L<Bio::Grep::Backend::BackendI> for other diagnostics. 

=over

=item C<mkvtree call failed. Cannot generate suffix array. Command was: ...>. 

It was not possible to generate a suffix array in generate_database().
Check permissions and paths. C<Bio::Root::SystemException>.

=item C<Unsupported alphabet of file.>

The method generate_database() could not determine the
alphabet (DNA or Protein) of the specified Fasta file. C<Bio::Root::BadParameter>


=item C<Vmatch call failed. Command was: ... > 

It was not possible to run C<Vmatch> in function search(). Check the search
settings. When you get the C<Vmatch> error 

  vmatch: searchlength=x must be >= y=prefixlen
  
The number of mismatches is too high or the query is too short. You can
rebuild the index with generate_database() and a smaller C<prefix_length>
or you can try C<online>.

C<Bio::Root::SystemException>.

=item C<vseqselect call failed. Cannot fetch sequences. Command was: ...> 

It was not possible to get some sequences out of the suffix array in 
get_sequences(). Check sequence ids. C<Bio::Root::SystemException>.

=item C<You can't combine qspeedup and complete.>

The C<Vmatch> parameters C<-complete> and C<-qspeedup> cannot combined. See 
the C<Vmatch> documentation. C<Bio::Root::BadParameter>.

=item C<You can't use showdesc() with upstream or downstream.>

We need the tool C<vsubseqselect> of the C<Vmatch> package for the upstream and 
downstream regions. This tool requires as parameter an internal C<Vmatch>
sequence id, which is not shown in the C<Vmatch> output when C<showdesc> is on. 
C<Bio::Root::BadParameter>.

=item C<You have to specify complete or querylength. ...'>

The C<Vmatch> parameters C<-complete> and C<-l> cannot combined. See the
C<Vmatch> documentation. C<Bio::Root::BadParameter>.

=back

=head1 SEE ALSO

L<Bio::Grep::Backend::BackendI>
L<Bio::Grep::SearchSettings>
L<Bio::SeqIO>

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
