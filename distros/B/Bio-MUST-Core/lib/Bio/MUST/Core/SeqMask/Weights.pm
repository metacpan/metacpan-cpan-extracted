package Bio::MUST::Core::SeqMask::Weights;
# ABSTRACT: Random weights for resampling sequence sites
$Bio::MUST::Core::SeqMask::Weights::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use List::AllUtils qw(sample);
use POSIX;

extends 'Bio::MUST::Core::SeqMask';

use Bio::MUST::Core::Types;


# override superclass' Bool type
# Note: mask indices are as follow: [site]
#       mask values  are integer weights (>= 0)
has '+mask' => (
    isa => 'ArrayRef[Int]',
);

# TODO: mask non-applicable methods from superclass? (Liskov principle)



sub bootstrap_masks {
    my $class = shift;
    my $ali   = shift;
    my $args  = shift // {};            # HashRef (should not be empty...)

    my $rep_n = $args->{rep} // 100;
    my $width = $ali->width;
    my $k     = $args->{width} // $width;

    # convert fractional len to conservative integer (if needed)
    $k = ceil($k * $width) if 0 < $k && $k <= 1;

    my @masks;

    for my $i (1..$rep_n) {
        my @weights = (0) x $width;
        $weights[ int(rand $width) ]++ for 1..$k;       # bootstrap sites
        push @masks, $class->new( mask => \@weights );
    }

    return @masks;
}



sub jackknife_masks {
    my $class = shift;
    my $ali   = shift;
    my $args  = shift // {};            # HashRef (should not be empty...)

    my $rep_n = $args->{rep} // 100;
    my $width = $ali->width;
    my $k     = $args->{width} // 0.5;

    # convert fractional len to conservative integer (if needed)
    $k = ceil($k * $width) if 0 < $k && $k <= 1;

    my @masks;

    for my $i (1..$rep_n) {
        my @sites = sample $k, (0..$width-1);           # jackknife sites
        push @masks, $class->custom_mask($width, \@sites);
    }

    return @masks;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqMask::Weights - Random weights for resampling sequence sites

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 bootstrap_masks

=head2 jackknife_masks

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
