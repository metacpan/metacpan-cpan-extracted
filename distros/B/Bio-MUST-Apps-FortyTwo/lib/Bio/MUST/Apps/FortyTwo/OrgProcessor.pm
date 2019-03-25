package Bio::MUST::Apps::FortyTwo::OrgProcessor;
# ABSTRACT: Internal class for forty-two tool
$Bio::MUST::Apps::FortyTwo::OrgProcessor::VERSION = '0.190820';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use Carp;
use Const::Fast;
use List::AllUtils qw(each_array pairmap);
use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:gaps :ncbi);
use Bio::MUST::Core::Utils qw(:filenames);
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Ali::Temporary';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::SeqMask';
use aliased 'Bio::MUST::Apps::Debrief42::TaxReport::NewSeq';

with 'Bio::MUST::Apps::Roles::OrgProcable';


has 'ali_proc' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::FortyTwo::AliProcessor',
    required => 1,
);


has 'tax_filter' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Str]]',
);


has '_tax_filter' => (
    is       => 'ro',
    isa      => 'Maybe[Bio::MUST::Core::Taxonomy::Filter]',
    init_arg => undef,
    writer   => '_set_tax_filter',
    handles  => [ qw(is_allowed) ],
);


has $_ . '_seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali::Temporary',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_' . $_ . '_seqs',
) for qw(homologous orthologous);


has 'aligned_seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_aligned_seqs',
);


has '_para_scores' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Num]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_para_scores',
    handles  => {
        para_score_for => 'get',
    },
);


has '_count_for' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Num]]',
    init_arg => undef,
    default  => sub { {} },
);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_homologous_seqs {
    my $self = shift;

    ##### [ORG] Searching for homologues...

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    my $args = $rp->blast_args_for('homologues') // {};
    $args->{-outfmt} = 6;
    $args->{-max_target_seqs} = 10000
        unless defined $args->{-max_target_seqs};

    my @seqs;
    for my $bank ($self->all_banks) {

        ###### [ORG] Processing BANK: $bank
        my $query_seqs = $ap->query_seqs;
        my $file = file( $rp->bank_dir, $bank );
        my $blastdb = Bio::MUST::Drivers::Blast::Database->new( file => $file );
        $args->{-db_gencode} = $self->code          # if TBLASTN
            if $query_seqs->type eq 'prot' && $blastdb->type eq 'nucl';
        my $parser = $blastdb->blast($query_seqs, $args);
        ###### [ORG] TBLASTN (or BLASTP/N): $bank . q{ } . $parser->filename

        # tie might help making 42 completely deterministic
        tie my %mask_for, 'Tie::IxHash';
        my %strand_for;

        # collect hit ids, masks and strands covered by queries
        $self->_collect_hsps(
            parser     => $parser,
            mask_for   => \%mask_for,
            strand_for => \%strand_for,
        );
        $parser->remove unless $rp->debug_mode;

        # fetch (and optionally trim) hits to their max range
        my @hits = $self->_fetch_and_trim_hits(
            blastdb    => $blastdb,
            mask_for   => \%mask_for,
            strand_for => \%strand_for,
        );
        ######## [DEBUG] hits: display( map { $_->full_id . ' => ' . $_->seq } @hits )

        # add seqs from current bank to homologous seqs
        push @seqs, @hits;
    }

    # build BLAST query file from homologous seqs
    return Temporary->new( seqs => \@seqs );
}


sub _build_orthologous_seqs {
    my $self = shift;

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    if ($rp->ref_brh_mode eq 'off') {
        ##### [ORG] Skipping orthology assessment!
        return $self->homologous_seqs;
    }

    ##### [ORG] Identifying orthologues among homologues...

    my $args = $rp->blast_args_for('orthologues') // {};
    $args->{-outfmt} = 6;
    $args->{-max_target_seqs} = 1;

    # tie might help making 42 completely deterministic
    tie my %count_for, 'Tie::IxHash';
    for my $ref_org ($ap->all_ref_orgs) {

        my $homologous_seqs = $self->homologous_seqs;
        my $blastdb = $rp->ref_blastdb_for($ref_org);
        $args->{-query_gencode} = $self->code       # if BLASTX
            if $homologous_seqs->type eq 'nucl' && $blastdb->type eq 'prot';
        my $parser = $blastdb->blast($homologous_seqs, $args);
        ##### [ORG] BLASTX (or BLASTP/N): $ref_org . q{ } . $parser->filename

        my $best_hits = $ap->best_hits_for($ref_org);
        while (my $hsp = $parser->next_query) {
            my $candidate = $homologous_seqs->long_id_for( $hsp->query_id );
            my $in_best_hits = $best_hits->is_listed(      $hsp->hit_id   );
            ######## [DEBUG]: $candidate . ( $in_best_hits && ' [=BRH=]' )
            $count_for{$candidate}++ if $in_best_hits;
        }
        $parser->remove unless $rp->debug_mode;
    }

    ######## [DEBUG] BRH counts: display( pairmap { "$a => $b" } %count_for )

    # keep only homologues that are orthologous for all effective ref_orgs
    my $ref_org_n = $ap->count_ref_orgs;
    my $orthologues = IdList->new(
        ids => [ grep { $count_for{$_} == $ref_org_n } keys %count_for ]
    );
    my $seqs = $orthologues->filtered_ali( $self->homologous_seqs );

    # build BLAST query file from orthologous seqs
    return Temporary->new( seqs => $seqs );
}


