#!/usr/bin/env perl
# PODNAME: inst-tax-filter.pl
# ABSTRACT: Apply a taxonomic filter to a (UniProt) FASTA database (optimized)
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

use Modern::Perl '2011';
use autodie;

use File::Basename;
use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::Taxonomy';

# build taxonomy and filter objects
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
my $filter = $tax->tax_filter($ARGV_filter);
### Active filter: $filter->all_specs

# regexes for capturing org component
my %regex_for = (
    ':UNI' => qr/OS=(.*) \s+ OX=/xms,
);

# setup (optional) regex (first use input as hash key then as regex)
my $regex;
if ($ARGV_id_regex) {
    $regex = $regex_for{$ARGV_id_regex} // $ARGV_id_regex;
    ### Using seq id regex: $regex
}

my $tax_filter = sub {
    my $seq = shift;
    my $seq_id = $seq->seq_id;

    # optionally extract org and update seq_id using specified regex
    if ($regex) {
        my ($org) = $seq_id->full_id =~ $regex;
        # skip unknown orgs
        return unless $org;     # TODO: issue warning?
        $seq_id = SeqId->new_with(
            org => $org, accession => '1', keep_strain => 1
        );
    }

    # skip unallowed seqs
    return unless $filter->is_allowed($seq_id);

    # store allowed seqs
    my $str = '>' . $seq->full_id . "\n";   # use original seq_id
    $str .= $seq->wrapped_str;

    return $str;
};

for my $infile (@ARGV_infiles) {
    my ($filename) = fileparse($ARGV_filter, qr{\.[^.]*}xms);
    my $outfile = secure_outfile($infile, "-$filename");

    ### Processing: $infile
    Ali->instant_store(
        $outfile, { infile => $infile, coderef => $tax_filter }
    );
}

__END__

=pod

=head1 NAME

inst-tax-filter.pl - Apply a taxonomic filter to a (UniProt) FASTA database (optimized)

=head1 VERSION

version 0.251810

=head1 USAGE

    inst-tax-filter.pl <infiles> --filter=<file> --taxdir=<dir>
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --filter=<file>

Path to an IDL file specifying the taxonomic filter to be applied.

In a tax_filter, wanted taxa are to be prefixed by a '+' symbol, whereas
unwanted taxa are to be prefixed by a '-' symbol. Wanted and unwanted taxa
are linked by logical ORs.

An example IDL file follows:

    -Viridiplantae
    -Opisthokonta
    +Ascomycota
    +Oomycota

=for Euclid: file.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --id-regex=<str>

Regular expression for capturing org from seq id [default: none].

The argument value can be either a predefined regex or a custom regex given
on the command line (do not forget to escape the special chars then). The
following predefined regexes are available (assuming a leading '>'):

    - :UNI (UniProt OS= field)

=for Euclid: str.type: string

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Valerian LUPO

Valerian LUPO <valerian.lupo@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
