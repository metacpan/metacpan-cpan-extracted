package Bio::Tools::CodonOptTable;

use warnings;
use strict;

use Data::Dumper;
use Bio::Root::Root;
use Bio::PrimarySeq;
use Bio::SeqIO;
use Bio::Tools::SeqStats;
use Bio::Tools::CodonTable;
use Bio::DB::GenBank;
use GD::Graph::bars;
use Text::Textile qw(textile);
use File::Slurp;

our $VERSION = '1.05';

use vars qw(@ISA %AMINOACID %GENETIC_CODE);

@ISA = ( 'Bio::Root::Root', 'Bio::SeqIO', 'Bio::PrimarySeq' );

%GENETIC_CODE = (
    'TCA' => 'S',    # Serine
    'TCC' => 'S',    # Serine
    'TCG' => 'S',    # Serine
    'TCT' => 'S',    # Serine
    'TTC' => 'F',    # Phenylalanine
    'TTT' => 'F',    # Phenylalanine
    'TTA' => 'L',    # Leucine
    'TTG' => 'L',    # Leucine
    'TAC' => 'Y',    # Tyrosine
    'TAT' => 'Y',    # Tyrosine
    'TAA' => '*',    # Stop
    'TAG' => '*',    # Stop
    'TGC' => 'C',    # Cysteine
    'TGT' => 'C',    # Cysteine
    'TGA' => '*',    # Stop
    'TGG' => 'W',    # Tryptophan
    'CTA' => 'L',    # Leucine
    'CTC' => 'L',    # Leucine
    'CTG' => 'L',    # Leucine
    'CTT' => 'L',    # Leucine
    'CCA' => 'P',    # Proline
    'CCC' => 'P',    # Proline
    'CCG' => 'P',    # Proline
    'CCT' => 'P',    # Proline
    'CAC' => 'H',    # Histidine
    'CAT' => 'H',    # Histidine
    'CAA' => 'Q',    # Glutamine
    'CAG' => 'Q',    # Glutamine
    'CGA' => 'R',    # Arginine
    'CGC' => 'R',    # Arginine
    'CGG' => 'R',    # Arginine
    'CGT' => 'R',    # Arginine
    'ATA' => 'I',    # Isoleucine
    'ATC' => 'I',    # Isoleucine
    'ATT' => 'I',    # Isoleucine
    'ATG' => 'M',    # Methionine
    'ACA' => 'T',    # Threonine
    'ACC' => 'T',    # Threonine
    'ACG' => 'T',    # Threonine
    'ACT' => 'T',    # Threonine
    'AAC' => 'N',    # Asparagine
    'AAT' => 'N',    # Asparagine
    'AAA' => 'K',    # Lysine
    'AAG' => 'K',    # Lysine
    'AGC' => 'S',    # Serine
    'AGT' => 'S',    # Serine
    'AGA' => 'R',    # Arginine
    'AGG' => 'R',    # Arginine
    'GTA' => 'V',    # Valine
    'GTC' => 'V',    # Valine
    'GTG' => 'V',    # Valine
    'GTT' => 'V',    # Valine
    'GCA' => 'A',    # Alanine
    'GCC' => 'A',    # Alanine
    'GCG' => 'A',    # Alanine
    'GCT' => 'A',    # Alanine
    'GAC' => 'D',    # Aspartic Acid
    'GAT' => 'D',    # Aspartic Acid
    'GAA' => 'E',    # Glutamic Acid
    'GAG' => 'E',    # Glutamic Acid
    'GGA' => 'G',    # Glycine
    'GGC' => 'G',    # Glycine
    'GGG' => 'G',    # Glycine
    'GGT' => 'G',    # Glycine
);

