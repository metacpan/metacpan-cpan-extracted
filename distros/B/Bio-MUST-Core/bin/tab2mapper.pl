#!/usr/bin/env perl
# PODNAME: tab2mapper.pl
# ABSTRACT: Build an id mapper from a tabular file giving annotation strings
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::Taxonomy';

die <<'EOT' if !$ARGV_taxdir && $ARGV_gi2taxid;
Missing required arguments:
    --taxdir=<dir>
EOT

# optionally build taxonomy object
my $tax;
if ($ARGV_taxdir) {
    $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
}

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $mapper = $tax->tab_mapper( $infile, {
        column   => $ARGV_column,
        gi2taxid => $ARGV_gi2taxid,
    } );

    my $outfile = change_suffix($infile, '.idm');
    $mapper->store($outfile);
}

__END__

=pod

=head1 NAME

tab2mapper.pl - Build an id mapper from a tabular file giving annotation strings

=head1 VERSION

version 0.251810

=head1 USAGE

    tab2mapper.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input tabular (TSV) files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --col[umn]=<n>

Column number providing the string to be used as the family [default: 1]. The
first column (at index 0) is the id and thus cannot be used as the family.

=for Euclid: n.type:    +int
    n.default: 1

=item --gi2taxid=<file>

Optional GI-to-taxid IDM to be used to expand GIs to modern MUST ids [default:
none]. This option requires a local mirror of the NCBI Taxonomy database.

=for Euclid: file.type: readable

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Loic MEUNIER

Loic MEUNIER <loic.meunier@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
