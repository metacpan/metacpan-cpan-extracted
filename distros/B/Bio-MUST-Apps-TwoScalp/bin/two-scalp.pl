#!/usr/bin/env perl
# PODNAME: two-scalp.pl
# ABSTRACT: Align or re-align sequences using various strategies
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@doct.uliege.be>

use Modern::Perl '2011';
use Getopt::Euclid qw(:vars);

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity
        : q{}
    ;
}
## use critic

use Smart::Comments -ENV;

use Carp;
use Const::Fast;
use File::Basename;
use List::AllUtils qw(part uniq count_by);
use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';

use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Drivers::Blast::Database';
use aliased 'Bio::MUST::Drivers::Blast::Database::Temporary';

use Bio::MUST::Apps::TwoScalp;
use aliased 'Bio::MUST::Apps::TwoScalp::AlignAll';
use aliased 'Bio::MUST::Apps::TwoScalp::Seq2Seq';
use aliased 'Bio::MUST::Apps::TwoScalp::Seqs2Profile';
use aliased 'Bio::MUST::Apps::TwoScalp::Profile2Profile';


const my $DEF_FAM => ':default';

# set up mafft options (and pseudo-options --fragments and --long)
my %opt;
$opt{ '--fragments' }  = ()            if $ARGV_fragments;
$opt{ '--long' }       = ()            if $ARGV_long;
$opt{ '--keeplength' } = ()            if $ARGV_keep_length;
$opt{ '--thread'     } = $ARGV_threads if $ARGV_threads > 1;
if ($ARGV_linsi) {
    $opt{ '--maxiterate' } = 1000;
    $opt{ '--localpair'  } = undef;
}

my $master_profile;
my $ref_prefix;

# TODO: check and unifomize error messages with other Bio::MUST::Apps
# TODO: decide between 'master' and 'reference'

if ($ARGV_p_ref) {
    ### Loading master profile: $ARGV_p_ref
    my $ref_profile = Ali->load($ARGV_p_ref);
    # change ids to have no conflict when removing redundant seqs
    my ($temp_file, $temp_mapper)
        = $ref_profile->temp_fasta( {id_prefix => 'pref-'});
    $ref_prefix = Ali->load($temp_file);
    $master_profile = $ref_prefix;
}

my $basename = $ARGV_in_seqs[0];
my $len = @ARGV_in_seqs;
#### number of specified files: $len

my @ord_fams;
my %seqs_for;

### Check if more than one in-seqs file
if ($len > 1) {
    @ord_fams = (1..$len);
    for my $fam (@ord_fams) {
        my $file = shift @ARGV_in_seqs;
        #### file: $file
        my $ali = Ali->load( $file );
        @{ $seqs_for{$fam} } = map { $_ } $ali->all_seqs;
    }
}

# TODO: check alternative here; too complex

### Check if family asked
if (@ord_fams && @ARGV_fam) {
    warn <<'EOT';
Warning: --fam option specified but there is more than one file.
--fam option will be ignored and I will follow infile order instead!"
EOT
}

elsif (@ARGV_fam) {
    @ord_fams = @ARGV_fam;
    my %exist_for = map { $_ => 1 } @ord_fams;
    my $ali = Ali->load(@ARGV_in_seqs);
    for my $seq ($ali->all_seqs) {
        my $fam = $seq->family // $DEF_FAM;

        # TODO: streamline this using either // or ? : within @{ ... }
        if ( exists $exist_for{$fam} ) {
            push @{ $seqs_for{$fam} }, $seq;
        }

        else {
            push @{ $seqs_for{other} }, $seq;
        }
    }
    push @ord_fams, 'other' if $seqs_for{other};
}

unless (@ord_fams) {
    ### One file with no family specified
    my $ali = Ali->load(@ARGV_in_seqs);
    # TODO: move this to Ali introspective methods
    my ($unaligned_seqs, $aligned_seqs)
        = part { $_->is_aligned ? 1 : 0 } $ali->all_seqs;
    @ord_fams = qw(aligned unaligned);
    $seqs_for{  aligned} =   $aligned_seqs if $aligned_seqs;
    $seqs_for{unaligned} = $unaligned_seqs if $unaligned_seqs;
}
#### fam: @ord_fams
##### %seqs_for