%AMINOACID = (
    'A' => 'Ala', 'R' => 'Arg', 'N' => 'Asn', 'D' => 'Asp',
    'C' => 'Cys', 'Q' => 'Gln', 'E' => 'Glu', 'G' => 'Gly',
    'H' => 'His', 'I' => 'Ile', 'L' => 'Leu', 'K' => 'Lys',
    'M' => 'Met', 'F' => 'Phe', 'P' => 'Pro', 'S' => 'Ser',
    'T' => 'Thr', 'W' => 'Trp', 'Y' => 'Tyr', 'V' => 'Val',
    'B' => 'Asx', 'Z' => 'glx', 'X' => 'Xaa', '*' => 'Stop'
);

sub new {
    my ( $class, @args ) = @_;
    my $self = $class->SUPER::new(@args);
    my (
        $seq,  $id,       $acc,      $pid,
        $desc, $alphabet, $given_id, $is_circular,
        $file, $format,   $ncbi_id,  $genetic_code
      )
      = $self->_rearrange(
        [
            qw(
              SEQ
              DISPLAY_ID
              ACCESSION_NUMBER
              PRIMARY_ID
              DESC
              ALPHABET
              ID
              IS_CIRCULAR
              FILE
              FORMAT
              NCBI_ID
              GENETIC_CODE
              )
        ],
        @args
      );

    if ( $file && $format ) {
        ( $seq, $id, $alphabet ) = $self->_read_localfile( $file, $format );
    }
    if ($ncbi_id) {
        ( $seq, $id, $desc, $alphabet ) = $self->_read_remotefile($ncbi_id);
    }

    $self = Bio::PrimarySeq->new(
        -seq              => $seq,
        -id               => $id,
        -accession_number => $acc,
        -display_id       => $given_id,
        -desc             => $desc,
        -primary_id       => $pid,
        -alphabet         => $alphabet,
        -is_circular      => $is_circular
    );
    $self->{'genetic_code'} = $genetic_code;
    _build_codons($self);
    _map_codon_iupac($self);
    return bless $self, $class;
}

sub _build_codons {
    my $self = shift;

    my $seq_stats = Bio::Tools::SeqStats->new( -seq => $self );
    my $codons = $seq_stats->count_codons();
    my $total_codons;
    foreach my $codon ( keys %GENETIC_CODE ) {
        if ( !exists $codons->{$codon} ) {
            $codons->{$codon} = 0;
        }
    }
    $self->{'codons'}         = $codons;
    $self->{'monomers_count'} = $seq_stats->count_monomers();
    $self->{'seq_mol_weight'} = $seq_stats->get_mol_wt();
    delete $codons->{ambiguous} if($codons->{ambiguous});
    
    return 1;
}

sub _read_remotefile {
    my ( $self, $ncbi_id ) = @_;

    my ( $seq, $id, $desc, $alphabet );

    my $retrivefile = new Bio::DB::GenBank(
        -retrievaltype => 'tempfile',
        -format        => 'Fasta'
    );

    my $fetchedfile = $retrivefile->get_Stream_by_acc($ncbi_id);
    my $seq_data    = $fetchedfile->next_seq;

    $seq      = $seq_data->seq;
    $id       = $seq_data->primary_id;
    $desc     = $seq_data->desc;
    $alphabet = $seq_data->alphabet;

    return ( $seq, $id, $desc, $alphabet );
}

sub _read_localfile {
    my ( $self, $file, $format ) = @_;

    my ( $seq, $id, $alphabet );

    my $inputstream = Bio::SeqIO->new(
        -file   => $file,
        -format => $format
    );
    my $input = $inputstream->next_seq();

    $seq      = $input->seq();
    $id       = $input->id;
    $alphabet = $input->alphabet;

    return ( $seq, $id, $alphabet );
}

sub rscu_rac_table {
    my $self = shift;

    my $codons = $self->{'codons'};
    my ( @codons, $max_rscu ) = $self->_calculate_rscu();
    my $rscu_rac = $self->_calculate_rac( @codons, $max_rscu );
    my @sorted_codons_by_aa =
      sort { $a->{aa_name} cmp $b->{aa_name} } @$rscu_rac;

    return \@sorted_codons_by_aa;
}

