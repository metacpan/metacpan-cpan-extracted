package Bio::MUST::Core::PostPred;
# ABSTRACT: Posterior predictive tests for sequences
$Bio::MUST::Core::PostPred::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Statistics::Descriptive;
use Tie::IxHash;

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::PostPred::Composition';


# private hash containing test statistics by sequence (and globally)
# Note: this hash is actually a Tie::IxHash (see factory methods)
has '_stats_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Num]]',
    required => 1,
    handles  => {
          all_ids => 'keys',
        stats_for => 'get',
    },
);


# private hash containing test Z-scores by sequence (and globally)
# Note: this hash is actually a Tie::IxHash (see builder)
has '_zscore_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Num]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_zscore_for',
    handles  => {
        zscore_for => 'get',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

# TODO: switch to BUILD to compute p-values as well
# TODO: explore other Statistics:: modules on CPAN

sub _build_zscore_for {
    my $self = shift;

    tie my %zscore_for, 'Tie::IxHash';

    # loop through all ids (including $GLOBAL id if any)
    for my $id ($self->all_ids) {

        # compute std-dev from simulated stat dist
        # Note: the first value MUST BE the observed test stat
        my ($obs, @sims) = @{ $self->stats_for($id) };
        my $stat = Statistics::Descriptive::Full->new();
           $stat->add_data(@sims);
        my $mean = $stat->mean;
        my $sd   = $stat->standard_deviation;

        # compute and store zscore
        my $zscore = ($obs - $mean) / $sd;
        $zscore_for{$id} = $zscore;
    }

    return \%zscore_for;
}

## use critic


# PostPred factory methods


sub comp_test {                             ## no critic (RequireArgUnpacking)
    return shift->_make_test(Composition, @_);
}


sub _make_test {
    my $class = shift;
    my $type  = shift;
    my $alis  = shift;

    tie my %stats_for, 'Tie::IxHash';

    # loop through Ali objects to compute the required test statistic
    # Note: the first Ali MUST BE the real one and the others the simulations
    for my $ali ( @{$alis} ) {

        # get test statistics for Ali
        my $test = $type->new( seqs => $ali );

        # accumulate test statistics by seq
        push @{ $stats_for{$_} }, $test->stat_for($_)
            for $test->all_ids;
    }

    return $class->new( _stats_for => \%stats_for );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::PostPred - Posterior predictive tests for sequences

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 comp_test

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
