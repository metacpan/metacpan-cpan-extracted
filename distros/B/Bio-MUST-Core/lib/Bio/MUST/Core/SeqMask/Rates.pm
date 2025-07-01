package Bio::MUST::Core::SeqMask::Rates;
# ABSTRACT: Evolutionary rates for sequence sites
$Bio::MUST::Core::SeqMask::Rates::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use Const::Fast;
use List::AllUtils qw(each_arrayref);
use POSIX;

extends 'Bio::MUST::Core::SeqMask';

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::SeqMask';


# override superclass' Bool type
# Note: mask indices are as follow: [site]
#       mask values  are rates
has '+mask' => (
    isa => 'ArrayRef[Num]',
);

# TODO: mask non-applicable methods from superclass? (Liskov principle)



sub min_rate {
    my $self = shift;
    return List::AllUtils::min @{ $self->mask };
}



sub max_rate {
    my $self = shift;
    return List::AllUtils::max @{ $self->mask };
}



sub delta_rates {
    my $self = shift;
    my $othr = shift;

    # check that both rates objects are the same length
    # potential bugs could come from constant sites etc
    my $s_width = $self->mask_len;
    my $o_width = $othr->mask_len;
    carp "[BMC] Warning: Rates widths do not match: $s_width vs. $o_width!"
        unless $s_width == $o_width;

    my @deltas;

    my $ea = each_arrayref [ $self->all_states ], [ $othr->all_states ];
    while (my ($s_rate, $o_rate) = $ea->() ) {
        push @deltas, 0 + ( sprintf "%.13f", abs( $s_rate - $o_rate ) );
    }   # Note: trick to get identical results across platforms

    # TODO: check that $self->new() is really correct
    return $self->new( mask => \@deltas );
}


# Rates-based SeqMask factory methods


# small delta for slightly increasing extreme bins
const my $DELTA => 1e-13;

sub bin_rates_masks {
    my $self  = shift;
    my $bin_n = shift;
    my $args  = shift // {};            # HashRef (should not be empty...)

    my $percentile = $args->{percentile} // 0;
    my $cumulative = $args->{cumulative} // 0;
    my $descending = $args->{descending} // 0;

    my @masks;

    # define bin bounds based on equal count (in terms of sites)
    if ($percentile) {

        # create rates-sorted index of sites (from slow to fast)
        my @index = sort {
            $self->state_at($a) <=> $self->state_at($b)
        } 0..$self->mask_len-1;

        # optionally reverse index: higher values mean slower rates (TIGER)
        @index = reverse @index if $descending;

        # compute masks from index slices
        my $step = ceil( @index / $bin_n );
        ### $step
        for my $i (0..$bin_n-1) {
            my $min = $cumulative ? 0 : ($i    * $step);
            my $max =                  (($i+1) * $step - 1);
               $max = $#index if $max > $#index;
            ### min: $min
            ### max: $max
            ### rates: map { $self->state_at($_) } @index[ $min..$max ]
            push @masks, SeqMask->custom_mask(
                $self->mask_len, [ @index[ $min..$max ] ]
            );

        }
    }

    # define bin bounds based on equal width (in terms of rates)
    else {
        my @bounds;

        # compute bin bounds from rate range
        my $min = $self->min_rate;
        my $max = $self->max_rate;
        my $step = ($max - $min) / $bin_n;
        for (my $i = $min + $step; $i <= $max; $i += $step) {
            push @bounds, $i;
        }
        # Note: did try to use Statistics::Descriptive with no luck

        # add lower bound for first bin...
        # ... and small delta to first/last bins for catching min/max values
        unshift @bounds, $min -  $DELTA;
                $bounds[-1]   += $DELTA;

        # optionally reverse bounds: higher values mean slower rates (TIGER)
        @bounds = reverse @bounds if $descending;
        ### @bounds

        # derive masks from bin bounds
        for my $i (1..$#bounds) {
            push @masks, $self->rates_mask(
                $cumulative ? $bounds[0] : $bounds[$i - 1],     # bin min
                $bounds[$i]                                     # bin max
            );
        }
    }

    return @masks;
}



sub rates_mask {
    my $self = shift;
    my $min  = shift;
    my $max  = shift;

    # ensure min and max are correctly ordered
    ($min, $max) = sort ($min, $max);

    # filter out sites not within (bin) bounds
    my @mask = map {
        (
            $self->state_at($_) >  $min
         && $self->state_at($_) <= $max
        ) + 0           # ensure proper numeric context (0 or 1)
    } 0..$self->mask_len-1;

    return SeqMask->new( mask => \@mask );
}


# I/O methods


# TODO: avoid duplicating code with SeqMask class

# TIGER format:
# 0.651325757576
# 0.633143939394
# 0.488257575758
# 1.0
# ...

# PhyloBayes (MPI) format:
# 0   15.5174
# 1   16.4429
# 2   18.664
# 3   30.1682
# ...

# PhyloBayes (serial) format:
# site  rate    std error
#
# 1   5.86191 0.207244
# 2   7.35053 0.350185
# 3   6.09158 0.24426
# ...

# IQ-TREE format:
# # Site-specific subtitution rates determined by empirical Bayesian method
# # This file can be read in MS Excel or in R with command:
# #   tab=read.table('replica-3-concat-modified.fasta.rate',header=TRUE)
# # Columns are tab-separated with following meaning:
# #   Site:   Alignment site ID
# #   Rate:   Posterior mean site rate weighted by posterior probability
# #   Cat:    Category with highest posterior (0=invariable, 1=slow, etc)
# #   C_Rate: Corresponding rate of highest category
# Site    Rate    Cat C_Rate
# 1   0.31154 1   0.30935
# 2   1.03326 4   1.91612
# 3   1.39822 4   1.91612
# ...

const my %COLUMN_FOR => (
    1 => 0,     # TIGER
    2 => 1,     # PhyloBayes (MPI)
    3 => 1,     # PhyloBayes (serial)
    4 => 1,     # IQ-TREE
);

sub load {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $mask = $class->new();
    my $col;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines, header line and process comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ m/^site/xmsi          # PhyloBayes/IQ-TREE
                  || $mask->is_comment($line);

        # try to split line on whitespace
        my @fields = split /\s+/xms, $line;
        $col //= $COLUMN_FOR{ scalar @fields };

        # store either first or second field depending on split outcome
        # Note: we check this outcome only once for efficiency
        $mask->add_state( $fields[$col] );
    }

    return $mask;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqMask::Rates - Evolutionary rates for sequence sites

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 min_rate

=head2 max_rate

=head2 delta_rates

=head2 bin_rates_masks

=head2 rates_mask

=head2 load

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
