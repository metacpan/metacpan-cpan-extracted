#!/usr/bin/env perl
# PODNAME: cdhit-tax-filter.pl
# ABSTRACT:
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(:filenames secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::Taxonomy';
use Bio::MUST::Drivers;
use aliased 'Bio::MUST::Drivers::CdHit';

# check for conditionally required arguments
die <<'EOT' if !$ARGV_taxdir && $ARGV_filter;
Missing required arguments:
    --taxdir=<dir>
EOT

# optionally build taxonomy and filter objects
my $filter;
if ($ARGV_filter) {
    my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
    $filter = $tax->tax_filter($ARGV_filter);
    ### Active filter: $filter->all_specs
}

my $method;
   $method = 'all' if $ARGV_keep_all;

for my $infile (@ARGV_infiles){

    ### Processing: $infile
    my $ali = Ali->load($infile);

    ### Running CD-HIT...
    my $cdh = CdHit->new(
              seqs => $infile,
        cdhit_args => { -c => $ARGV_identity }
    );
    my $new_cluster_for;

    # 1. taxonomic mode (main goal)
    if ($ARGV_filter) {
        my $list = ( $filter->tax_list($ali) )->ids;
        $new_cluster_for = $cdh->filter_clusters($list, $method);
    }

    # 2. simple CDHIT mode
    # TODO: move logic to lib?
    else {
        my @representatives = $cdh->all_cluster_names;
        my @members         = $cdh->all_cluster_seq_ids;
        $new_cluster_for->{$_} = {
            representatives => [ shift @representatives ],
            members         => [ map { $_->full_id } @{ shift @members } ],
        } for 1..$cdh->count_representatives;
    }

    if ($ARGV_store_id_mapper) {
        my $idmfile = change_suffix(
            insert_suffix($infile, $ARGV_out_suffix), '.idm'
        );
        dump_mapper($idmfile, $new_cluster_for);
    }

    my @want_ids = map {
        @{ $new_cluster_for->{$_}{representatives} }
    } keys %$new_cluster_for;

    $ali->apply_list( IdList->new( ids => \@want_ids ) );
    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali ->store($outfile);
}

sub dump_mapper {
    my $outfile         = shift;
    my $new_cluster_for = shift;

    open my $out, '>', $outfile;

    CLUSTER:
    for my $cluster ( keys %{$new_cluster_for} ) {
        my $reprs   = $new_cluster_for->{$cluster}{representatives};
        my $members = $new_cluster_for->{$cluster}{members        };

        next CLUSTER unless @{$members};

        my $n = @{$members} + 1;
        say {$out} join "\t", $_ . "#C$cluster" . "N$n#", $_ for @{$reprs};
    }

    return;
}

__END__

=pod

=head1 NAME

cdhit-tax-filter.pl - # CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

=head1 VERSION

version 0.252830

=head1 NAME

cdhit-tax-filter.pl -

=head1 VERSION

version

=head1 USAGE

    cdhit-tax-filter.pl --filter=<file> --taxdir=<dir> <infiles>
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --identity=<n>

=for Euclid: n.type: 0+number
    n.default: 1.0

=item --filter=<file>

Path to an IDL file specifying the taxonomic filter to be applied. This
requires a local mirror of the NCBI Taxonomy database [default: none].

In a tax_filter, wanted taxa are to be prefixed by a '+' symbol, whereas
unwanted taxa are to be prefixed by a '-' symbol. Wanted and unwanted taxa are
linked by logical ORs.

An example IDL file follows:

    -Viridiplantae
    -Opisthokonta
    +Ascomycota
    +Oomycota

=for Euclid: file.type: readable

=item --keep-all

Extract all the sequences of the specified taxa from the clusters instead of
using only the longest (when possible) [default: no].

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --store-id-mapper

Store the IDM file corresponding to each output file [default: no].

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

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
