package Bio::MUST::Apps::FortyTwo::AliProcessor;
# ABSTRACT: Internal class for forty-two tool
$Bio::MUST::Apps::FortyTwo::AliProcessor::VERSION = '0.202160';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use Carp;
use Const::Fast;
use List::AllUtils qw(first part partition_by pairmap);
use POSIX;
use Sort::Naturally;
use Tie::IxHash;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:filenames secure_outfile);
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Ali::Temporary';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Apps::SlaveAligner::Local';
use aliased 'Bio::MUST::Apps::FortyTwo::OrgProcessor';
use aliased 'Bio::MUST::Apps::Debrief42::TaxReport::NewSeq';

with 'Bio::MUST::Apps::Roles::AliProcable';


has 'run_proc' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::FortyTwo::RunProcessor',
    required => 1,
);


has '+ali' => (
    handles  => [ qw(all_new_seqs all_but_new_seqs) ],
);


has 'lookup' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_lookup',
);


has 'blastdb' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Drivers::Blast::Database::Temporary',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_blastdb',
);


has 'para_blastdb' => (
    is       => 'ro',
    isa      => 'Maybe[Bio::MUST::Drivers::Blast::Database::Temporary]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_para_blastdb',
);


has 'tax_report' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Apps::Debrief42::TaxReport::NewSeq]',
    init_arg => undef,
    default  => sub { {} },
    handles  => {
            tax_line_for => 'get',
        set_tax_line     => 'set',
        all_tax_line_ids => 'keys',
    },
);


has '_' . $_ . '_seqs_by_org' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Bio::MUST::Core::Seq]]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_' . $_ . '_seqs_by_org',
    handles  => {
        'count_' . $_ . '_orgs' => 'count',
          'all_' . $_ . '_orgs' => 'keys',
               $_ . '_seqs_for' => 'get',
    },
) for qw(ali non new);


has 'query_seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali::Temporary',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_query_seqs',
);


has '_best_hits_by_ref_org' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Core::IdList]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_best_hits_by_ref_org',
    handles  => {
      count_ref_orgs      => 'count',
        all_ref_orgs      => 'keys',
     remove_ref_org       => 'delete',
        all_best_hits     => 'values',
            best_hits_for => 'get',
    },
);


