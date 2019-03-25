package Bio::MUST::Apps::Roles::OrgProcable;
# ABSTRACT: Attributes and methods common to OrgProcessor objects
$Bio::MUST::Apps::Roles::OrgProcable::VERSION = '0.190820';
use Moose::Role;

use autodie;
use feature qw(say);

use Smart::Comments -ENV;

use List::AllUtils qw(each_array);
use Number::Interval;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::SeqMask';


has 'org' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has 'banks' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => {
        all_banks => 'elements',
    },
);


has 'code' => (
    is       => 'ro',
    isa      => 'Str',
    default  => '1',
);


sub _collect_hsps {                         ## no critic (RequireArgUnpacking)
    my $self = shift;
    my %args = @_;

    my ($parser, $protein, $transcript, $mask_for, $hit_for, $strand_for)
        = @args{ qw(parser protein transcript mask_for hit_for strand_for) };

    # Note: this method should work both for
    # - XML HSPs within a single hit (1331)
    # - multi-query/multi-hit tabular HSPs (42)
    $parser //= $transcript;

    while (my $hsp = $parser->next_hsp) {

        # get mask key from query protein (1331) or hit hsp (42)
        my $key = $transcript ? $protein->query_def : $hsp->hit_id;

        # update coverage on corresponding hit
        push @{ $mask_for->{$key} }, Number::Interval->new(
               min => $hsp->hit_start, max => $hsp->hit_end,
            incmin => 1,            incmax => 1,
        );

        # record protein => best transcript pair (only for 1331)
        # Note: we do this here rather than in leel OrgProcessor for symmetry
        $hit_for->{$key} //= $transcript->id
            if defined $hit_for;

        # record strand (only for 42)
        $strand_for->{$key} += $hsp->hit_strand
            if defined $strand_for;
    }

    return;
}


sub _fetch_and_trim_hits {                  ## no critic (RequireArgUnpacking)
    my $self = shift;
    my %args = @_;

    my ($blastdb, $mask_for, $hit_for, $strand_for)
        = @args{ qw(blastdb mask_for hit_for strand_for) };

    my $rp = $self->ali_proc->run_proc;

    # compute seq chunks to extract from all hits (default behavior)
    my @entries;
    if ($rp->trimming_mode eq 'on') {

        # tie might help making app completely deterministic
        tie my %chunks_for, 'Tie::IxHash';

        # loop through masks to consolidate neighboring ranges into chunks
        # Note: while ranges always deal with hit seqs...
        # ... the key is either a protein abbr_id (1331) or a hit id (42)
        while ( my ($key, $mask) = each %{$mask_for} ) {

            # first fetch seed range (corresponding to the best HSP)
            # this will be useful for 1331 only (see below)
            my $seed = $mask->[0]->min;

            # then sort ranges in ascending order
            my @ranges = sort { $a->min <=> $b->min } @{$mask};

            # merge successive ranges not farther away than hit_max_shift
            my $range1 = shift @ranges;
            while (my $range2 = shift @ranges) {

                # too distant: store current chunk and start new one
                if ( $range2->min - $range1->max > $rp->trim_max_shift) {
                    push @{ $chunks_for{$key} }, $range1;
                    $range1 = $range2;
                }

                # close enough: extend current chunk
                else {
                    $range1->max(
                        List::AllUtils::max( $range1->max, $range2->max )
                    );  # Note: this is needed as BLAST can return HSPs
                }       # that are completely included within better HSPs...
            }

            # store last chunk
            push @{ $chunks_for{$key} }, $range1;

            # only keep the (extended) range containing seed (only for 1331)
            # this allows extracting the correct seq in case of paralogy
            if (defined $hit_for) {
                $chunks_for{$key} = [
                    grep { $_->contains($seed) } @{ $chunks_for{$key} }
                ];
            }
        }

        # format chunks for retrieval with blastdbcmd...
        # ... allowing for hit_extra_margin (no risk of out-of-bound max)
        # keys are converted to hit ids on the fly (only for 1331)
        while ( my ($key, $chunks) = each %chunks_for ) {
            push @entries, map {
                (defined $hit_for ? $hit_for->{$key} : $key) . q{ }
                    . List::AllUtils::max(1, $_->min - $rp->trim_extra_margin)
                    . q{-} .                ($_->max + $rp->trim_extra_margin)
            } @{$chunks};
        }
    }

    # otherwise simply extract whole hits
    else {
        @entries = map {                        # again on the fly (see above)
            defined $hit_for ? $hit_for->{$_} : $_
        } keys %{$mask_for};
    }

    # fetch hits from BLAST database
    # in any case extracted seqs are hits (for both 1331 and 42)
    # trimming is left to blastdbcmd (should be very efficient)
    my @hits = $blastdb->blastdbcmd( \@entries )->all_seqs;

    # rename hits after (long) id of corresponding protein (only for 1331)
    if (defined $hit_for) {
        my @abbr_ids = keys %{$mask_for};
        my $ea = each_array(@abbr_ids, @hits);
        while (my ($abbr_id, $hit) = $ea->() ) {
            my $new_id = $self->long_id_for($abbr_id);
            $hit->set_seq_id( SeqId->new( full_id => $new_id ) );
        }
    }

    # rename hits to fill in tax-reports (only for 42)
    # this is only needed when trimming_mode is on (default behavior)
    if (defined $strand_for && $rp->trimming_mode eq 'on') {
        my %count_for;
        my $ea = each_array(@entries, @hits);
        while (my ($entry, $hit) = $ea->() ) {

            # extract details from entry
            my ($hit_id, $start, $end) = $entry =~ m/(\S+)\s(\d+)\-(\d+)/xms;

            # compute hit strand (through HSPs votes)
            # Note: strand might be inaccurate in case of multiple chunks
            my $strand = $strand_for->{$hit_id} >= 0 ? 1 : -1;

            # embed range and strand in hit_id
            my $new_id = join ':::', $hit_id, $start, $end, $strand;
            $hit->set_seq_id( SeqId->new( full_id => $new_id ) );
        }
    }

    return @hits;
}


sub display {                               ## no critic (RequireArgUnpacking)
    return join "\n--- ", q{}, @_
}


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Roles::OrgProcable - Attributes and methods common to OrgProcessor objects

=head1 VERSION

version 0.190820

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
