#!/usr/bin/env perl
# PODNAME: tag-loc-ids.pl
# ABSTRACT: Compute seq id organelle tags based on sequence identity
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Path::Class qw(file);
use Smart::Comments;
use Getopt::Euclid qw(:vars);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils 'change_suffix';
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::FastParsers::Blast::Table';


REPORT:
for my $infile (@ARGV_infiles) {

    my $fasta = $infile;
       $fasta =~ s/$_//xms for @ARGV_in_strip;
       $fasta = change_suffix($fasta, $ARGV_fasta_suffix);
    my $ali   = Ali->load($fasta);

    my %new_id_for;
    my $org = join "_", (split "_", $infile)[0,1];

    my $report_file = file($infile);
    my $report = Table->new( file => $report_file );

    HIT:
    # loop through first hits for each query
    while (my $hit = $report->next_query) {

        # consider only hits over percent_id threshold
        next HIT if $hit->percent_identity < $ARGV_percent_id;

        # strict check of length unless percent_id filter only
        unless ($ARGV_pid_only) {
            next HIT
                unless ( $hit->query_end - $hit->query_start )
                    == (   $hit->hit_end -   $hit->hit_start )
            ;
        }

        my $seq_id = SeqId->new( full_id => $hit->hit_id );
        my $query_id = $hit->query_id;
           $query_id =~ s/_/ /xms;

        ### hitid: $hit->hit_id
        ### fullid: $seq_id->full_id
        ### tag: $seq_id->tag
        my ($tag) = $hit->hit_id =~ m/([a-z]{2,3})\#/xms;
        $new_id_for{$query_id}
            = ($seq_id->tag ? $seq_id->tag : $tag) . '#' . $query_id;
    }

    my @curr_ids = keys %new_id_for;
    my @new_ids  = map { $new_id_for{$_} } @curr_ids;

    my $idfile = change_suffix( $report_file, $ARGV_pruning
        ? "$ARGV_loc.idl" : "$ARGV_loc.idm" );
    if  ($ARGV_pruning) {
        ### Writing idl file...
        my $idl = IdList->new(ids => \@curr_ids);
        $idl->store($idfile);
        next REPORT;
        ### Done!
    }
    else {
        ### Writing idm file...
        my $idm = IdMapper->new(
            long_ids => \@new_ids,
            abbr_ids => \@curr_ids
        );
        $idm->store($idfile);
        next REPORT;
        ### Done!
    }
}

__END__

=pod

=head1 NAME

tag-loc-ids.pl - Compute seq id organelle tags based on sequence identity

=head1 VERSION

version 0.210170

=head1 USAGE

    tag-loc-ids.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input FASTA files [repeatable argument].

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

=item --percent-id=<n>

Min percentage identity to consider a hit.

=for Euclid: n.type: n
    n.default: 99

=item --fasta[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

=item --pruning

If activated produce a list of sequence IDs for pruning of alignment ('.idl'
file). By default, output is a '.idm' file for renaming sequences in original
fasta/ali file.

=item --loc=<loc>

for Euclid:
    loc.type: str

Cellular compartment you want to work with.

=item --count=<str>

Prot count per plastome file.

for Euclid:
    str.type: str

=item --pid_only

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Mick VAN VLIERBERGHE

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