sub _map_codon_iupac {
    my $self = shift;

    my $myCodonTable = Bio::Tools::CodonTable->new();
    my $codons       = $self->{'codons'};
    $self->{'genetic_code'} = 1 if ( !$self->{'genetic_code'} );

    $myCodonTable->id( $self->{'genetic_code'} );

    my $myCodons;

    foreach my $single_codon ( keys %$codons ) {
        my $aa_name_abri = $myCodonTable->translate($single_codon);
        my $aa_name      = $AMINOACID{$aa_name_abri};
        $myCodons->{$single_codon} = {
            'frequency' => $codons->{$single_codon},
            'aa_name'   => $aa_name,
        };
    }
    $self->{'codons'} = $myCodons;

    return 1;
}

#    Function : Calculate the RSCU(Relative Synonymous Codons Uses).
#    Note     : The formula is used in the following references.
#	 http://www.pubmedcentral.nih.gov/articlerender.fcgi?tool=pubmed&pubmedid=3547335

sub _calculate_rscu {
    my $self = shift;

    my $codons = $self->{'codons'};

    my ( $rscu, @myCodons, %rscu_max_table );

    foreach my $each_codon ( keys %$codons ) {
        my $amino = $codons->{$each_codon}->{'aa_name'};
        my $freq  = $codons->{$each_codon}->{'frequency'};
        my $count;
        my $all_freq_aa = 0;
        if ($amino) {
            foreach my $goforall ( keys %$codons ) {
                if ( $amino && ( $codons->{$goforall}->{'aa_name'} eq $amino ) )
                {
                    $all_freq_aa += $codons->{$goforall}->{'frequency'};
                    $count++;
                }
            }
            $rscu = $all_freq_aa > 0 ? $count * $freq / $all_freq_aa : 0.00;
        }
        if ( !defined( $rscu_max_table{$amino} )
            || ( $rscu_max_table{$amino} < $rscu ) )
        {
            $rscu_max_table{$amino} = $rscu;
        }
        push @myCodons,
          {
            codon         => $each_codon,
            frequency     => $freq,
            aa_name       => $amino,
            rscu          => $rscu,
            total_aa_comb => $count,
            all_fre_aa    => $all_freq_aa,
          };
    }
    return ( \@myCodons, \%rscu_max_table );
}

#    Function : Calculate the RAC (Relative Adaptiveness of a Codon).
#    Note     : The formula is used in the following references.
#	 http://www.pubmedcentral.nih.gov/articlerender.fcgi?tool=pubmed&pubmedid=3547335

sub _calculate_rac {
    my ( $self, $codons, $max_rscu ) = @_;
    my ( $rac, @myCodons );

    foreach my $each_codon (@$codons) {
        my $amino = $each_codon->{'aa_name'};
        my $rscu  = $each_codon->{'rscu'};
        if ($amino) {
            my $max = $max_rscu->{$amino};
            $rac = $max > 0 ? $rscu / $max : 0.00;
            push @myCodons,
              {
                'codon'     => $each_codon->{'codon'},
                'frequency' => $each_codon->{'frequency'},
                'aa_name'   => $amino,
                'rscu'      => sprintf( "%.2f", $rscu ),
                'rac'       => sprintf( "%.2f", $rac ),
              };
        }
    }
    return ( \@myCodons );
}

# The CAI index is defined as the geometric mean of these relative adaptiveness values.
sub calculate_cai {
    my ( $self, $rscu_rac ) = @_;

    my $count;
    my $w;
    foreach my $codon (@$rscu_rac) {
        $w += $codon->{rac};
        $count++;
    }
    my $cai = $w * ( 1 / $count );

# A CAI of 1.0 is considered to be perfect in the desired expression organism, and a
# CAI of >0.9 is regarded as very good, in terms of high gene expression level.
    return sprintf( "%.2f", $cai );
}

