package Bio::MUST::Apps::HmmCleaner::Process;
# ABSTRACT: Process class for HmmCleaner
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>
$Bio::MUST::Apps::HmmCleaner::Process::VERSION = '0.243280';
use Moose;
use namespace::autoclean;

use Carp;
use Smart::Comments -ENV;
use Modern::Perl;

use Bio::MUST::Core 0.180230;
use Bio::MUST::Core::Constants qw(:gaps :files);
use Bio::FastParsers::Hmmer;
use aliased 'Bio::MUST::Core::Seq';

####### [PROCESS] Value of env verbosity : scalar(split ' ', $ENV{Smart_Comments})

# ATTRIBUTES
has 'ali' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Core::Ali',
    required    => 1,
);

has 'seq' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Core::Seq',
    required    => 1,
);

has 'model' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Drivers::Hmmer::Model::Temporary',
    required    => 1,
);

has 'nogap_seq' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Core::Seq',
    lazy        => 1,
    builder     => '_build_nogap_seq',
);

has 'parser' => (
    is          => 'ro',
    isa         => 'Bio::FastParsers::Hmmer::Standard',
    lazy        => 1,
    builder     => '_build_parser',
);

has 'score' => (
    is          => 'ro',
    isa         => 'Str',
    lazy        => 1,
    builder     => '_build_scoreseq',
);

has 'consider_X' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 1,
);

has 'debug_mode' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
);

# BUILDER

## no critic (ProhibitUnusedPrivateSubroutines)

# do the hmmsearch and recover the standard parser for current process
sub _build_parser {
    my $self = shift;

    my $hmmer = $self->model;

    # we work without gap
    # Hmmsearch output file and parser

    my $target = Bio::MUST::Core::Ali::Temporary->new(
            seqs => [$self->nogap_seq],
            args => {
                degap       => 0,
                gapify      => 0,
                clean       => 0,
                persistent  => ($self->debug_mode) ? 1 : 0,
            },
    );
    my $parser = $hmmer->search( $target, { '--notextw' => undef, }); # removed domE 10e-3
    #~ my $parser = $hmmer->search( [$self->nogap_seq], { '--notextw' => undef, '--domE' => 10e-3} );

    return $parser;
}

sub _build_nogap_seq {
    my $self = shift;
    my $seq = $self->seq;
    my $nogap_seq = ($self->consider_X) ? $seq->clone->gapify('X')->degap : $seq->clone->gapify->degap;
    ###### [PROCESS] nogap seq : $nogap_seq->seq
    return $nogap_seq;
}

sub _build_scoreseq {
    my $self = shift;

    my $target = $self->parser->next_iteration->next_target;

    my $seqfullid = $self->seq->full_id;
    my $seqlength = $self->nogap_seq->seq_len;

    my $concat_scoreseq;
    if ( defined $target ) {
        ### [PROCESS] Actual target name : $target->name
        my @domains_info = $target->all_domains;
        #### [PROCESS] Nb of domains : scalar(@domains_info)

        # check for ovelapping domains
        for(my $i=0; $i<@domains_info; $i++){
            for(my $j=$i+1; $j<@domains_info; $j++){
                my $o = _overlap( $domains_info[$i]->hmm_start, $domains_info[$i]->hmm_end, $domains_info[$j]->hmm_start, $domains_info[$j]->hmm_end );
                if ($o > 10) {
                    carp "WARNING : Repetition of length $o detected in ".$seqfullid."\tdomains: ".$domains_info[$i]->hmm_start.' -> '.$domains_info[$i]->hmm_end.' and '.$domains_info[$j]->hmm_start.' -> '.$domains_info[$j]->hmm_end." \n";
                    ## TODO: Check what is going on if we have a domain inside a previous one
                }
            }
        }

        ### Concatening all domains on 1 line...
        $concat_scoreseq = ( @domains_info == 0 ) ? '' : " " x ($domains_info[0]->ali_start - 1);
        # Condition if no domain found

        if ( @domains_info > 0) {
            for (my $i=0; $i<@domains_info; $i++) {
                ###### [PROCESS] currentscore length   : length($concat_scoreseq)
                ###### [PROCESS] length of next domain : length($domains_info[$i]->scoreseq)
                ###### [PROCESS] domain ali start      : $domains_info[$i]->ali_start
                ###### [PROCESS] Seq       : $domains_info[$i]->seq
                ###### [PROCESS] Score seq : $domains_info[$i]->scoreseq
                ###### [PROCESS] degap seq : $domains_info[$i]->get_degap_scoreseq

                # substr of score to remove beginning that could correspond to overlap
                my $add = substr( $domains_info[$i]->get_degap_scoreseq, ( length($concat_scoreseq) - $domains_info[$i]->ali_start + 1 ) );
                ###### [PROCESS] Added score : $add
                $concat_scoreseq .= $add;
                # If current domain is not the last one
                if($i+1 != @domains_info){
                    # if this domain does not overlap with the next one
                    if ( $domains_info[$i]->ali_end < $domains_info[$i+1]->ali_start ) {
                        # extend score with blank so that score length is ok to add next domain
                        $concat_scoreseq .= " " x ( $domains_info[$i+1]->ali_start - $domains_info[$i]->ali_end - 1);
                    }
                }
                ###### [PROCESS] current $i concat_scoreseq: $concat_scoreseq
            }
        } else {
            carp 'WARNING : No domains found for '.$seqfullid.' in '.$self->ali->file."\n";
            # TODO <-> Remove this futur empty seq
        }

        $concat_scoreseq .= " " x ($seqlength - length($concat_scoreseq));
        #### [PROCESS] Final concatenated scoreseq : $concat_scoreseq
    } else {
        ### No target...
        carp 'WARNING : No domains found for '.$seqfullid.' in '.$self->ali->file."\n";
        # TODO <-> Remove this futur empty seq
        $concat_scoreseq .= " " x ($seqlength);
    }

    return $concat_scoreseq;
}

## use critic

# Given two segment a-b and c-d, give the common part size
# assume a<b and c<d
# This sub is coming from the original script
sub _overlap {
    my ($a, $b, $c, $d) = @_;
    my $ret = 0;
    if( ($c <= $b) and ($b <= $d) ){
        $ret = $b-$c;
    }
    if( ($c <= $a) and ($a <= $d) ){
        if($ret == 0){
            $ret = $d-$a;
        }
        else{
            $ret-=$a-$c;
        }
    }
    if( ($a < $c) and ($d < $b) ){
        $ret = $d-$c;
    }
    return $ret;
}

sub DEMOLISH {
    my $self = shift;

    $self->parser->remove unless ($self->debug_mode);

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::HmmCleaner::Process - Process class for HmmCleaner

=head1 VERSION

version 0.243280

=head1 AUTHOR

Arnaud Di Franco <arnaud.difranco@gmail.fr>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arnaud Di Franco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
