package Bio::MUST::Apps::SlaveAligner::Local;
# ABSTRACT: Internal class for slave-aligner
$Bio::MUST::Apps::SlaveAligner::Local::VERSION = '0.213470';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say switch);
use experimental qw(smartmatch);        # to suppress warnings about 'when'

use Smart::Comments -ENV;

use List::AllUtils qw(max);
use Sort::Naturally;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Seq';


# _delayed_indels is a hash (site) of hashes (new_seq id)
# storing the number of insertions caused by each new_seq at each
# pos (as if each new_seq was added on its own to the Ali)

has 'ali' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
);


has '_delayed_indels' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[HashRef[Num]]',
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        all_sites => 'keys',
        indels_at => 'get',
    },
);


sub align {                                 ## no critic (RequireArgUnpacking)
    my $self = shift;
    my %args = @_;

	my (
	    $query,                 #  new_seq as aligned in BLAST report
	    $sbjct,                 # template as aligned in BLAST report
	    $tmplt,                 # template as aligned in Ali
	    $splcd,
	    $start                  # pairwise alignment start in template
	) = @args{ qw(new_seq subject template cds_seq start) };

    # determine mode (prot/nucl) based on absence/presence of a DNA seq
    # setup multiplier according to mode
    my $mul = defined $splcd ? 3 : 1;

    # align query left-end on template
    for (my $u = 0; $u < $start; $u++) {
        $start++ if $tmplt->is_gap($u);
    }
    my $aligned_seq = q{ } x ( ($start-1) * $mul );

    # TODO: check whether $start can be set to hit_start-1 before the loop

    # setup loop
    my $t = $start-1;               # pos within template in Ali
    my $q = 0;                      # pos within  new_seq in BLAST report
    my $s = 0;                      # pos within template in BLAST report
    my $len = $query->seq_len;

    # loop through new_seq positions
    while ($q < $len) {

        # encode gap configuration for easy dispatching
        my $case
            = $tmplt->is_gap($t)
            . $query->is_gap($q)
            . $sbjct->is_gap($s)
        ;

        # examine 6 possible cases (t* q* s* and tL q* s* do not exist)
        given ($case) {
            when (/100|110/xms) {   # case 1: t* qL sL
                                    # case 2: t* q* sL
                $aligned_seq .= '*' x $mul;
                $t++;
            }
            when (/101|000/xms) {   # case 3: t* qL s*
                                    # case 4: tL qL sL
                $aligned_seq .= $mul == 1 ? $query->state_at($q)
                                          : $splcd->edit_seq($q * $mul, $mul);
                $t++;
                $q++;
                $s++;
            }
            when (/010/xms) {       # case 5: tL q* sL
                $aligned_seq .= '*' x $mul;
                $t++;
                $q++;
                $s++;
            }
            when (/001/xms) {       # case 6: tL qL s*
                $aligned_seq .= $mul == 1 ? $query->state_at($q)
                                          : $splcd->edit_seq($q * $mul, $mul);
                $self->_delayed_indels->{$t}{ $query->full_id } += $mul;
                $q++;
                $s++;
            }
        }
    }

    return Seq->new(
        seq_id => $query->full_id,
        seq    => $aligned_seq
    );
}


# TODO: ensure that new seqs are in Ali

sub make_indels {
    my $self = shift;

    # process delayed indels (from left to right)
    my $offset = 0;
    my @sites = sort { $a <=> $b } $self->all_sites;

    for my $site (@sites) {

        # get length of longest indel at site
        my %indel_by = %{ $self->indels_at($site) };
        my $max_indel = max values %indel_by;

        # insert indels at site into all seqs

        SEQ:
        for my $seq ( $self->ali->all_seqs ) {

            # reduce indel length if seq has indels at the same site
            my $indel = $max_indel - ( $indel_by{ $seq->full_id } // 0 );

            # skip seq if indel reduced to zero
            next SEQ if $indel == 0;

            # skip seq if indel farther than seq end
            # TODO: check boundary
            next SEQ if $site + $offset > $seq->seq_len - 1;

            # splice seq to insert required number of gaps
            $seq->edit_seq($site + $offset, 0, '*' x $indel);
        }

        # account for indel in subsequent computations
        $offset += $max_indel;
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::SlaveAligner::Local - Internal class for slave-aligner

=head1 VERSION

version 0.213470

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
