package Bio::MUST::Core::SeqMask::Freqs;
# ABSTRACT: Arbitrary frequencies for sequence sites
$Bio::MUST::Core::SeqMask::Freqs::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Const::Fast;
use List::AllUtils qw(sum);

use Bio::MUST::Core::Types;
use aliased 'Bio::MUST::Core::SeqMask::Rates';


# public hash containing freqs by sequence and site
# Note: this hash is actually a Tie::IxHash (see Profiles)
has 'freq_for_at' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Num]]',
    required => 1,
    handles  => {
        count_freqs_at     => 'count',
          all_freqs_at     => 'values',
              freqs_at_for => 'get',
          all_ids          => 'keys',
    },
);


# private SeqMask::Rates-like object derived by averaging freqs over seqs
has '_mask' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::SeqMask::Rates',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_mask',
    handles  => {
       mask_len         => 'mask_len',
        all_freqs       =>  'all_states',
        min_freq        =>  'min_rate',
        max_freq        =>  'max_rate',
        bin_freqs_masks =>  'bin_rates_masks',
            freqs_mask  =>      'rates_mask',
    },
);


# private hash containing freqs averaged over sites
has '_avg_freq_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Num]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_avg_freq_for',
    handles  => {
        avg_freq_for => 'get',
    },
);

const my $PREC => 3;

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_mask {
    my $self = shift;

    my @mask;

    # average freqs over seqs
    for my $freqs_at ($self->all_freqs_at) {
        my $i = 0;
        $mask[$i++] += $_ for @{$freqs_at};
    }
    my $n = $self->count_freqs_at;
    @mask = map { $_ / $n } @mask;

    return Rates->new( mask => \@mask );
}


sub _build_avg_freq_for {
    my $self = shift;

    my %avg_freq_for;

    # average freqs over sites
    my $n = $self->mask_len;
    for my $id ($self->all_ids) {
        $avg_freq_for{$id} = sum( @{ $self->freqs_at_for($id) } ) / $n;
    }

    return \%avg_freq_for;
}

## use critic



sub store {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $reorder = $args->{reorder} // 0;

    open my $out, '>', $outfile;

    # optionally sort ids by descending average freq (over sites)
    my @ids = $self->all_ids;
       @ids = sort {
            $self->avg_freq_for($b) <=> $self->avg_freq_for($a)
    }  @ids if $reorder;

    # output header
    say {$out} join "\t", 'site', 'f(i,.)', @ids;

    # output average freqs (over sites)
    say {$out} join "\t", 'f(.,j)', q{},
        map { sprintf "%.${PREC}f", $self->avg_freq_for($_) } @ids;

    # setup rows with site numbers and average freqs (over seqs)
    my @rows = 1..$self->mask_len;
    my @avg_freqs_at = map { sprintf "%.${PREC}f", $_ } $self->all_freqs;
    $_ .= "\t" . shift @avg_freqs_at for @rows;

    # assemble freqs by site (one site by row)
    for my $id (@ids) {
        my @freqs_at
            = map { sprintf "%.${PREC}f", $_ } @{ $self->freqs_at_for($id) };
        $_ .= "\t" . shift @freqs_at for @rows;
    }

    # output freqs for all sites
    say {$out} $_ for @rows;

    close $out;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqMask::Freqs - Arbitrary frequencies for sequence sites

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 store

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
