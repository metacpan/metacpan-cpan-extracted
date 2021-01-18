#!/usr/bin/env perl
# PODNAME: abbr-ids-fas.pl
# ABSTRACT: Abbreviate (standardize) seq ids in FASTA files

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:seqids);
use Bio::MUST::Core::Utils qw(change_suffix secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdMapper';


# regexes for capturing unique identifier component
my %regex_for = (
    ':DEF' => $DEF_ID,
    ':GI'  =>  $GI_ID,
    ':GNL' => $GNL_ID,
    ':JGI' => $JGI_ID,
    ':PAC' => $PAC_ID,
);

# load optional prefix mapper file
my $prefix_mapper;
if ($ARGV_id_prefix_mapper) {
    ### Taking prefixes from: $ARGV_id_prefix_mapper
    $prefix_mapper = IdMapper->load($ARGV_id_prefix_mapper);
}

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->dont_guess;

    # determine seq_id prefix
    my $prefix = $ARGV_id_prefix // q{};        # defaults to no prefix
    if ($prefix_mapper) {                       # infile paths are ignored
        my ($filename) = fileparse($infile);
        $prefix .= $prefix_mapper->abbr_id_for($filename);
    }
    if ($prefix) {
        ### Prefixing seq ids with: $prefix
        $prefix .= '|';                         # add '|' separator
    }

    # build id_mapper
    my $id_mapper;

    # 1. regex mapper (first use input as hash key then as regex)
    if ($ARGV_id_regex) {
        my $regex = $regex_for{$ARGV_id_regex} // $ARGV_id_regex;
        $id_mapper = $ali->regex_mapper($prefix, $regex);
        ### Using seq id regex: $regex
    }

    # 2. accession mapper
    elsif ($ARGV_ids_from_acc) {
        $id_mapper = $ali->acc_mapper(  $prefix);
        ### Using accessions as seq ids
    }

    # 3. standard mapper
    else {
        $id_mapper = $ali->std_mapper(  $prefix . 'seq');
        ### Using standard seq ids
    }

    $ali->shorten_ids($id_mapper);

    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store_fasta($outfile);

    # optionally store the id mapper
    if ($ARGV_store_id_mapper) {
        my $idmfile = change_suffix($outfile, '.idm');
        $id_mapper->store($idmfile);
    }

}

__END__

=pod

=head1 NAME

abbr-ids-fas.pl - Abbreviate (standardize) seq ids in FASTA files

=head1 VERSION

version 0.210170

=head1 USAGE

    abbr-ids-fas.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

=item --store-id-mapper

Store the IDM file corresponding to each output file [default: no].

=item --id-prefix-mapper=<file>

Path to an optional IDM file explicitly listing the infile => prefix pairs.
Useful in the context of processing multiple input files. This argument and
the next one (C<--id-prefix>) can be both specified together. In such a case,
however, a single pipe char is appended to the combined prefix.

=for Euclid: file.type: readable

=item --id-prefix=<str>

String to use as the seq id prefix (e.g., NCBI taxon id, 4-letter code)
[default: none].

=for Euclid: str.type: string

=item --id-regex=<str>

Regular expression for capturing the original seq id [default: none]. When
both are specified, this argument takes precedence on the next one
(C<--ids-from-acc>).

The argument value can be either a predefined regex or a custom regex given
on the command line (do not forget to escape the special chars then). The
following predefined regexes are available (assuming a leading '>'):

    - :DEF (first stretch of non-whitespace chars)
    - :GI  (number nnn in  gi|nnn|...)
    - :GNL (string xxx in gnl|yyy|xxx)
    - :JGI (number nnn in jgi|xxx|nnn or jgi|xxx|nnn|yyy)
    - :PAC (number nnn in xxx|PACid:nnn)

=for Euclid: str.type: string

=item --ids-from-acc

Use MUST accessions or gi numbers (after the @ char) as abbr seq ids [default:
no]. When neither this argument nor the preceding one (C<--id-regex>) is
specified, abbr seq ids will be of the form seq1, seq2 etc.

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