sub prefered_codon {
    my ( $self, $codons ) = @_;
    my $prefered_codon;
    for my $each_aa (@$codons) {
        my $aa_name   = $each_aa->{'aa_name'};
        my $rscu      = $each_aa->{'rscu'};
        my $codon     = $each_aa->{'codon'};
        my $frequency = $each_aa->{'frequency'};

        if ( !defined( $prefered_codon->{$aa_name} )
            || ( $prefered_codon->{$aa_name} < $rscu ) )
        {
            $prefered_codon->{$aa_name} = $codon;
        }
    }
    return $prefered_codon;
}

sub generate_graph {
    my ( $self, $codons, $output_file ) = @_;

    my ( @x_axis_labels, @rscu, @rac, @x_axis_values, @codons_table,
        @codon_freq );
    my $y_axis_max       = 8;
    my @category_colours = qw(red dgreen);
    my $bar_graph        = new GD::Graph::bars( 1000, 500 );

    foreach my $each_aa (@$codons) {
        if ( $each_aa->{'aa_name'} ) {
            push( @codons_table,
                $each_aa->{'aa_name'} . "(" . $each_aa->{'codon'} . ")" );
            push( @codon_freq, $each_aa->{'frequency'} );
            push( @x_axis_labels,
                    $each_aa->{'codon'} . "("
                  . $each_aa->{'frequency'} . ")" . "-"
                  . $each_aa->{'aa_name'} );
            push( @rscu, $each_aa->{'rscu'} );
            push( @rac,  $each_aa->{'rac'} );
        }
    }

    my @bar_graph_table;
    push( @bar_graph_table, \@x_axis_labels );
    push( @bar_graph_table, \@rscu );
    push( @bar_graph_table, \@rac );

    $bar_graph->set(
        title =>
'Graph Representing : Relative Synonymous Codons Uses and Relative Adaptiveness of a Codon for '
          . $self->display_id,
        y_label     => 'RSCU and RAC values',    #y-axis label
        y_max_value => $y_axis_max,              #the max value of the y-axis
        y_min_value => 0
        , #the min value of y-axis, note set below 0 if negative values are required
        y_tick_number    => 20,      #y-axis scale increment
        y_label_skip     => 1,       #label every other y-axis marker
        box_axis         => 0,       #do not draw border around graph
        line_width       => 2,       #width of lines
        legend_spacing   => 5,       #spacing between legend elements
        legend_placement => 'RC',    #put legend to the centre right of chart
        dclrs => \@category_colours
        ,    #reference to array of category colours for each line
        bgclr             => 'red',
        long_ticks        => 0,
        tick_length       => 3,
        x_labels_vertical => 1,
    ) || die "\nFailed to create line graph: $bar_graph->error()";

    $bar_graph->set_legend( 'RSCU Value', 'RAC Value' );

    my $plot = $bar_graph->plot( \@bar_graph_table );

    my $line_file = $output_file;
    open( GPH, ">$line_file" )
      || die("\nFailed to save graph to file: $line_file. $!");
    binmode(GPH);
    print GPH $plot->gif();
    close(GPH);
}

