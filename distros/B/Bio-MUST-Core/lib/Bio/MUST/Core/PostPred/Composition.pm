package Bio::MUST::Core::PostPred::Composition;
# ABSTRACT: Posterior predictive test for compositional bias
$Bio::MUST::Core::PostPred::Composition::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use List::AllUtils qw(sum);
use Tie::IxHash;

use Bio::MUST::Core::Types;


has 'seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
    handles  => [
        qw(gapmiss_regex all_seqs)
    ],
);

# TODO: consider a role if more tests are implemented

# private hash containing compositional biases
# Note: this hash is actually a Tie::IxHash (see builder)
has '_stat_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Num]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_stat_for',
    handles  => {
         all_ids => 'keys',
        stat_for => 'get',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_stat_for {
    my $self = shift;

        my %glb_freq_for;
    tie my %seq_freq_for, 'Tie::IxHash';

    my $regex = $self->gapmiss_regex;
    my $glb_tot = 0;

    # loop through seqs to store state freqs
    for my $seq ($self->all_seqs) {
        my %freq_for;
        my $seq_tot = 0;

        STATE:
        for my $state ($seq->all_states) {
            $state = uc $state;

            # skip missing/gap states
            # Note: This is different from what we do in SeqMask::Profiles
            # so as to avoid these states to decrease regular state freqs
            next STATE if $state =~ m/$regex/xms;

            # store state occurrences both for current seq and globally
            $glb_freq_for{$state}++;
                $freq_for{$state}++;
            $glb_tot++;
            $seq_tot++;
        }

        # convert occurrences to freqs for current seq
        $freq_for{$_} /= $seq_tot for keys %freq_for;

        # store freqs for current seq
        $seq_freq_for{ $seq->full_id } = \%freq_for;
    }

    # convert global occurrences to freqs
    $glb_freq_for{$_} /= $glb_tot for keys %glb_freq_for;

    tie my %bias_for, 'Tie::IxHash';

    # compute bias for each seq
    # according to Blanquart and Lartillot 2008
    for my $id (keys %seq_freq_for) {
        while (my ($aa, $freq) = each %glb_freq_for) {
            $bias_for{$id} += ( ($seq_freq_for{$id}{$aa} // 0) - $freq ) ** 2;
        }
    }

    # compute global biases
    $bias_for{'GLOBALMAX'}  = List::AllUtils::max( values %bias_for );
    $bias_for{'GLOBALMEAN'} = sum( values %bias_for ) / keys %bias_for;

    return \%bias_for;
}

## use critic

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::PostPred::Composition - Posterior predictive test for compositional bias

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