FAM:
for my $fam (@ord_fams) {
    ### Check if seqs are aligned from part: $fam

    # TODO: fix this as it is very dangerous to have my depending on if
    # https://metacpan.org/pod/Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations
    ## no critic (ProhibitConditionalDeclarations)
    my $ali = Ali->new( seqs => $seqs_for{$fam}, guessing => 1 )
        if $seqs_for{$fam};
    ## use critic

    unless ($ali) {
        carp "Warning: no sequence found for family: $fam";
        next FAM;
    }

    if ($fam eq 'other') {
        ### Degap seqs from families not specified
        $ali->degap_seqs;
    }

    my ($unaligned_seqs, $aligned_seqs)
        = part { $_->is_aligned ? 1 : 0 } $ali->all_seqs;
        #= part { $_->is_aligned ? 1 : 0 } $seqs_for{$fam};

    my $p2;

    # TODO: check how to simplify complex alternatives here

    if ($aligned_seqs) {
        my $aligned = Ali->new(
            seqs => $aligned_seqs,
            guessing => 1,
        );

        if ($unaligned_seqs) {
            my $unaligned = Ali->new(
                seqs => $unaligned_seqs,
                guessing => 1,
            );
            ### Align non aligned seqs on aligned seqs from the same family
            $p2 = align_on_profile($aligned, $unaligned);
        }
        $p2 = $aligned unless $p2;
    }

    elsif ($unaligned_seqs && $master_profile) {
        ### There are only unaligned seqs in this family
        my $unaligned = Ali->new(
            seqs => $unaligned_seqs,
            guessing => 1,
        );
        $p2 = $unaligned;
    }

    if ($master_profile) {
        my $new_master_profile = align_on_profile($master_profile, $p2);
        $master_profile = $new_master_profile;
    }

    # align from scratch only if only unaligned seqs and no other family
    # TODO: make this more explicit: too subtle combining ? : and postfix unless
    $master_profile = $p2 ? $p2 : align_from_scratch($unaligned_seqs)
        unless $master_profile;
}

if ($ARGV_p_ref) {
    ### prune seq from reference profile
    my @ids2prune = map { $_->full_id } $ref_prefix->all_seq_ids;
    my $list = IdList->new( ids => \@ids2prune );
    $list = $list->negative_list($master_profile);
    my $pruned_ali = $list->filtered_ali($master_profile);
    $master_profile = $pruned_ali;
}

# add suffix
my $outfile = secure_outfile($basename, $ARGV_out_suffix);
### Store fasta outfile: $outfile
$master_profile->store($outfile);


sub align_on_profile {
    # TODO choose better name here (reused from main code)
    ## no critic (ProhibitReusedNames)
    my $master_profile = shift;
    ## use critic
    my $other = shift;
    ##### profile sequences: $master_profile

    my $new_profile = $master_profile;

    unless ($new_profile->has_uniq_ids) {
        ### non uniq seq id in master profile
        $new_profile = uniq_ids($new_profile);
    }

    my $toalign = $other;
    ##### sequence to add: $toalign

    unless ($toalign->has_uniq_ids) {
        ### non uniq seq id p2
        $toalign = uniq_ids($toalign);
    }

    my ($toalign_file, $toalign_mapper)
        = $toalign->temp_fasta( {id_prefix => 'toalign-'} );

    my $profile = $new_profile;
    my ($profile_file, $profile_mapper)
        = $profile->temp_fasta( {id_prefix => 'profile-'} );

    my %mapper = ( profile => $profile_mapper, toalign => $toalign_mapper );

    my $type = $other->is_aligned ? 'prof' : 'seqs';
    ### type of sequence to add: $type

    # set up new (expendable) hash to change used options
    tie my %reduced_opt, 'Tie::IxHash';
    %reduced_opt = %opt;

    if ($type eq 'prof') {
        delete @reduced_opt{ qw( --fragments --long --keeplength ) };
        $new_profile = Profile2Profile->new( file1   => $toalign_file,
                                             file2   => $profile_file,
                                             options => \%reduced_opt  );
    }

    elsif ($type eq 'seqs') {
        delete @reduced_opt{ qw( --maxiterate --localpair ) }
            if $ARGV_keep_length;
        $new_profile =    Seqs2Profile->new( file1   => $toalign_file,
                                             file2   => $profile_file,
                                             options => \%reduced_opt  );
    }

    $new_profile->restore_ids( $mapper{profile} );
    $new_profile->restore_ids( $mapper{toalign} );

    unless ($new_profile->has_uniq_ids) {
        ### non uniq ids between parts to align
        $new_profile = uniq_ids($new_profile);
    }

    return $new_profile;
}