sub generate_report {
    my ( $self, $out_file ) = @_;

    my $myCodons     = $self->rscu_rac_table();
    my $sequence_id  = $self->id;
    my $genetic_code = $self->{genetic_code};
    my $monomers     = $self->{monomers_count};
    my $cai          = $self->calculate_cai($myCodons);

    my %colors = (
        'Ala'  => '#f4f4f4', 'Arg'  => '#FF99FF', 'Asn'  => '#CC99CC',
        'Asp'  => '#99FFCC', 'Cys'  => '#99CC99', 'Gln'  => '#CCFF00',
        'Glu'  => '#FF00CC', 'Gly'  => '#33FFCC', 'His'  => '#66CCFF',
        'Ile'  => '#c9c9c9', 'Leu'  => '#CCFFFF', 'Lys'  => '#FFFFCC',
        'Met'  => '#FFFF66', 'Phe'  => '#FFCC00', 'Pro'  => '#F4F4F4',
        'Ser'  => '#FF99FF', 'Thr'  => '#CC99CC', 'Trp'  => '#99FFCC',
        'Tyr'  => '#CCFF00', 'Val'  => '#33FFCC', 'Asx'  => '#6666CC',
        'glx'  => '#FF00CC', 'Xaa'  => '#cccccc', 'Stop' => '#f8f8f8'
    );

    my $codons  = "|%{color:red}CODON%|";
    my $aa_name = "|%{color:red}AMINOACID%|";
    my $counts  = "|%{color:red}COUNT%|";
    my $rscu    = "|%{color:red}RSCU%|";
    my $rac     = "|%{color:red}RAC%|";

    foreach my $each_codon (@$myCodons) {
        my $frequency  = $each_codon->{frequency} || 'O';
        my $amino_acid = $each_codon->{aa_name};
        my $codon      = $each_codon->{codon};
        my $rscu_value = $each_codon->{rscu};
        my $rac_value  = $each_codon->{rac};
        my $aa_color   = $colors{$amino_acid};

        $codons  .= "%{background:$aa_color}$codon%|";
        $aa_name .= "%{background:$aa_color}$amino_acid%|";
        $counts  .= "%{background:$aa_color}$frequency%|";
        $rscu    .= "%{background:$aa_color}$rscu_value%|";
        $rac     .= "%{background:$aa_color}$rac_value%|";
    }
    my $codon_uses = "$codons\n$aa_name\n$counts\n";
    my $rscu_uses  = "$codons\n$aa_name\n$rscu\n";
    my $rac_uses   = "$codons\n$aa_name\n$rac\n";
    my $mono_mers =
        "|%{color:red}A%|"
      . $monomers->{A} . "|\n"
      . "|%{color:red}T%|"
      . $monomers->{T} . "|\n"
      . "|%{color:red}G%|"
      . $monomers->{G} . "|\n"
      . "|%{color:red}C%|"
      . $monomers->{C} . "|\n";

    my $gc_percentage =
      ( ( $monomers->{G} + $monomers->{C} ) /
          ( $monomers->{A} + $monomers->{T} + $monomers->{G} + $monomers->{C} )
      ) * 100;
    $gc_percentage = sprintf( "%.2f", $gc_percentage );

    my $REPORT = <<EOT;
h1. Bio::Tools::CodonOptTable

%{color:green}Report for $sequence_id%

%{color:red}Codon Adaptation Index (CAI) for sequence% : $cai

%{color:red}GC percentage for sequence% : $gc_percentage%

%{color:red}GENETIC CODE USED% : $genetic_code "--more about genetic code--":http://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi

%{background:#336699;color:white;padding:5px}++**CODON USAGE**++%

$codon_uses

%{background:#336699;color:white;padding:5px}++**Relative Synonimous Codon Usage (RSCU)**++%

$rscu_uses

%{background:#336699;color:white;padding:5px}++**Relative Adaptiveness of Codon**++%

$rac_uses

%{background:#336699;color:white;padding:5px}++**Monomers**++%

$mono_mers

"Source code":http://search.cpan.org/~shardiwal/Bio-Tools-CodonOptTable-$VERSION/lib/Bio/Tools/CodonOptTable.pm is available.

EOT

    my $html = textile($REPORT);
    write_file( $out_file, $html );
}

1;    # End of Bio::Tools::CodonOptTable

__END__

=head1 NAME

Bio::Tools::CodonOptTable - A more elaborative way to check the codons usage!

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    use Bio::Tools::CodonOptTable;

    my $seqobj = Bio::Tools::CodonOptTable->new(
        -seq              => 'ATGGGGTGGGCACCATGCTGCTGTCGTGAATTTGGGCACGATGGTGTACGTGCTCGTAGCTAGGGTGGGTGGTTTG',
        -id               => 'GeneFragment-12',
        -accession_number => 'Myseq1',
        -alphabet         => 'dna',
        -is_circular      => 1,
        -genetic_code     => 1,
    );
    
    #If you wanna read from file
    my $seqobj = Bio::Tools::CodonOptTable->new(
        -file         => "contig.fasta",
        -format       => 'Fasta',
        -genetic_code => 1,
    );
    
    #If you have Accession number and want to get file from NCBI
    my $seqobj = Bio::Tools::CodonOptTable->new(
        -ncbi_id      => "J00522",
        -genetic_code => 1,
    );
    
    my $myCodons = $seqobj->rscu_rac_table();
    
    if ($myCodons) {
        foreach my $each_aa (@$myCodons) {
            print "Codon      : ", $each_aa->{'codon'},     "\t";
            print "Frequency  : ", $each_aa->{'frequency'}, "\t";
            print "AminoAcid  : ", $each_aa->{'aa_name'},   "\t";
            print "RSCU Value : ", $each_aa->{'rscu'},      "\t";       #Relative Synonymous Codons Uses
            print "RAC Value  : ", $each_aa->{'rac'},       "\t \n";    #Relative Adaptiveness of a Codon
        }
    }
    
    # To get the prefered codon list based on RSCU & RAC Values
    my $prefered_codons = $seqobj->prefered_codon($myCodons);
    while ( my ( $amino_acid, $codon ) = each(%$prefered_codons) ) {
        print "AminoAcid : $amino_acid \t Codon : $codon\n";
    }
    
    # To produce a graph between RSCU & RAC
    # Graph output file extension should be GIF, we support GIF only
    $seqobj->generate_graph( $myCodons, $outfile_name );
    
    # To Calculate Codon Adaptation Index (CAI)    
    my $gene_cai = $seqobj->calculate_cai($myCodons);

    # To Produce HTML report
    # This function will generate HTML report, outfile extension should be .html
    $seqobj->generate_report($outfile_name);

=head1 DESCRIPTION

The purpose of this module is to show codon usage.

We produces each codon frequency,
	    Relative Synonymous Codons Uses and
	    Relative Adaptiveness of a Codon table and bar graph
that will help you to calculate the Codon Adaptation Index (CAI) of a gene, to see the gene expression level.

Relative Synonymous Codons Uses(RSCU) values are the number of times a particular codon is observed, relative to the number of times
that the codon would be observed in the absence of any codon usage bias.

In the absence of any codon usage bias, the RSCU value would be 1.00.
A codon that is used less frequently than expected will have a value of less than 1.00 and vice versa for a codon that is used more frequently than expected.

Genetics Code: NCBI takes great care to ensure that the translation for each coding sequence (CDS) present in GenBank records is correct. Central to this effort is careful checking on the taxonomy of each record and assignment of the correct genetic code (shown as a /transl_table qualifier on the CDS in the flat files) for each organism and record. This page summarizes and references this work.
http://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi

The following functions are provided by this module:

=over 3

=item new()

Constructor.

=item rscu_rac_table()

To Produce RSCU and RAC table along with codon and Amino acid name.

=item prefered_codon($myCodons)

Return you prefered codons list.

=item generate_graph($myCodons,"outputfile.gif")

Produce a bar graph between RAC(Relative Adaptiveness of a Codon) & RSCU (Relative Synonymous Codons Uses).

=item calculate_cai($myCodons)

Calculate Codon Adaptation Index (CAI) for sequence.

=item generate_report($outfile_name);

To Produce HTML report, this function will generate HTML report, outfile extension should be .html
example output : L<http://search.cpan.org/src/SHARDIWAL/Bio-Tools-CodonOptTable-1.05/result.html>

=back

=head1 AUTHOR

Rakesh Kumar Shardiwal, C<< <rakesh.shardiwal at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-tools-codonopttable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Tools-CodonOptTable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Tools::CodonOptTable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Tools-CodonOptTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Tools-CodonOptTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Tools-CodonOptTable>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Tools-CodonOptTable>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Rakesh Kumar Shardiwal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
