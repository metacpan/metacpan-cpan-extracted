package Bio::MUST::Core::SeqMask::Pmsf;
# ABSTRACT: Posterior mean site frequencies (PMSF) for sequence sites
$Bio::MUST::Core::SeqMask::Pmsf::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use Const::Fast;
use List::AllUtils qw(sum each_arrayref);

extends 'Bio::MUST::Core::SeqMask';

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::SeqMask::Rates';


# override superclass' Bool type
# Note: mask indices are as follow: [site][AA]
#       mask values  are freqs
has '+mask' => (
    isa => 'ArrayRef[ArrayRef[Num]]',
);

# TODO: mask non-applicable methods from superclass? (Liskov principle)

const my $PREC => 10;


sub chi_square_stats {
    my $self = shift;
    my $othr = shift;

    # check that both pmsf objects are the same length
    # potential bugs could come from constant sites etc
    my $s_width = $self->mask_len;
    my $o_width = $othr->mask_len;
    carp "[BMC] Warning: PMSF widths do not match: $s_width vs. $o_width!"
        unless $s_width == $o_width;

    my @stats;

    my $ea = each_arrayref [ $self->all_states ], [ $othr->all_states ];
    while (my ($s_freqs, $o_freqs) = $ea->() ) {
        push @stats, 0 + ( sprintf "%.${PREC}f", sum map {
            ( $o_freqs->[$_] - $s_freqs->[$_] )**2 / $s_freqs->[$_]
        } 0..$#$o_freqs );
    }   # Note: trick to get identical results across platforms
    # https://stackoverflow.com/questions/21204733/a-better-chi-square-test-for-perl

    return Rates->new( mask => \@stats );
}


# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $mask = $class->new();

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines, header line and process comment lines
#       next LINE if $line =~ $EMPTY_LINE
#                 || $mask->is_comment($line);

        # split line on whitespace and ignore first value (site number)
        my (undef, @fields) = split /\s+/xms, $line;

        # store AA freqs all at once
        $mask->add_state( \@fields );
    }

    return $mask;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqMask::Pmsf - Posterior mean site frequencies (PMSF) for sequence sites

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 chi_square_stats

=head2 load

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