sub _build_para_scores {
    my $self = shift;

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    # ignore if no .para file in use
    my $blastdb = $ap->para_blastdb;
    return unless $blastdb;

    my $args = $rp->blast_args_for('templates') // {};
    $args->{-outfmt} = 6;
    $args->{-max_target_seqs} = 1;

    my $orthologous_seqs = $self->orthologous_seqs;
    $args->{-query_gencode} = $self->code           # if BLASTX
        if $orthologous_seqs->type eq 'nucl' && $blastdb->type eq 'prot';
    my $parser = $blastdb->blast($orthologous_seqs, $args);
    ##### [ORG] BLASTX (or BLASTP/N): 'PARA ' . $parser->filename

    my %para_score_for;
    while (my $hsp = $parser->next_query) {
        my $candidate = $orthologous_seqs->long_id_for( $hsp->query_id );
        my $hit = $blastdb->long_id_for( $hsp->hit_id );
        my $score = $hsp->bit_score;
        ######## [DEBUG] candidate: $candidate
        ######## [DEBUG] hit: $hit
        ######## [DEBUG] score: $score
        $para_score_for{$candidate} = $score;
    }
    $parser->remove unless $rp->debug_mode;

    return \%para_score_for;
}


sub _build_aligned_seqs {               ## no critic (ProhibitExcessComplexity)
    my $self = shift;

    ##### [ORG] Aligning orthologues...

    my $aligned_seqs = Ali->new();

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    my $args = $rp->blast_args_for('templates') // {};
    $args->{-outfmt} = 5;
    $args->{-max_target_seqs} = $rp->tax_max_hits * 2;

    my $orthologous_seqs = $self->orthologous_seqs;
    my $blastdb = $ap->blastdb;
    $args->{-query_gencode} = $self->code           # if BLASTX
        if $orthologous_seqs->type eq 'nucl' && $blastdb->type eq 'prot';
    my $parser = $blastdb->blast($orthologous_seqs, $args);
    ##### [ORG] XML BLASTX (or BLASTP/N): $parser->filename

    # abort if no hit
    my $bo = $parser->blast_output;
    return Ali->new() unless $bo;

    ORTHOLOGUE:
    for my $orthologue ($bo->all_iterations) {
        unless ($orthologue->count_hits) {
            ###### [ORG] skipped orthologue due to lack of significant template
            next ORTHOLOGUE;
        }   # TODO: investigate why this should happen at all...

        # fetch tax_line from orthologue
        # Note: .para check is also done in this sub (hence the next below)
        my $tax_line = $self->_fetch_tax_line_for_transcript($orthologue);
        next ORTHOLOGUE unless $tax_line;

        # extract contam_org and transcript_id from tax_line...
        my $contam_org = $tax_line->contam_org;
        my $transcript_id = $tax_line->seq_id . '%s';   # chunk placeholder
           $transcript_id .= "...$contam_org" if $contam_org;
           $transcript_id .= '#NEW#';

        # ... and use it "as is" to store tax_line in tax_report (no chunk tag)
        my $tax_line_id = sprintf $transcript_id, q{};
        $ap->set_tax_line( $tax_line_id => $tax_line );

        # extract transcript_seq from tax_line
        my $transcript_seq = Seq->new(
            seq_id => $tax_line_id,     # same id without alignment
            seq    => $tax_line->seq
        );

        # skip both orthologue alignment and integration if metagenomic mode
        next ORTHOLOGUE if $rp->run_mode eq 'metagenomic';

        # optionally add transcript_seq as is (without alignment)
        if ($rp->aligner_mode eq 'off') {

            ####### [ORG] Adding: $transcript_seq->full_id

            $aligned_seqs->add_seq($transcript_seq);
            next ORTHOLOGUE;
        }

        # build a template_seq list as long as query coverage improves
        # exonerate will try to use the longest template for alignment
        # while BLAST will use each hit in turn (possibly as a fall-back)
        my @templates;
        my @template_seqs;
        my $best_coverage = 0;

        TEMPLATE:
        for my $template ($orthologue->all_hits) {

            # fetch template full_id
            my $template_id = SeqId->new(
                full_id => $blastdb->long_id_for($template->def)
            );

            # optionally skip template if from same org as the orthologue
            if ($rp->ali_patch_mode eq 'on') {
                if ($template_id->full_org eq $transcript_seq->full_org) {
                    ###### [ORG] skipped same-org template due to patch_mode
                    next TEMPLATE;
                }
            }

            # compute query coverage by template HSPs
            my $mask = SeqMask->empty_mask( $orthologue->query_len );
            $mask->mark_block($_->query_start, $_->query_end)
                for $template->all_hsps;
            my $coverage = $mask->coverage;

            last TEMPLATE if $coverage
                < $best_coverage * $rp->ali_cover_mul;
            $best_coverage = $coverage;

            ######## [DEBUG] template: $template_id->full_id
            ######## [DEBUG] coverage: sprintf '%.2f', $coverage

            # fetch and cache aligned template seq from Ali
            # Note: we emulate a fast get_seq_with_id using Ali lookup
            push @templates, $template;
            push @template_seqs, $ap->ali->get_seq(
                $ap->lookup->index_for( $template_id->full_id )
            );
        }

        # Note: as we (optionally) skip templates, we may run out of templates
        unless (@templates) {
            ###### [ORG] skipped orthologue due to lack of suitable template
            next ORTHOLOGUE;
        }

        # flag tracking exonerate failure (for exoblast mode)
        my $failure;

        if ($rp->aligner_mode =~ m/exonerate|exoblast/xms) {

            # use longest template for exonerate alignment
            my $template_seq = $template_seqs[-1];

            # align transcript on template protein and get its translation
            # Note: in exonerate the translated dna_seq is called 'target_seq'
            my $exo = Bio::MUST::Drivers::Exonerate::Aligned->new(
                dna_seq => $transcript_seq,
                pep_seq => $template_seq->clone->degap,
                code    => $self->code,
            );

            # get new_seq from exonerate report
            # build new_id from transcript_id and exonerate model used
            my $new_id = sprintf $transcript_id, '.E.' . $exo->model;
            my $new_seq = $exo->target_seq;
               $new_seq->set_seq_id($new_id);

            ####### [ORG] Adding: $new_seq->full_id

            unless ($new_seq->seq_len) {
                my $fate = $rp->aligner_mode eq 'exoblast'
                    ? 'will retry with BLAST' : 'discarded'
                ;
                ####### [ORG] exonerate failure: $fate
                $failure = 1;
            }

            else {
                # align new_seq on template_seq using subject_seq as a guide
                $aligned_seqs->add_seq(
                    $ap->integrator->align(
                         new_seq => $new_seq,
                         subject => $exo->query_seq,
                        template => $template_seq,
                           start => $exo->query_start,
                    )
                );

                ######## [DEBUG] aligned with exonerate model: $exo->model
            }
        }

        if ( ($rp->aligner_mode eq 'blast')
          || ($rp->aligner_mode eq 'exoblast' && $failure) ) {

            TEMPLATE:
            for my $template (@templates) {

                # use each template in turn for BLAST alignment
                my $template_seq = shift @template_seqs;
                last TEMPLATE unless $template_seq;

                HSP:
                for my $hsp ($template->all_hsps) {

                    # build HSP id from transcript_id and template/HSP ranks
                    my $hsp_id = sprintf $transcript_id,
                        '.H' . $template->num . '.' . $hsp->num;

                    # build HSP seq from BLASTX report
                   (my $hsp_seq = $hsp->qseq) =~ s{\*}{$FRAMESHIFT}xmsg;
                    my $new_seq = Seq->new(
                        seq_id => $hsp_id,
                        seq    => $hsp_seq
                    );

                    # fetch aligned template seq from HSP (= subject)
                    my $subject_seq = Seq->new(
                        seq_id => $template_seq->seq_id,
                        seq    => $hsp->hseq
                    );

                    # reverse complement seqs if template on reverse in BLASTN
                    if ($ap->query_seqs->type eq 'nucl'
                                && $blastdb->type eq 'nucl'
                                && $hsp->hit_strand == -1) {
                            $new_seq =     $new_seq->reverse_complemented_seq;
                        $subject_seq = $subject_seq->reverse_complemented_seq;
                    }

                    ####### [ORG] Adding: $new_seq->full_id

                    # align new_seq on template_seq using subject_seq as a guide
                    $aligned_seqs->add_seq(
                        $ap->integrator->align(
                             new_seq => $new_seq,
                             subject => $subject_seq,
                            template => $template_seq,
                               start => $hsp->hit_start,
                        )
                    );

                    ######## [DEBUG] aligned with BLAST
                }
            }
        }
    }

    $parser->remove unless $rp->debug_mode;

    return $aligned_seqs;
}

