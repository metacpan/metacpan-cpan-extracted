#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use Bio::AlignIO;
use Data::Dumper;

my $help;
my $informat  = 'fasta';
my $outformat = 'clustalw';
my $id;
my $shorten_id_from_end;
GetOptions(
    'id=s'                  => \$id,
    'to=s'                  => \$outformat,
    'from=s'                => \$informat,
    'help'                  => \$help,
    'shorten-id-from-end|s' => \$shorten_id_from_end,
) or die "there is a problems with parsing the options. $!";

pod2usage( -verbose => 2, -noperldoc => 1 ) if $help;

#get filenames from arguments
my ( $in_file, $out_file ) = @ARGV;
#die if input file doesn't exist
die ">>$in_file<< is no file"
    unless ( -f $in_file );
#die if output file is not vaild
die ">>$out_file<< is not a valid output file name"
    unless ( $out_file && $out_file ne '' );

#open input file
my $aln_in_fh = Bio::AlignIO->new(
    -format => $informat,
    -file   => $in_file
);

#open output file
my $aln_out_fh = Bio::AlignIO->new(
    -format => $outformat,
    -file   => '>' . $out_file
);

no warnings 'redefine';

sub Bio::SimpleAlign::set_displayname_flat {
    my $self = shift;
    my ( $nse, $seq );

    foreach $seq ( $self->each_seq() ) {
        $nse = $seq->get_nse();
        $self->displayname( $nse, substr( $seq->id, -10 ) );
    }
    return 1;
}

#write from input to output
while ( my $align_object = $aln_in_fh->next_aln ) {

    $align_object->id($id)
        if ($id);
    if ($shorten_id_from_end) {
        $align_object->set_displayname_flat;
        foreach my $seq ( $align_object->each_seq ) {
            if ( length( $seq->display_id ) > 10 ) {
                my $nse = $seq->get_nse();
            }
        }
    }
    $aln_out_fh->write_aln($align_object);
}

__END__

=head1 NAME

aln2aln - convert different alignment formats to another alignment format

=head1 SYNOPSIS

    perl aln2aln.pl [OPTIONS] [--help] <input_alignment_file> <file_in_other_format>

=head1 DESCRIPTION

Takes <input_alignment_file> and converts it to <file_in_other_format>
On default, it assumes 'fasta' as input format, but you can
use the --from option to make sure that aln2aln uses a different
format. Same applies to --to

Some formats have a limitation on identifier length (>30 characters or so), so
check this first, if strange problems occur.
    
=head1 OPTIONS

=over 4

=item B<< --shorten-id-from-end >>

If the sequence ids from the input alignment are too long, take the last 10 characters of the id.

=item B<--from <FORMAT>> and B<--to <FORMAT>>

Assume one of the following alignment input formats:

FORMATS:

    fasta       FASTA format
    pfam        pfam format
    selex       selex (hmmer) format
    stockholm   stockholm format
    prodom      prodom (protein domain) format
    msf         msf (GCG) format
    mase        mase (seaview) format
    bl2seq      Bl2seq Blast output
    nexus       Swofford et al NEXUS format
    pfam        Pfam sequence alignment format
    phylip      Felsenstein's PHYLIP format
    clustalw    ClustalW format

=back

=head1 SEE ALSO

L<Bio::AlignIO>

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
