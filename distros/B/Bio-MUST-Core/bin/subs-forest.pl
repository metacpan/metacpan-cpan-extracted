#!/usr/bin/env perl
# PODNAME: subs-forest.pl
# ABSTRACT: Subsample forest (multiple trees) files (and restore ids)

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix secure_outfile);
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::Tree::Forest';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $forest = Forest->load($infile);

    $infile =~ s/$_//xms for @ARGV_in_strip;

    if ($ARGV_map_ids) {
        my $idmfile = change_suffix($infile, '.idm');
        my $idm = IdMapper->load($idmfile);
        ### Restoring seq ids from: $idmfile
        $forest->restore_ids($idm);
    }

    if (%ARGV_x) {
        my ($burnin, $every, $until) = @ARGV_x{ qw(burnin every until) };
        $until = $forest->count_trees
            if !$until || $until > $forest->count_trees;
        die "<burnin> ($burnin) larger than <until> ($until); aborting!\n"
            if $burnin > $until;
        ### Subsampling using: "-x $burnin $every $until"

        my @trees;
        for (my $i = $burnin; $i < $until ; $i += $every) {
            push @trees, $forest->get_tree($i);
        }
        $forest = Forest->new( trees => \@trees );
    }

    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $forest->store($outfile);
}

__END__

=pod

=head1 NAME

subs-forest.pl - Subsample forest (multiple trees) files (and restore ids)

=head1 VERSION

version 0.251810

=head1 USAGE

    subs-forest.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input forest files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --in[-strip]=<str>

Substring(s) to strip from infile basenames before attempting to derive other
infile (e.g., IDM files) and outfile names [default: none].

=for Euclid: str.type: string
    repeatable

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

=item --map-ids

Sequence id mapping switch [default: no]. When specified, sequence ids are
restored from the corresponding IDM files.

=item -x <burnin> [<every> [<until>]]

Forest subsampling scheme [default: 0 1 Inf]. This option follows PhyloBayes'
C<bpcomp> and C<readpb> usage.

=for Euclid: burnin.type: int >= 0
    burnin.default: 0
    every.type:  int > 0
    every.default:  1
    until.type:  int > 0
    until.default:  undef

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
