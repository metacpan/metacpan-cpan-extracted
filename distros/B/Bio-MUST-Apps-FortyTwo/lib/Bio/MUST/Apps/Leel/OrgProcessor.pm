package Bio::MUST::Apps::Leel::OrgProcessor;
# ABSTRACT: Internal class for leel tool
$Bio::MUST::Apps::Leel::OrgProcessor::VERSION = '0.190820';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use Carp;
use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:seqids);
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Ali::Temporary';
use aliased 'Bio::MUST::Core::IdMapper';

with 'Bio::MUST::Apps::Roles::OrgProcable';


has 'ali_proc' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::Leel::AliProcessor',
    required => 1,
);


has 'protein_seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali::Temporary',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_protein_seqs',
    handles  => [
        qw(abbr_id_for long_id_for)
    ],
);


has 'protein_seq_mapper' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdMapper',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_protein_seq_mapper',
    handles  => {
        accession_for => 'long_id_for',
    },
);


has $_ . '_seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_' . $_ . '_seqs',
) for qw(transcript aligned);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_protein_seqs {
    my $self = shift;

    ##### [ORG] Collecting proteins...

    my $ap = $self->ali_proc;

    my $org = $self->org;
    my $ali = $ap->ali;

    my @seqs = $ali->filter_seqs( sub { $_->full_org eq $org } );

    carp "Warning: no seq for org $org; skipping org!"
        unless @seqs;

    return Temporary->new( seqs => \@seqs );
}


sub _build_protein_seq_mapper {
    my $self = shift;

    my @protein_seq_ids = $self->protein_seqs->all_seq_ids;

    # abbr_ids are protein ids turned to query_ids for BLAST report (seq1 etc)
    my @abbr_ids = map {
        $self->abbr_id_for( $_->full_id )
    } @protein_seq_ids;

    # TODO: put regex in common with Mick's one-on-one in BMC

    # long_ids are bare accessions extracted from protein ids (Ahyp8251 etc)
    # these protein accessions will be matched against transcript accessions
    my @long_ids = map {
        $_->accession
            =~ s{ $TAIL_42 }{}xmsgr
    } @protein_seq_ids;

    return IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids,
    );
}


sub _build_transcript_seqs {
    my $self = shift;

    ##### [ORG] Searching for transcripts...

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    my $args = $rp->blast_args_for('transcripts') // {};
    $args->{-outfmt} = 5;
    $args->{-max_target_seqs} = 5
        unless defined $args->{-max_target_seqs};
    $args->{-db_gencode} = $self->code;

    my @seqs;
    for my $bank ($self->all_banks) {

        ###### [ORG] Processing BANK: $bank
        my $file = file( $rp->bank_dir, $bank );
        my $blastdb = Bio::MUST::Drivers::Blast::Database->new( file => $file );
        my $parser = $blastdb->tblastn($self->protein_seqs, $args);
        ###### [ORG] XML TBLASTN: $bank . q{ } . $parser->filename
        my $bo = $parser->blast_output;

        # collect transcript ids and ranges covered by proteins
        # tie might help making 1331 completely deterministic
        tie my %mask_for, 'Tie::IxHash';
        my %hit_for;

        PROTEIN:
        for my $protein ($bo->all_iterations) {

            # get protein accession
            my $protein_acc = $self->accession_for( $protein->query_def );

            TRANSCRIPT:
            for my $transcript ($protein->all_hits) {

                # get (corresponding?) transcript accession
                my @fields = split /\|/xms, $transcript->id;
                my $transcript_acc = pop @fields;

                # check that both accessions are identical
                my $rank = $transcript->num;
                unless ($protein_acc eq $transcript_acc) {
                    ####### [ORG] ids do not match: "$protein_acc vs. $transcript_acc (hit $rank)"

                    # optionally try next transcript if accessions are different
                    next TRANSCRIPT if $rp->id_match_mode eq 'enforce';
                }

                # mention success only in case of previous failure
                elsif ($rank > 1)  {
                    ####### [ORG] ids now do match: "$protein_acc (hit $rank)"
                }

                # collect protein id and mask for transcript
                $self->_collect_hsps(
                    protein    => $protein,         # Blast::Xml::Iteration
                    transcript => $transcript,      # Blast::Xml::Hit
                    mask_for   => \%mask_for,
                    hit_for    => \%hit_for,
                );

                # no need to examine remaining transcripts
                next PROTEIN;
            }
        }
        $parser->remove unless $rp->debug_mode;

        # fetch (and optionally trim) transcripts to their max range
        my @hits = $self->_fetch_and_trim_hits(
            blastdb  => $blastdb,
            mask_for => \%mask_for,
            hit_for  => \%hit_for,
        );
        ######## [DEBUG] transcripts: display( map { $_->seq } @hits )

        # add transcripts from current bank to seqs
        push @seqs, @hits
    }

    # check that all transcripts were indeed recovered
    my $missing_n = $self->protein_seqs->count_seqs - @seqs;
    carp "Warning: cannot find $missing_n transcript(s): skipping it (them)!"
        if $missing_n;

    return Ali->new( seqs => \@seqs );
}


sub _build_aligned_seqs {
    my $self = shift;

    ##### [ORG] Aligning transcripts...

    my $aligned_seqs = Ali->new();

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    TRANSCRIPT:
    for my $transcript_seq ( $self->transcript_seqs->all_seqs ) {
        my $protein_seq = $ap->protein_for( $transcript_seq->full_id );

        # align transcript on template protein and get its translation
        # Note: in exonerate the translated dna_seq is called 'target_seq'
        my $exo = Bio::MUST::Drivers::Exonerate::Aligned->new(
            dna_seq => $transcript_seq,
            pep_seq => $protein_seq->clone->degap,
            code    => $self->code,
        );

        # build new_seq from exonerate report
        my $new_seq = $exo->target_seq;
        unless ($new_seq->seq_len) {
            ### exonerate failure: 'discarded'
            next TRANSCRIPT;
        }

        # align cds_seq on protein_seq using new_seq and subject_seq as guides
        $aligned_seqs->add_seq(
            $ap->integrator->align(
                 new_seq => $new_seq,
                 subject => $exo->query_seq,
                template => $protein_seq,
                 cds_seq => $exo->spliced_seq,
                   start => $exo->query_start,
            )
        );
    }

    return $aligned_seqs;
}

## use critic


sub BUILD {
    my $self = shift;

    my $ap = $self->ali_proc;

    ##### [ORG] proteins: display( $self->protein_seqs->all_long_ids )
    return unless $self->protein_seqs->all_long_ids;

    ##### [ORG] transcripts: display( map { $_->full_id } $self->transcript_seqs->all_seq_ids  )
    return unless $self->transcript_seqs->all_seq_ids;

    ##### [ORG] aligned: display( map { $_->full_id } $self->aligned_seqs->all_seq_ids )
    return unless $self->aligned_seqs->all_seq_ids;

    ##### [ORG] Adding aligned seqs to file...
    $ap->cds_ali->add_seq( $self->aligned_seqs->all_seqs );

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Leel::OrgProcessor - Internal class for leel tool

=head1 VERSION

version 0.190820

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