sub align_from_scratch {
    my $seqs = shift;

    my $toalign = Ali->new(
        seqs => $seqs,
        guessing => 1,
    );
    $toalign->degap_seqs;

    unless ($toalign->has_uniq_ids) {
        ### non uniq seq id
        $toalign = uniq_ids($toalign);
    }

    my ($toalign_file, $toalign_mapper) = $toalign->temp_fasta;

    # set up new (expendable) hash to change used options
    tie my %reduced_opt, 'Tie::IxHash';
    %reduced_opt = %opt;
    delete $reduced_opt{ '--keeplength' };

    my $new_profile = AlignAll->new( file    => $toalign_file,
                                     options => \%reduced_opt );
    $new_profile->restore_ids($toalign_mapper);

    return $new_profile;
}


sub uniq_ids {
    # TODO: modify way to check ids and seq to keep seq from master profile
    # with ids slightly different if subseq
    my $ali = shift;

    my @ids = map { $_->full_id } $ali->all_seq_ids;

    my %count_for = count_by { $_ } @ids;
    my @duplicates = grep { $count_for{ $_ } > 1 } @ids;
    #### non uniq ids: @duplicates

    for my $dup ( uniq @duplicates ) {
        my @seqs = grep { $_->full_id eq $dup } $ali->all_seqs;
        my $len_seq = @seqs;

        for my $i ( 1..($len_seq-1) ) {

            unless ( $seqs[$i]->is_subseq_of($seqs[$i-1])
                || ( $seqs[$i-1]->is_subseq_of($seqs[$i])
                &&   $seqs[$i]->is_subseq_of($seqs[$i-1]) ) ) {
                carp "Warning: duplicate ids but different sequences for: $dup";
            }
        }
    }

    my @uniq_ids = uniq @ids;
    my @seq_uniq_ids = map { $ali->get_seq_with_id($_) } @uniq_ids;
    my $ali2 = Ali->new(
        seqs => \@seq_uniq_ids,
        guessing => 1,
    );

    return $ali2;
}


# TODO: check if args are better served with 'repeatable' or '...'

__END__

=pod

=head1 NAME

two-scalp.pl - Align or re-align sequences using various strategies

=head1 VERSION

version 0.243240

=head1 USAGE

    two-scalp.pl --in-seqs=<infiles>... [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item --in-seqs=<infiles>...

Path to input ALI file(s) with sequences to align. If only one file is
specified, the script aligns all non-aligned sequences on the already aligned
sequences (but see option C<--fam> below). If several files are specified,
each file is aligned on the previous one(s) in the given order.

=for Euclid: infiles.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --p-ref=<infile>

Path to input ALI file with already aligned sequences [default: none]. When
such a master profile is specified, its sequences are only used as references
for aligning the sequences of the other input file(s). Therefore, they will
not appear in the final output.

=for Euclid: infile.type: readable

=item --fam=<family>...

Family (or families) to consider when aligning sequences (already aligned or
not) [default: none]. Families are processed in the given order, i.e., the
first specified family is the first aligned and will serve as a master profile
for the second one, etc. If sequences from additional families (or devoid of
family) are also present, these are degapped and aligned on the profile
obtained after aligning the specified families.

=for Euclid: family.type: string

=item --fragments

Run MAFFT with the C<--addfragments> option [default: no]. This option should
be specified when the sequences to align are (much) shorter than the sequences
that are already aligned. See
L<https://mafft.cbrc.jp/alignment/server/add.html> for details.

=item --long

Run MAFFT with the C<--addlong> option [default: no]. This option should be
specified when the sequences to align are (much) longer than the sequences
that are already aligned. See
L<https://mafft.cbrc.jp/alignment/server/add.html> for details.

=item --keep-length

Alignment length remains unchanged when adding sequences from the same family
[default: no]. This is achieved by clipping sequence regions not fitting in the
existing alignment.

=item --linsi

Run C<mafft-linsi> instead of the default C<mafft> executable for more accurate
alignment [default: no]. If the C<--keep-length> option is specified, the
default C<mafft> will still be run when aligning sequences from the same family.

=item --threads=<n>

Number of threads to allocate to the aligner [default: n.default]. Mostly useful
when the C<--linsi> option is specified.

=for Euclid: n.type: +int
    n.default: 1

=item --out[-suffix]=<suffix>

Suffix to append to infile basename for deriving outfile name [default:
suffix.default]. The infile giving the basename is the first given to --in-seqs.

=for Euclid: suffix.type: string
    suffix.default: '-ts'

=item --verbosity=<level>

Verbosity level for logging to STDERR [default: level.default]. Available levels
range from 0 to 6. Level 6 corresponds to debugging mode.

=for Euclid: level.type: int, level >= 0 && level <= 6
    level.default: 0

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Amandine BERTRAND Valerian LUPO

=over 4

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Valerian LUPO <valerian.lupo@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