## use critic


sub _fetch_tax_line_for_transcript {
    my $self       = shift;
    my $orthologue = shift;

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    # fetch transcript accession (= query id) from BLAST report
    my $query_def = $orthologue->query_def;
    my $transcript_acc = $self->orthologous_seqs->long_id_for($query_def);

    # extract range and strand (if any) from transcript accession
    # Note: this mostly makes sense for genomic contigs/scaffolds
    my @fields = split /:::/xms, $transcript_acc;
    my ($strip_acc, $start, $end, $strand) = @fields;

    # set acc to transcript accession
    my ($first_chunk) = $strip_acc =~ m/^(\S+)/xms;
    my @parts = split /\|/xms, $first_chunk;
    my $acc = pop @parts;
    ###### [ORG] orthologous transcript: $acc

    # check again for paralogy if .para file in use
    if ($ap->para_blastdb) {
        my $para_score = $self->para_score_for($transcript_acc);
        my $temp_score = $orthologue->get_hit(0)->get_hsp(0)->bit_score;
        if ($para_score > $temp_score) {
            ###### [ORG] rejected for PARA[logy]: "$para_score > $temp_score"
            return;
        }
    }

    # prebuild SeqId list for all templates
    # this is needed for family affiliation (first only)
    #        ... and for assessing template taxonomy (all)
    my $blastdb = $self->ali_proc->blastdb;
    my @templates = $orthologue->all_hits;
    my @template_ids = map {
        SeqId->new( full_id => $blastdb->long_id_for( $_->def ) )
    } @templates;

    # set family to first template family (if any)
    my $family = $template_ids[0]->family // q{};
    $family .= '-' if $family;

    # set org to current (bank) org
    my $org = $self->org;
    my $contam_org = q{};

    # setup tax_report data
    my $common_tax;
    my $lca;
    my $lineage;
    my $tag = q{};
    my $top_score = 0;
    my $rel_n = 0;
    my $mean_len;
    my $mean_ident;

    # optionally analyze template taxonomy
    # ... to build tax_reports of additions
    # ... to tag potential contaminations
    if ( $rp->tax_reports eq 'on' || $self->_tax_filter ) {
        my @relatives;
        my $best_score = 0;
        my $sum_len    = 0;
        my $sum_ident  = 0;

        my $tax = $rp->tax;
        my $ea = each_array @templates, @template_ids;

        # accumulate relatives for LCA inference
        # Note: three logical modes can be distinguished.
        # These should be implemented in the config file.
        # 1. best-hit
        # - tax_max_hits: 1
        # - filter on tax_min_score or tax_min_len / tax_min_ident
        # 2. classic LCA
        # - tax_max_hits: to be specified
        # - filter on tax_min_score or tax_min_len / tax_min_ident
        # 3. MEGAN-like LCA
        # - tax_max_hits: should be ignored
        # - filter on tax_min_score / tax_score_mul
        # however all criteria can be simultaneously activated

        REL:
        while ( my ($template, $template_id) = $ea->() ) {

            # accumulate at most tax_max_hits relatives for LCA inference
            last REL if @relatives >= $rp->tax_max_hits;

            # ensure that match to template is good enough...
            # by default all these thresholds are disabled
            my $hsp = $template->get_hsp(0);

            # ... MEGAN-like mode (and top_score needed for one-on-one)
            my $score = $hsp->bit_score;
            $top_score = List::AllUtils::max($top_score, $score);
            # Note: we do not use last due to non-monotonic score decrease

            # no need to accumulate relatives if no NCBI Taxonomy is available
            last REL unless $tax;

            next REL if $score < $rp->tax_min_score;
            next REL if $score < $rp->tax_score_mul * $best_score;

            # ... classic or best-hit mode
            my $len   = $hsp->align_len;
            next REL if $len   < $rp->tax_min_len;
            my $ident = $hsp->identity / $len;
            next REL if $ident < $rp->tax_min_ident;

            # try to determine taxonomy of template
            # if possible add template to list of relatives...
            # ... and set best_score for MEGAN-like mode
            my @taxonomy = $tax->fetch_lineage($template_id);
            if (@taxonomy) {
                # Note: contrary to ref_score_mul the best_score never changes
                $best_score ||= $score;
                $sum_len   += $len;
                $sum_ident += $ident;
                push @relatives, \@taxonomy;
                ######## [DEBUG] hit: $template_id->full_id
                ######## [DEBUG] length: $len
                ######## [DEBUG] identity: sprintf '%.2f', $ident
                ######## [DEBUG] lineage: join '; ', @taxonomy
            }
        }

        ######## [DEBUG] relatives: display( map { join '; ', @$_ } @relatives )

        if (@relatives < $rp->tax_min_hits) {
            ###### [ORG] tagged as unclassified due to lack of relatives
            $common_tax = [ 'unclassified sequences' ];
            if ($self->_tax_filter) {
                $tag = 'u#';
            }
        }

        else {
            # infer LCA from all relatives...
            $common_tax = $tax->compute_lca(@relatives);
            $lineage = join '; ', @{$common_tax};
            ######## [DEBUG] LCA lineage: $lineage
            $lca = $common_tax->[-1];
            ###### [ORG] affiliated to: $lca

            if ($rp->tax_reports eq 'on') {
                $rel_n = @relatives;
                $mean_len   = sprintf '%.2f', $sum_len   / $rel_n;
                $mean_ident = sprintf '%.2f', $sum_ident / $rel_n;
            }

            # optionally tag potential contamination based on LCA
            # Note: LCAs are used "as is" because is_allowed handles them
            if ($self->_tax_filter) {
                ######## [DEBUG] pass tax_filter: $self->is_allowed($common_tax)
                unless ( $self->is_allowed($common_tax) ) {
                    ###### [ORG] tagged as contaminated
                    $tag = 'c#';
                    $contam_org = join '_',
                        map { $_ // () } SeqId->parse_ncbi_name($lca);
                }       # delete undef species/strains
            }
        }
    }

    # check for multiple orthologues derived from the same transcript
    # Note: this mostly makes sense for genomic contigs/scaffolds
    my $acc_u = $acc;
    my $count = ++$self->_count_for->{$org}{$acc};
    if ($count > 1) {                       # direct access to private attr
        carp "Note: more than one orthologue extracted from $acc; "
            . "appending .$count to accession.";
        $acc_u .= ".$count";
    }

    # fetch orthologous transcript and give it nearly complete full_id
    my $transcript_seq
        = $self->orthologous_seqs->get_seq_with_id($transcript_acc)->seq;
    my $transcript_id
        = $org =~ $PKEYONLY || $org =~ $GCAONLY ? $org . '|' . $acc_u
                               : $family . $tag . $org . '@' . $acc_u
    ;

    # build tax_report line for transcript
    my $tax_line = NewSeq->new(
        seq_id     => $transcript_id,
        contam_org => $contam_org,
        top_score  => $top_score,
        rel_n      => $rel_n,
        mean_len   => $mean_len,
        mean_ident => $mean_ident,
        lca        => $lca,
        lineage    => $lineage,
        acc        => $acc,
        start      => $start,
        end        => $end,
        strand     => $strand,
        seq        => $transcript_seq,
    );

    return $tax_line;
}


sub BUILD {
    my $self = shift;

    my $ap = $self->ali_proc;
    my $rp = $ap->run_proc;

    # optionally build _tax_filter from tax_filter (specs) and tax attrs
    # Note: cannot use builder/coercion because of the need for a tax object
    if ($self->tax_filter) {
        my $tax = $rp->tax;
        $self->_set_tax_filter( $tax->tax_filter( $self->tax_filter ) )
            if $tax;        # warning already issued at this stage
    }

    ##### [ORG] homologues: display( $self->homologous_seqs->all_long_ids )
    return unless $self->homologous_seqs->all_long_ids;

    ##### [ORG] orthologues: display( $self->orthologous_seqs->all_long_ids )
    return unless $self->orthologous_seqs->all_long_ids;

    ##### [ORG] aligned: display( map { $_->full_id } $self->aligned_seqs->all_seq_ids )
    return unless $self->aligned_seqs->all_seq_ids;

    ##### [ORG] Adding aligned seqs to file...
    $ap->ali->add_seq( $self->aligned_seqs->all_seqs );

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::FortyTwo::OrgProcessor - Internal class for forty-two tool

=head1 VERSION

version 0.190820

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