has '_seqs_for_removal' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    init_arg => undef,
    default  => sub { IdList->new() },
    handles => {
          marked_for_removal => 'is_listed',
        mark_seq_for_removal => 'add_id',
             all_marked_seqs => 'all_ids',
          remove_marked_seqs => 'negative_list',
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_integrator {
    return Local->new( ali => shift->ali );
}


sub _build_lookup {
    return shift->ali->new_lookup;
}


sub _build_blastdb {
    return Bio::MUST::Drivers::Blast::Database::Temporary->new(
        seqs => [ shift->all_but_new_seqs ]
    );
}


sub _build_para_blastdb {
    my $self = shift;

    my $parafile = change_suffix($self->ali->filename, '.para');
    return unless -e $parafile;

    #### [ALI] PARA file in use: $parafile
    return Bio::MUST::Drivers::Blast::Database::Temporary->new(
        seqs => $parafile
    );
}


sub _build_new_seqs_by_org {
    my $self = shift;
    return $self->_split_seqs_by_org(
        Ali->new( seqs => [ $self->all_new_seqs     ] )
    );
}


sub _build_ali_seqs_by_org {
    my $self = shift;
    return $self->_split_seqs_by_org(
        Ali->new( seqs => [ $self->all_but_new_seqs ] )
    );
}


sub _build_non_seqs_by_org {
    my $self = shift;

    my $nonfile = change_suffix( $self->ali->filename, '.non' );
    return {} unless -e $nonfile;

    #### [ALI] NON file in use: $nonfile
    return $self->_split_seqs_by_org( Ali->load($nonfile) );
}


const my $DEF_ORG => ':default';

sub _split_seqs_by_org {
    my $self = shift;
    my $seqs = shift;               # actually an Ali object...

    # split Seqs into one or more ArrayRefs keyed by full_org
    # tie probably useless here but ensuring reproducible logs
    tie my %seqs_for, 'Tie::IxHash';
    for my $seq ($seqs->all_seqs) {
        my $genus = $seq->genus     // q{};
        my $org   = $seq->full_org  // $DEF_ORG;
        push @{ $seqs_for{$org} }, $seq;
    }

    return \%seqs_for;
}


sub _build_query_seqs {
    my $self = shift;

    #### [ALI] Collecting queries...

    my $rp = $self->run_proc;

    my @seqs    # filter out doubtful seqs from each query_org
        = grep { not $_->is_doubtful }
           map { @{ $self->ali_seqs_for($_) // [] } }
        $rp->all_query_orgs
    ;

    unless (@seqs) {
        carp '[ALI] Warning: no seq for any query_org; using longest instead!';
        @seqs = ( $self->get_longest_query_seq );
    }

    return Temporary->new( seqs => \@seqs );
}


sub _build_best_hits_by_ref_org {
    my $self = shift;

    #### [ALI] Identifying best hits for queries in reference orgs...

    my $rp = $self->run_proc;
    my $args = $rp->blast_args_for('references') // {};
    $args->{-outfmt} = 6;
    $args->{-max_target_seqs} = 10
        unless defined $args->{-max_target_seqs};

    # tie might help making 42 completely deterministic
    tie my %best_hits_for, 'Tie::IxHash';
    tie my %avg_score_for, 'Tie::IxHash';

    ORG:
    for my $ref_org ($rp->all_ref_orgs) {

        my $query_seqs = $self->query_seqs;
        my $blastdb = $rp->ref_blastdb_for($ref_org);
        my $parser = $blastdb->blastp($query_seqs, $args);
        #### [ALI] BLASTP: $ref_org . q{ } . $parser->filename

        # collect best hit(s) for each query against ref proteome
        my $curr_query = q{};
        my $seen_qry_n = 0;
        my $seen_hit_n = 0;
        my $best_score = 0;
        my $cmul_score = 0;

        # tie might help making 42 completely deterministic
        tie my %hits, 'Tie::IxHash';
        while ( my $hsp = $parser->next_hit ) {

            # fetch query and bitscore for current hit
            my $query = $hsp->query_id;
            my $score = $hsp->bit_score;

            # reset score if next query
            if ($query ne $curr_query) {
                $seen_qry_n++;
                $curr_query = $query;
                $best_score = 0;
            }

            # include hit if within score tolerance
            # Note: for consistency with coverage_mul the new lower score
            # becomes the new 'best_score' (increasing tolerance thus)
            if ($score >= $best_score * $rp->ref_score_mul) {
                my $hit = $hsp->hit_id;
                ######## [DEBUG] query: $query_seqs->long_id_for($query)
                ######## [DEBUG] hit: $hit
                ######## [DEBUG] score: $score
                $hits{$hit}++;
                $seen_hit_n++;
                $best_score  = $score;
                $cmul_score += $score;
            }
        }

        $parser->remove unless $rp->debug_mode;

        # skip ref_orgs without best hits
        unless ($cmul_score) {
            carp "[ALI] Note: no best hit for: $ref_org;"
                . ' removing it from ref_orgs.';
            next ORG;
        }

        # store average score for best hits in current ref proteome
        # Note: divisor is set to number of best hits (plus unseen queries)
        my $divisor = $seen_hit_n + $query_seqs->count_seqs - $seen_qry_n;
        my $avg_score = $cmul_score / $divisor;
        $avg_score_for{$ref_org} = $avg_score;

        # store best hit list for current ref proteome
        my $best_hits = IdList->new( ids => [ keys %hits ] );
        $best_hits_for{$ref_org} = $best_hits;
    }
    ######## [DEBUG] avg scores: display( pairmap { "$a => $b" } %avg_score_for )

    my $ref_org_n = ceil( $rp->ref_org_mul * $rp->all_ref_orgs );
    my @ref_orgs = keys %avg_score_for;
    if (@ref_orgs > $ref_org_n) {

        #### [ALI] Discarding non-best ref_orgs and keeping only: $ref_org_n
        @ref_orgs = sort {
            $avg_score_for{$b} <=> $avg_score_for{$a}
        } @ref_orgs;
        @ref_orgs = @ref_orgs[ 0 .. $ref_org_n - 1 ];

        %best_hits_for = map { $_ => $best_hits_for{$_} } @ref_orgs;
    }

    return \%best_hits_for;
}

## use critic


sub get_longest_query_seq {
    my $self = shift;

    my $max_seq;
    my $max_len = 0;

    # loop through potential queries and select longest seq
    for my $org ($self->all_ali_orgs) {

        SEQ:
        for my $seq ( @{ $self->ali_seqs_for($org) } ) {

            # filter out doubtful seqs from each query_org
            next SEQ if $seq->is_doubtful;

            # find longest seq using a manual yet fast approach
            my $len = $seq->nomiss_seq_len;
            if ($len > $max_len) {
                $max_seq = $seq;
                $max_len = $len;
            }
        }
    }

    return $max_seq;
}


sub check_brh_among_best_hits {
    my $self = shift;

    #### [ALI] Checking BRH among best hits in reference orgs...
    if ($self->count_ref_orgs < 2) {
        carp '[ALI] Warning: not enough ref_orgs for checking BRH'
            . ' among best hits!';
        return;
    }

    my $rp = $self->run_proc;
    my $args = $rp->blast_args_for('references') // {};
    $args->{-outfmt} = 6;
    $args->{-max_target_seqs} = 1;

    for my $ref_org1 ($self->all_ref_orgs) {

        # build query_seqs from best hits for current ref_org
        my $query_seqs = Temporary->new(
            seqs => $rp->ref_blastdb_for($ref_org1)->blastdbcmd(
                [ $self->best_hits_for($ref_org1)->all_ids ]
            )->seqs     # TODO: improve this through coercion
        );

        tie my %count_for, 'Tie::IxHash';

        ORG2:
        for my $ref_org2 ($self->all_ref_orgs) {
            next ORG2 if $ref_org2 eq $ref_org1;

            my $blastdb = $rp->ref_blastdb_for($ref_org2);
            my $parser = $blastdb->blastp($query_seqs, $args);
            #### [ALI] BLASTP: "$ref_org1 vs $ref_org2 " . $parser->filename

            my $best_hits = $self->best_hits_for($ref_org2);
            while ( my $hsp = $parser->next_query ) {
                my $candidate = $query_seqs->long_id_for( $hsp->query_id );
                my $in_best_hits = $best_hits->is_listed( $hsp->hit_id   );
                ######## [DEBUG]: $candidate . ( $in_best_hits && ' [=BRH=]' )
                $count_for{$candidate}++ if $in_best_hits;
            }
            $parser->remove unless $rp->debug_mode;
        }

        ######## [DEBUG] BRH counts: display( pairmap { "$a => $b" } %count_for )

        # remove ref_orgs that completely failed BRH
        # Note: this should not happen too often because of ref_org_mul
        unless (keys %count_for) {
            carp "[ALI] Note: failed BRH for: $ref_org1;"
                . ' removing it from ref_orgs.';
            $self->remove_ref_org($ref_org1);
            # Note: the remaining ref_orgs (as 1) will not be tested vs. this
            # ref_org (as 2) from now on; thus early Warnings only due to this
            # ref_org (as 2) could have been avoided
        }

        # check BRH with all *other* ref_orgs (hence - 1)
        my $other_n = $self->all_ref_orgs - 1;
        carp '[ALI] Warning: best hits not in BRH across all ref_orgs!'
            unless List::AllUtils::all {
                $count_for{$_} == $other_n
            } keys %count_for
        ;
    }

    return;
}


sub merge_chunks {
    my $self = shift;

    # fetch all new seqs having a 42 tail
    # those are the aligned orthologous transcripts
    my $tail_regex = qr{ (:? \.H\d+\.\d+ | \.E\.bf | \.E\.lc ) \b }xms;
    my @new_seqs = grep { $_->full_id =~ $tail_regex } $self->all_new_seqs;

    # leave early if no new seqs
    return unless @new_seqs;

    # partition transcripts by full_id ignoring 42 tails
    my %new_seqs_by_acc = partition_by {
        ( my $full_id = $_->full_id ) =~ s{$tail_regex}{}; $full_id
    } @new_seqs;

    # separate single-chunk transcripts from multi-chunk transcripts
    my ($singles, $multiples) = part {
        @{ $new_seqs_by_acc{$_} } > 1
    } sort keys %new_seqs_by_acc;
    ####### [ALI] multi-chunk transcripts: display( @{$multiples} )

    # simply remove 42 tails from single-chunk transcripts
    # Note: ->[0] is required because values are singleton ARRAYREFs
    $new_seqs_by_acc{$_}->[0]->set_seq_id( SeqId->new( full_id => $_ ) )
        for @{ $singles // [] };

    # leave early if no multi-chunk transcripts
    return unless @{ $multiples // [] };

    # get alignment width and regex
    my $width = $self->ali->width;
    my $gap_regex = $self->ali->gapmiss_regex;

    # merge chunks for each transcript
    for my $merged_id ( @{$multiples} ) {

        # order transcript chunks following BLAST hit and HSP ranks
        # this will ensure that best-scoring hits/HSPs come first
        my @chunks = sort {
            ncmp( $a->full_id, $b->full_id )
        } @{ $new_seqs_by_acc{$merged_id} };

        my $merged_seq;
        my $gap = q{ };

        # take each state from first chunk where it is not missing/gap
        # insert '*' if no chunk can provide it
        # Note: we insert a blank at first site to trigger Seq->spacify
        for my $site (0..$width-1) {
            my $chunk = first {  $_->state_at($site) !~ $gap_regex } @chunks;
            $merged_seq .= $chunk ? $chunk->state_at($site) : $gap;
            $gap = '*';
        }

        # add merged_seq
        $self->ali->add_seq(
            Seq->new(
                seq_id => $merged_id,
                seq    => $merged_seq
            )
        );

        # mark chunks for removal
        $self->mark_seq_for_removal( map { $_->full_id } @chunks );
    }

    return;
}


sub mark_redundant_seqs {
    my $self = shift;

    # fetch all new seqs not yet marked for removal
    my @new_seqs = grep {
        !$self->marked_for_removal( $_->full_id )
    } $self->all_new_seqs;

    # examine each new_seq for redundancy etc
    for my $seq (@new_seqs) {

        my $id  = $seq->full_id;
        my $org = $seq->full_org;

        # remove seq if included in Ali for the org...
        if (   List::AllUtils::any { $seq->is_subseq_of($_) }
                @{ $self->ali_seqs_for($org) // [] } ) {
            ####### [ALI] removed for redundancy within ALI: $id
            $self->mark_seq_for_removal($id);
        }
        # ... or included in .non file for the org...
        elsif (List::AllUtils::any { $seq->is_subseq_of($_) }
                @{ $self->non_seqs_for($org) // [] } ) {
            ####### [ALI] removed for inclusion in NON file: $id
            $self->mark_seq_for_removal($id);
        }
        # ... or included in new_seqs for the org
        # but not seq itself and not if already marked for removal
        # to avoid both auto and mutual removal of identical new_seqs
        elsif (List::AllUtils::any { $seq->is_subseq_of($_) }
                grep {                      $id ne $_->full_id
                    && !$self->marked_for_removal( $_->full_id ) }
                @{ $self->new_seqs_for($org) // [] } ) {
            ####### [ALI] removed for redundancy with other #NEW# seqs: $id
            $self->mark_seq_for_removal($id);
        }   # Note: it is important that marked_seqs... is constantly updated
    }

    return;
}


sub mark_lengthened_seqs {
    my $self = shift;

    # fetch all new seqs not yet marked for removal
    my @new_seqs = grep {
        !$self->marked_for_removal( $_->full_id )
    } $self->all_new_seqs;

    # examine each new_seq for lengthening
    for my $seq (@new_seqs) {
        my $org = $seq->full_org;

        # identify pre-existing seqs included in a new_seq...
        my @redundants = map { $_->full_id }    # opposite to above...
             grep {                             $_->is_subseq_of($seq) }
             grep { !$self->marked_for_removal( $_->full_id )          }
            @{ $self->ali_seqs_for($org) // [] }
        ;   # Note: it is important that marked_seqs... is constantly updated

        # ... and remove them
        # Note: not sure that more than one per new_seq would be very common
        if (@redundants) {
            ####### [ALI] removed for redundancy by lengthening: join ', ', @redundants
            $self->mark_seq_for_removal(@redundants);
        }
    }

    return;
}


sub reorder_new_seqs {
    my $self = shift;

    my $ali = $self->ali;

    # partition Ali between old and new_seqs
    my ($old_seqs, $new_seqs) = part { $_->is_new } $ali->all_seqs;

    # reorder new_seqs naturally on family/full_org/accession
    # Note: this should ignore the c# tag during sorting
    $ali->_set_seqs( [ @{ $old_seqs // [] }, sort {
        ncmp( $a->family_then_full_org, $b->family_then_full_org )
            ||
        ncmp( $a->accession,            $b->accession            )
    }                  @{ $new_seqs // [] } ] );

    return;
}


sub BUILD {
    my $self = shift;

    my $rp = $self->run_proc;

    my $ali = $self->ali;
    #### [ALI] #seqs: $ali->count_seqs

    unless ( $ali->count_seqs ) {
        #### [ALI] empty file; skipping!
        return;
    }

    # default to clearing new tags from Ali
    $ali->clear_new_tags
        unless $rp->ali_keep_old_new_tags eq 'on';

    # check for optional use of .non and .para
    # Note: lazy builders do not require it but this makes a better log
    $self->count_non_orgs;
    $self->para_blastdb;

    #### [ALI] queries: display( $self->query_seqs->all_long_ids )

    if ($rp->ref_brh eq 'on') {

        #### [ALI] reference orgs: display( $self->all_ref_orgs )

        #### [ALI] best hits: display( map { $_->all_ids } $self->all_best_hits )

        $self->check_brh_among_best_hits;
    }

    for my $org ($rp->all_orgs) {

        #### [ALI] Processing ORG: $org->{org}
        OrgProcessor->new( ali_proc => $self, %{$org} );
    }

    my $filename = $ali->filename;
    my $suffix = $rp->out_suffix;

    unless ( $rp->run_mode eq 'metagenomic' ) {

        #### [ALI] Making delayed indels...
        $self->integrator->make_indels;

        #### [ALI] Merging sequence chunks...
        $self->merge_chunks;

        #### [ALI] Removing redundant (and unwanted) seqs...
        $self->mark_redundant_seqs;

        # TODO: write tests for this
        if ($rp->ali_keep_lengthened_seqs eq 'off') {
            #### [ALI] Removing lengthened seqs...
            $self->mark_lengthened_seqs;
        }

        #### [ALI] merged/redundant/unwanted/lengthened: display( $self->all_marked_seqs )
        $ali->apply_list( $self->remove_marked_seqs($ali) );

        #### [ALI] Re-ordering remaining aligned seqs...
        $self->reorder_new_seqs;

        #### [ALI] Writing updated file...
        my $outfile = secure_outfile($filename, $suffix);
        $ali->store($outfile);
    }

    if ($rp->tax_reports eq 'on') {
        # TODO: consider moving this in TaxReport-like class

        #### [ALI] Writing taxonomic report...
        my $tax_report = secure_outfile(
            change_suffix($filename, '.tax-report'), $suffix
        );

        open my $fh, '>', $tax_report;
        say {$fh} '# ' . join "\t", NewSeq->heads;

        # print tax_lines for all new_seqs
        my @new_seqs = $rp->run_mode eq 'phylogenomic'
            ? map { $_->full_id } $self->all_new_seqs       # phylogenomic mode
            :              nsort( $self->all_tax_line_ids ) #  metagenomic mode
        ;
        say {$fh} join "\n", map { $_->stringify }
            map { $self->tax_line_for($_) // () } @new_seqs;
    }   # Note: skip preexisting new_seqs for which there are no tax_lines

    #### [ALI] Done analyzing file...
    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::FortyTwo::AliProcessor - Internal class for forty-two tool

=head1 VERSION

version 0.202160

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
