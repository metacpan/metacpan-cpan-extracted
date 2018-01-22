package Bio::MUST::Apps::TwoScalp::Seq2Seq;
# ABSTRACT: internal class for two-scalp tool
$Bio::MUST::Apps::TwoScalp::Seq2Seq::VERSION = '0.180160';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use List::AllUtils qw(part);

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:gaps);
use Bio::MUST::Core::Utils qw(secure_outfile);

use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::SeqMask';
use aliased 'Bio::MUST::Drivers::Blast::Database::Temporary';
use aliased 'Bio::MUST::Drivers::Blast::Query';
use aliased 'Bio::MUST::Apps::SlaveAligner::Local';


has 'coverage_mul' => (
    is       => 'ro',
    isa      => 'Num',
    default  => 1.1,
);


has 'single_hsp' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);


has 'out_suffix' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    default  => '-ts',
);


has 'ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
);


has 'lookup' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    init_arg => undef,
    writer   => '_set_lookup',
);


has 'new_ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_new_ali',
);


has 'integrator' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::SlaveAligner::Local',
    init_arg => undef,
    writer   => '_set_integrator',
);


has 'blastdb' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Drivers::Blast::Database::Temporary',
    init_arg => undef,
    writer   => '_set_blastdb',
);


has 'query_seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Drivers::Blast::Query',
    init_arg => undef,
    writer   => '_set_query_seqs',
);


sub _align_seqs {
    my $self = shift;

    my $args->{-outfmt} = 5;
       $args->{-max_target_seqs} = 5;

    my $blastdb = $self->blastdb;
    my $query_seqs = $self->query_seqs;
    my $parser = $query_seqs->blast($blastdb, $args);
    #### [S2S] XML BLASTP/N: $parser->filename

    my $bo = $parser->blast_output;
    return unless $bo;

    my $sort_method = $self->single_hsp ? 'score' : 'hit_start';

    QUERY:
    for my $query ( $bo->all_iterations ) {

        my $query_id = $query_seqs->long_id_for( $query->query_def );
        ##### [S2S] Aligning: $query_id

        my @templates;
        my @template_seqs;
        my $best_coverage = 0;

        TEMPLATE:
        for my $template ( $query->all_hits ) {

            # compute query coverage by template HSPs
            my $mask = SeqMask->empty_mask( $query->query_len );
            $mask->mark_block( $_->query_start, $_->query_end )
                for $template->all_hsps;
            my $coverage = $mask->coverage;

            last TEMPLATE if $coverage
                < $best_coverage * $self->coverage_mul;
            $best_coverage = $coverage;

            # fetch template full_id
            my $template_id = SeqId->new(
                full_id => $blastdb->long_id_for( $template->def )
            );

            ###### [S2S] template: $template_id->full_id
            ###### [S2S] coverage: $coverage

            # fetch and cache aligned template seq from Ali
            push @templates, $template;
            push @template_seqs, $self->ali->get_seq(
                $self->lookup->index_for( $template_id->full_id )
            );
        }

        unless (@templates) {
            ##### [S2S] skipped alignment due to lack of suitable template
            next QUERY;
        }

        @templates = ( $templates[-1] ) if $self->single_hsp;

        TEMPLATE:
        for my $template (@templates) {

            # use each template in turn for BLAST alignment
            my $template_seq = shift @template_seqs;
            last TEMPLATE unless $template_seq;

            # sort HSPs by descending start coordinate on template or by
            # descending score depending on --single-hsp option
            my @hsps = sort {
                $b->$sort_method <=> $a->$sort_method
            } $template->all_hsps;

            HSP:
            for my $hsp (@hsps) {

                # build HSP id from query id (and template/HSP ranks)
                my $hsp_id = $query_seqs->long_id_for( $query->query_def );
                $hsp_id .= '.H' . $template->num . '.' . $hsp->num
                    unless $self->single_hsp;
                $hsp_id .= '#NEW#';

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
                if ($query_seqs->type eq 'nucl' && $blastdb->type eq 'nucl'
                    && $hsp->hit_strand == -1) {
                        $new_seq =     $new_seq->reverse_complemented_seq;
                    $subject_seq = $subject_seq->reverse_complemented_seq;
                }

                # align new_seq on template_seq using subject_seq as a guide
                $self->new_ali->add_seq(
                    $self->integrator->align(
                         new_seq => $new_seq,
                         subject => $subject_seq,
                        template => $template_seq,
                           start => $hsp->hit_start,
                    )
                );

                last HSP if $self->single_hsp;
            }
        }
    }

    return;
}


sub display {                               ## no critic (RequireArgUnpacking)
    return join "\n--- ", q{}, @_
}


sub BUILD {
    my $self = shift;

    my $ali = $self->ali;
    #### [ALI] #seqs: $ali->count_seqs
    unless ($ali->count_seqs) {
        #### [ALI] empty file; skipping!
        return;
    }

    # Note: this class maintains DRY through a single BUILD
    # hence the writers instead of the usual builders

    $self->_set_lookup( $ali->new_lookup );

    # TODO: fix bug with 'aligned' seqs only composed of trailing spaces
    my ($unaligned_seqs, $aligned_seqs)
        = part { $_->is_aligned ? 1 : 0 } $ali->all_seqs;
    #### [S2S] seqs to align: display( map { $_->full_id } @{$unaligned_seqs} )

    $self->_set_blastdb( Temporary->new( seqs =>   $aligned_seqs ) );
    $self->_set_query_seqs(  Query->new( seqs => $unaligned_seqs ) );

    my $new_ali = Ali->new( seqs => $aligned_seqs );
    $self->_set_new_ali($new_ali);

    my $integrator = Local->new( ali => $new_ali );
    $self->_set_integrator($integrator);

    $self->_align_seqs;

    #### [S2S] Making delayed indels...
    $integrator->make_indels;

    #### [S2S] Writing updated file...
    my $outfile = secure_outfile($ali->filename, $self->out_suffix);
    $new_ali->store($outfile);

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::TwoScalp::Seq2Seq - internal class for two-scalp tool

=head1 VERSION

version 0.180160

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
