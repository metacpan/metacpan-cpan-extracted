#!/usr/bin/env perl
# PODNAME: split-ppred-ali.pl
# ABSTRACT: Split ALI files into subsets of sites based on ppred data

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::SeqMask';
use aliased 'Bio::MUST::Core::SeqMask::Profiles';


# TODO: generalize this to other executables through Utils?
my ($load, $store) = qw(load store);
my %out_args;
if ($ARGV_phylip) {
    ### Infiles (and outfiles) are in PHYLIP format
    $load  .= '_phylip';
    $store .= '_phylip';
    $out_args{chunk} = -1;
}

# setup optional lists
my $sim_list;
   $sim_list = IdList->load($ARGV_sim_seq_list) if $ARGV_sim_seq_list;
my $obs_list;
   $obs_list = IdList->load($ARGV_obs_seq_list) if $ARGV_obs_seq_list;
my $msk_list;
   $msk_list = $obs_list                        if $ARGV_only_mask;

### Processing simulated files: scalar @ARGV_sim_files
my $sim_alis = [ map { Ali->load_phylip($_) } @ARGV_sim_files ];
my $profiles = Profiles->ppred_profiles($sim_alis, { sim_list => $sim_list } );

INFILE:
for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->$load($infile);
    $ali->gapify_seqs if $ARGV_from_scafos;
    ### Infile: "$infile had " . $ali->width . ' sites'

    # optionally delete constant sites
    $ali->apply_mask( SeqMask->variable_mask($ali) ) if $ARGV_del_const;

    ### Computing masks from ppreds
    my $freqs = $profiles->ppred_freqs($ali, {
        obs_list => $obs_list,
        by_seq   => $ARGV_by_seq,
    } );

    if ($ARGV_only_dump_freqs) {
        my $sim_out = change_suffix($infile, $ARGV_out_suffix . '.sim_freqs');
        ### Dumping simulated freqs to: $sim_out
        $profiles->store($sim_out);
        my $obs_out = change_suffix($infile, $ARGV_out_suffix . '.obs_freqs');
        ### Dumping observed freqs to: $obs_out
        $freqs->store($obs_out, { reorder => $ARGV_reorder } );
        next INFILE;
    }

    my %args;
    $args{percentile} = 1 if $ARGV_percentile;
    $args{cumulative} = 1 if $ARGV_cumulative;
    $args{descending} = 1;              # freqs are always descending!

    my @masks = $freqs->bin_freqs_masks($ARGV_bin_number, \%args);

    # output one Ali per bin
    for my $i (0..$#masks) {
        my $bin_ali = $masks[$i]->filtered_ali($ali, $msk_list);
        my $outfile = secure_outfile($infile, $ARGV_out_suffix . "-bin$i");
        # Note: $ARGV_out_suffix defaults to q{} for smooth concatenation

        ### Outfile: "$outfile has " . $bin_ali->width . ' sites'
        $bin_ali->$store($outfile, \%out_args);
    }
}

__END__

=pod

=head1 NAME

split-ppred-ali.pl - Split ALI files into subsets of sites based on ppred data

=head1 VERSION

version 0.181120

=head1 SYNOPSIS

    $ split-ppred-ali.pl cpVITRELLA-80x8363.puz --phylip
        --sim-files=`ls cpNOVITRELLA-79x8363-CATGTRG-PP_sample_*.ali`
        --sim-seq-list=sim.idl --obs-seq-list=obs.idl
        --bin-number=10 --percentile --out=-ppred

    $ cat sim.idl
    Karlodiniu

    $ cat obs.idl
    Vitrella_b

    # for testing
    $ perl -Ilib bin/split-ppred-ali.pl test/for-ppred.phy --phylip
        --sim-files=`ls test/ppred-*.phy`
        --sim-seq-list=test/sim.idl --obs-seq-list=test/obs.idl
        --bin-number=10 --percentile --out=-ppred --only-mask

    $ perl -Ilib bin/split-ppred-ali.pl test/for-ppred.phy --phylip
        --sim-files=`ls test/ppred-*.phy` --by-seq --only-dump-freqs

At each site, a profile is computed from the simulated primary sequences for
ids listed in C<--sim-seq-list> and compared to the character state observed
in the sequences listed in C<--obs-seq-list>. A mask corresponding to the
simulated frequencies for the observed states is built and sites are ranked
according to these descending frequencies, which means that highest bins
include sites where the observed state is rarely (or never found) in
simulations. Sites where the state is a gap or is missing always get the
maximum frequency and thus fall in the lowest bins.

=head1 USAGE

    split-ppred-ali.pl <infiles> --simfiles=<files>... [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument]. If infiles are not in ALI but
in PHYLIP format, use the C<--phylip> option below.

=for Euclid: infiles.type: readable
    repeatable

=item --sim-files=<files>...

List of paths to simulated input files. These files are assumed to be in
PHYLIP format as they result from PhyloBayes' C<ppred>.

=for Euclid: files.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --out[-suffix]=<suffix>

Suffix to append to (possibly stripped) infile basenames for deriving
outfile names [default: none]. When not specified, outfile names are taken
from infiles but original infiles are preserved by being appended a .bak
suffix.

=for Euclid: suffix.type: string
    suffix.default: q{}

=item --sim-seq-list=<file>

Path to IDL file listing the ids of the sequences from which site profiles
will be computed after acquiring simulated input files [default: all seqs].

=item --obs-seq-list=<file>

Path to IDL file listing the ids of the sequences that will give observed
frequencies and thus govern site trimming in infiles [default: all seqs].

=item --by-seq

Enable seq-specific simulated site profiles [default: no]. When not specified,
average site profiles are computed from simulated input files.

=item --from-scafos

Consider the input ALI file as generated by SCaFoS [default: no]. Currently,
specifying this option results in turning all ambiguous and missing character
states to gaps.

=item --del-const

Delete constant sites just as the C<-dc> option of PhyloBayes [default: no].

=item --phylip

Assume infiles and outfiles are in PHYLIP format (instead of ALI format)
[default: no].

=item --bin-number=<n>

Number of bins to define [default: 10].

=for Euclid: n.type:    number
    n.default: 10

=item --percentile

Define bins containing an equal number of sites rather than bins of equal
width in terms of observed state frequencies [default: no].

=item --cumulative

Define bins including all previous bins [default: no]. This leads to ALI
outfiles of increasing width where the sequences listed in C<-obs-seq-list>
include ever more character states rarely observed in simulated primary
sequences for ids listed in C<--sim-seq-list>.

=item --only-mask

Mask rarely observed states in sequences listed in C<--obs-seq-list> instead
of removing the corresponding sites from the alignment [default: no].

=item --only-dump-freqs

Output simulated and observed state frequencies instead of producing regular
output files [default: no]. When specified, this option supercedes all those
pertaining to site binning.

=item --reorder

Reorder sequences following descending observed freqs [default: no]. This
option only applies when C<--only-dump-freqs> is specified.

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
