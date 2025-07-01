package Bio::MUST::Core::SeqMask::Profiles;
# ABSTRACT: Evolutionary profiles for sequence sites
$Bio::MUST::Core::SeqMask::Profiles::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use Const::Fast;
use Tie::IxHash;

extends 'Bio::MUST::Core::SeqMask';

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::SeqMask::Freqs';


# override superclass' Bool type
# Note: mask indices are as follow: [site]{full_id}{AA}
#       mask values  are AA freqs (both per seq and averaged over seqs)
has '+mask' => (
    isa => 'ArrayRef[HashRef[HashRef[Num]]]',
);

# TODO: mask non-applicable methods from superclass? (Liskov principle)
# TODO: move this under PostPred instead of SeqMask?

const my $AVERAGE => '<:AVERAGE:>';
const my $PREC => 3;


sub ppred_profiles {
    my $class = shift;
    my $alis  = shift;
    my $args  = shift // {};            # HashRef (should not be empty...)

    my $list = $args->{sim_list};

    my @sim_freq_at_for;

    my $regex;
    my $width;
    my $seq_inc;
    my $avg_inc;

    # loop through Ali objects to build site profiles
    # Note: profiles will be available both per seq and averaged over seqs
    for my $ali ( @{$alis} ) {

        # extract seqs on which to compute freqs (defaults to all seqs)
        my $sample = $list ? $list->filtered_ali($ali) : $ali;
        my @seqs = $sample->all_seqs;

        # setup mask details based on first Ali
        unless ($regex) {
            $regex = $ali->gapmiss_regex;
            $width = $ali->width;
            $seq_inc = 1.0 / @{$alis};
            $avg_inc = $seq_inc / @seqs;
        }

        # loop through simulated seqs to store and average ppred state freqs
        for my $seq (@seqs) {
            my $full_id = $seq->full_id;

            # store and average ppred state freq at each site for current seq
            # Note: all missing/gap states are folded to '*'
            for my $site (0..$width-1) {
                my $sim_state = uc $seq->state_at($site);
                   $sim_state = '*' if $sim_state =~ m/$regex/xms;
                $sim_freq_at_for[$site]{$full_id}{$sim_state} += $seq_inc;
                $sim_freq_at_for[$site]{$AVERAGE}{$sim_state} += $avg_inc;
            }
        }
    }

    return $class->new( mask => \@sim_freq_at_for );
}



sub ppred_freqs {
    my $self = shift;
    my $ali  = shift;
    my $args = shift // {};             # HashRef (should not be empty...)

    my $by_seq = $args->{by_seq} // 0;
    my $list   = $args->{obs_list};

    # ppred_freqs_by_seq
    # input: f_AA(site,seq)
    # output: f_AAobs(site,seq)
    # => mask f_AAobs_avg(site) over seq
    # => seq sort f_AAobs_avg(seq) over sites

    # ppred_freqs
    # input: f_AA_avg(site) over seq
    # output: f_AAobs(site,seq)
    # => mask f_AAobs_avg(site) over seq
    # => seq sort f_AAobs_avg(seq) over sites

    tie my %obs_freq_for_at, 'Tie::IxHash';

    # extract seqs on which to compute freqs (defaults to all seqs)
    my $sample = $list ? $list->filtered_ali($ali) : $ali;
    my @seqs = $sample->all_seqs;

    # setup mask details
    my $regex = $ali->gapmiss_regex;
    my $width = $ali->width;

    # loop through real seqs to store observed state freqs
    # Note: ppred state freqs are either by seq or averaged over seqs
    for my $seq (@seqs) {
        my $full_id = $seq->full_id;
        my $seq_key = $by_seq ? $full_id : $AVERAGE;

        # store observed state freq at each site for current seq
        # Note: sites with missing/gap state get a max freq of 1.0
        for my $site (0..$width-1) {
            my $sim_freq_for = ${ $self->state_at($site) }{$seq_key};
            my $obs_state = uc $seq->state_at($site);
            my $obs_freq = $obs_state =~ m/$regex/xms ? 1.0
                : $sim_freq_for->{$obs_state} // 0.0;
            $obs_freq_for_at{$full_id}[$site] = $obs_freq;
        }
    }

    return Freqs->new( freq_for_at => \%obs_freq_for_at );
}



sub store {
    my $self    = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    # output header
    say {$out} join "\t", qw(site seq aa), 'f(i,j)';

    # setup loop
    my @ids;
    my @aas = split //xms, 'ACDEFGHIKLMNPQRSTVWY*';     # TODO: improve this
    my $width = $self->mask_len;

    # loop through sites, ids and AAs to output ppred state freqs
    for my $site (0..$width-1) {
        my $sim_freq_for = $self->state_at($site);
        @ids = sort keys %{ $sim_freq_for // {} } unless @ids;
                                                # get ids from first state
        ID:
        for my $id (@ids) {
            next ID if $id eq $AVERAGE;         # skip averaged ppred freqs
            for my $aa (@aas) {
                say {$out} join "\t", $site + 1, $id, $aa,
                    defined $sim_freq_for->{$id}{$aa}
                        ? sprintf "%.${PREC}f", $sim_freq_for->{$id}{$aa} : 0;
            }   # missing AAs are set to 0 (hence the alphabet)
        }
    }

    close $out;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqMask::Profiles - Evolutionary profiles for sequence sites

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 ppred_profiles

=head2 ppred_freqs

=head2 store

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
