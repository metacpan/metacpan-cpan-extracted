#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# This file is part of G-language Genome Analysis Environment package
#
#     Copyright (C) 2001-2009 Keio University
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# 
#   $Id: G.pm,v 1.4 2002/07/30 17:40:56 gaou Exp $
#
# G-language GAE is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
# 
# G-language GAE is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with G-language GAE -- see the file COPYING.
# If not, write to the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
# 
#END_HEADER
#
# written by Kazuharu Arakawa <gaou@sfc.keio.ac.jp> at
# G-language Project, Institute for Advanced Biosciences, Keio University.
#

package Bio::Glite;

use 5.008;
use strict;
use LWP::UserAgent;
use Data::Dumper;

require Exporter;

use base qw(Exporter);

our @EXPORT = qw(
COMGA_correlation COMGA_table_maker DoubleHelix Ew P2 RNAfold _blast _clustalw _codon_usage_table _fasta _formatdb aaui align_pathway alignment amino_counter amino_info annotate_with_glimmerM baseParingTest base_counter base_entropy base_individual_information_matrix base_information_content base_relative_entropy base_z_value blastall bui cai calc_pI cbi circular_map codon_compiler codon_counter codon_mva codon_usage cognitor complement consensus_z cor cumulative diffseq dinuc dist_in_cc dnawalk dote enc filter_cds_by_atg find_dif find_dnaAbox find_iteron find_king_of_gene find_ori_ter find_pattern find_tandem find_ter fop foreach_RNAfold foreach_tandem gcsi gcskew gcwin generateGMap genes_from_ori genome_map genome_map2 genome_map3 genomicskew gopac gpac grapher graphical_LTR_search icdi leading_strand least_squares_fit load load_kegg_api longest_ORF ma_filter ma_normalize ma_rfilter markov max maxdex mean median min mindex molecular_weight nucleotide_periodicity oligomer_counter oligomer_search oligomer_translation over_lapping_finder palindrome peptide_mass phx plasmid_map query_arm query_strand read_goa rep_ori_ter run_glimmerM seq2png seqinfo seqret set_essentiality set_gc3 set_goa set_gpac set_operon set_strand shuffleseq signature splitprintseq standard_deviation sum test_gpac to_fasta togoWS translate ttest variance view_cds w_value ws
	load
        say
        p
        puts
        readFile
        writeFile
);

our $VERSION = '0.10';

# Preloaded methods go here.

my $prefix  = 'http://rest.g-language.org/';
my $upload  = $prefix . 'upload/upl.pl';
my $ua = LWP::UserAgent->new;

sub load {
    my $this = {};

    $_[0] =  $ua->post($upload, 'Content_Type'=>'form-data', 'Content'=>['file'=>[$_[0]]])->content if(-e $_[0]);

    foreach my $line (split(/\n/, $ua->get($prefix . $_[0] . '/disclose')->content)){
	my ($feat, $key, $val) = split(/\t/, $line);
	if(length $val){
	    $this->{$feat}->{$key} = $val;
	}else{
	    $this->{$feat} = $key;
	}
    }

    foreach my $feat (keys %{$this}){
	next unless($feat =~ /FEATURE/);
        next unless ($this->{$feat}->{type} =~ /CDS|RNA/);
        
	$this->{$this->{$feat}->{gene}} = $this->{$feat} if(length $this->{$feat}->{gene});
	$this->{$this->{$feat}->{locus_tag}} = $this->{$feat} if(length $this->{$feat}->{locus_tag});
	$this->{'CDS' . $this->{$feat}->{cds}} = $this->{$feat} if($this->{$feat}->{type} eq 'CDS');
    }

    $this->{filename} = $_[0];
    print $ua->get($prefix . $_[0])->content;

    return bless $this;
}



sub AUTOLOAD{
    our $AUTOLOAD;
    my $gb = shift;
    my @args = @_;
    my @method = split(/::/, $AUTOLOAD);

    my $i = 0;
    my (@new_args);
    while(defined $args[$i]){
        if (substr($args[$i], 0, 1) eq '-' && substr($args[$i], 1, 1) !~ /[0-9]/){
            if(!defined($args[$i + 1]) || substr($args[$i + 1], 0, 1) eq '-' && substr($args[$i + 1], 1, 1) !~ /[0-9]/){
                push(@new_args, substr($args[$i], 1) . '=' . 1);
                $i ++;
            }else{
                push(@new_args, substr($args[$i], 1) . '=' . $args[$i + 1]);
                $i += 2;
            }
	}else{
	    push(@new_args, $args[$i]);
	    $i ++;
        }
    }

    my $url = $prefix . join('/', $gb->{filename}, $method[-1], @new_args);
    my $request = HTTP::Request->new('GET', $url);
    my $res = $ua->simple_request($request);
    my $result;

    if($res->is_redirect){
	$result = $res->header('Location');
    }else{
	if($res->is_success){
	    $result = $ua->get($url)->content;
	}else{
	    if($res->status_line =~ /404/){
		die("no such function $method[-1]");
	    }else{
		die($res->status_line);
	    }
	}
    }
    
    if($result =~ /\n +/ || $result =~ /http/){
	print $result, "\n";
    }else{
	return split(/\n/, $result);
    }
}

sub DESTROY{}

sub p{ print Dumper(@_), "\n"; }
sub puts{ print @_, "\n"; }
sub say{ print join(',', @_), "\n"; }

sub readFile{
    my $file = shift;
    my $chomp = shift || 0;
    my @result;

    open(FILE, $file) || die($!);
    while(<FILE>){
        chomp if($chomp);
        push(@result, $_);
    }
    close(FILE);

    if(wantarray()){
        return @result;
    }else{
        return join('', @result);
    }
}


sub writeFile{
    my $data = shift;
    my $file = shift || "out.txt";

    open(OUT, '>' . $file) || die($!);
    print OUT $data;
    close(OUT);

    return $file;
}



1;

__END__

=head1 NAME

Bio::Glite - G-language Genome Analysis Environment REST service interface module

=head1 SYNOPSIS

 use Bio::Glite;                 # Imports G-language GAE module 
   
 $gb = load("ecoli.gbk");        # Creates G's instance as $gb 
                                 # At the same time, read in ecoli.gbk. 
                                 # Read the annotation and sequence 
                                 # information 
                                 # See DESCRIPTION for details
   
 $gb->seq_info();                # Prints the basic sequence information.

 $find_ori_ter($gb);             # Give $gb as the first argument to 
                                 # most of the analysis functions


=head1 DESCRIPTION

 The G-language GAE fully supports most sequence databases.

 Stored annotation information:

 LOCUS  
         $gb->{LOCUS}->{id}              -accession number 
         $gb->{LOCUS}->{length}          -length of sequence  
         $gb->{LOCUS}->{nucleotide}      -type of sequence ex. DNA, RNA  
         $gb->{LOCUS}->{circular}        -1 when the genome is circular.
                                          otherwise 0
         $gb->{LOCUS}->{type}            -type of species ex. BCT, CON  
         $gb->{LOCUS}->{date}            -date of accession 

 HEADER  
         $gb->{HEADER}  

 COMMENT  
         $gb->{COMMENT}  

 FEATURE  
         Each FEATURE is numbered(FEATURE1 .. FEATURE1172), and is a 
         hash structure that contains all the keys of Genbank.   
         In other words,  in most cases, FEATURE$i's hash at least 
         contains informations listed below: 
         $gb->{FEATURE$i}->{start}  
         $gb->{FEATURE$i}->{end}  
         $gb->{FEATURE$i}->{direction}
         $gb->{FEATURE$i}->{join}
         $gb->{FEATURE$i}->{note}  
         $gb->{FEATURE$i}->{type}        -CDS,gene,RNA,etc.
         $gb->{FEATURE$i}->{feature}     -same as $i

         To analyze each FEATURE, write: 

         foreach my $feature ($gb->feature()){
               print $gb->{$feature}->{type}, "\n";
         }  

         In the same manner, to analyze all CDS, write:  
 
         foreach my $cds ($gb->cds()){
               print $gb->{$cds}->{gene}, "\n";
         }

         Feature or gene information can also be accessed with CDS numbers:
         $gb->{CDS$i}->{start}

         or with locus_tags or gene names (for CDS, tRNA, and rRNA)
         $gb->{thrL}->{start}
         $gb->{b0001}->{start}

 BASE COUNT  
         $gb->{BASE_COUNT}  

 SEQ  
         $gb->seq()              -sequence data following "ORIGIN" 

=head1 Supported methods of G-language Genome Analysis Environment

=cut

=head2 $gb = new G("genome file")

     Name: $gb = new G("genome file")   -   create a G instance

     see "help load" for more information.

=cut

=head2 load

     Name: load   -   load genome databases

         This funciton is used to load genome databases into memory.
         First option is the filename of the database. Default format is
         the GenBank database. Database format is guessed from the extensions.
         (eg. .gbk => GenBank, .fasta => FASTA, .embl => EMBL)

         There are also several sample bacterial genomes included in the system.
         $eco   = load("ecoli"); # Escherichia coli K12 MG1655 - NC_000913
         $bsub  = load("bsub");  # Bacillus subtilis           - NC_000964
         $mgen  = load("mgen");  # Mycoplasma genitalium       - NC_000908
         $cyano = load("cyano"); # Synechococcus sp.           - NC_005070
         $pyro  = load("pyro");  # Pyrococcus furiosus         - NC_003413

         Data can be automatically donwloaded from public databases using
         Uniform Sequence Address (USA) keys.
         http://emboss.sourceforge.net/docs/themes/UniformSequenceAddress.html
         Currently supported database keys are: 
            swiss, genbank, genpept, embl, refseq 
         eg. 
            $gb = load("embl:xlrhodop");
            $gb = load("genbank:AY063336")
            $gb = load("swiss:ROA1_HUMAN")

         Second option specifies detailed actions.

           'no msg'                  suprresses all STDOUT messages printed 
                                     when loading a database, including the
                                     copyright info and sequence statistics.

           'no cache'                suppresses the use of database caching.
                                     By default, databases are cached for
                                     optimized performance. (since v.1.6.4)

           'force cache'             rebuilds database cache.

           'multiple locus'          this option merges multiple loci in the 
                                     database and load the information
                                     as G-language instance.

           'bioperl'                 this option creates a G instance from 
                                     a bioperl object. 
                                     eg. $bp = $bp->next_seq();       # bioperl
                                         $gb = load($bp, "bioperl"); # G

           'longest ORF annotation'  this option predicts genes with longest ORF
                                     algorithm (longest frame from start codon
                                     to stop codon, with more than 17 amino 
                                     acids) and annotates the sequence.

           'glimmer annotation'      this option predicts genes using glimmer2,
                                     a gene prediction software for microbial
                                     genomes available from TIGR.
                                     http://www.tigr.org/softlab/
                                     Local installation of glimmer2 and setting
                                     of PATH environment value is required.

               - following options require bioperl installation -

           'Fasta'              this option loads a Fasta format database.
           'EMBL'               this option loads a EMBL  format database.
           'swiss'              this option loads a swiss format database.
           'SCF'                this option loads a SCF   format database.
           'PIR'                this option loads a PIR   format database.
           'GCG'                this option loads a GCG   format database.
           'raw'                this option loads a raw   format database.
           'ace'                this option loads a ace   format database.
           'net GenBank'        this option loads a GenBank format database from 
                                NCBI database. With this option, the first value to 
                                pass to load() function will be the accession 
                                number of the database.

=cut

=head2 $gb->output()

   Name: $gb->output()   -   output the G instance data to file

   Description:
         Given a filename and an option, outputs the G-language data object 
         to the specified file in a flat-file database of a given format.
         The options are the same as those of new().  Default format is 'GenBank'.

         eg. $gb->output("my_genome.embl", "EMBL");
             $gb->output("my_genome.gbk"); # with GenBank you can ommit the option.

=cut

=head2 complement

   Name: complement   -   get the complementary nucleotide sequence

   Description:
         Given a sequence, returns its complement.

         eg. complement('atgc');  # returns 'gcat'

=cut

=head2 method_list

   Name: method_list   -   get the list of availabel G-language GAE functions

   Description:
         Returns an array of available method names. 
         When 1 is supplied as an argument, returns an array of API-related
         method names.

         eg. @methods = method_list();     # contains more than 100 analysis functions
             @APImethods = method_list(1); # contains around 50 API-related methods.

=cut

=head2 translate

   Name: translate   -   translate a nucleotide sequence to amino acid sequence

   Description:

         Given a sequence, returns its translated sequence.
         Regular codon table is used.
         eg. translate('ctggtg');  # returns 'LV'

=cut

=head2 $gb->seq()

   Name: $gb->seq()   -   get the sequence data from G instance

   Description:
         Returns the entire sequence. Same as $gb->{SEQ};

=cut

=head2 $gb->seq_info()

   Name: $gb->seq_info()   -   display basic statistics about the data

   Description:
         Prints the basic information of the genome to STDOUT.

=cut

=head2 $gb->find()

   Name: $gb->find()   -   search through the genome data object with keywords

   Description:
         This method provides powerful means to search within the G-language genome
         data object with keywords. Given a set of keywords, this method returns
         the list of feature IDs corresponding to the search query. In G-language Shell,
         search results are also directly printed out (you can specify -print=>1 option
         in API mode to print within your program).

         eg. @features = $gb->find('RNA', 'tyrosine');    # multiple keywords are allowed.

         Keywords can be specific to each of the feature attributes:

         eg. $gb->find(-type=>'CDS', -product=>'metabolism', 'subunit');

         Regular expressions are allowed for keywords:

         eg. $gb->find(-type=>'CDS', -EC_number=>'^2.7.');

=cut

=head2 $gb->getseq()

   Name: $gb->getseq()   -   get nucleotide sequence of the given positions (Perl coordinates)

   Description:
         Given the start and end positions (starting from 0 as in Perl),
         returns the sequence specified.

         eg. $gb->getseq(1,3); # returns the 2nd, 3rd, and 4th nucleotides.

   Options:
       -circular   when the first position is larger than the second position,
                   retrieves the sequece spanning across the end of the circular
                   chromosome. (ex: $gb->getseq(4639670, 5, -circular))

=cut

=head2 $gb->get_gbkseq()

   Name: $gb->get_gbkseq()   -   get nucleotide sequence of the given positions (GenBank coordinates)

   Description:
         Given the start and end positions (starting from 1 as in 
         Genbank), returns the sequence specified.

         eg. $gb->get_gbkseq(1,3); # returns the 1st, 2nd, and 3rd nucleotides.

   Options:
       -circular   when the first position is larger than the second position,
                   retrieves the sequece spanning across the end of the circular
                   chromosome. (ex: $gb->getseq(4639670, 5, -circular))

=cut

=head2 $gb->get_cdsseq()

   Name: $gb->get_cdsseq()   -   get nucleotide sequence of the given CDS

   Description:
         Given a CDS ID, returns the CDS sequence. 
         'complement' is properly parsed.

         eg. $gb->get_cdsseq('CDS1'); # returns the 'CDS1' sequence.

=cut

=head2 $gb->get_geneseq()

   Name: $gb->get_geneseq()   -   get nucleotide sequence of the given gene

   Description:
         Given a CDS ID, returns the CDS sequence, or the exon sequence
         If introns are present.
         'complement' is properly parsed, and introns are spliced out.

         eg. $gb->get_geneseq('CDS1'); # returns the 'CDS1' sequence or exon.

=cut

=head2 $gb->feature()

   Name: $gb->feature()   -   get a list of feature IDs

   Description:
         Returns the array of all feature IDs.
         Features are ignored when $gb->{$feature}->{on} is 0.

         eg.
           foreach ($gb->feature()){
               $gb->get_cdsseq($_);
           }
           #prints all feature sequences.

         Optionally, feature type can be supplied to return only the
         specifies features.

         eg. $gb->feature("tRNA"); # returns feature IDs only for tRNAs

         Option of "all" always returns all features regardless of the
         value of $gb->{$feature}->{on}.

=cut

=head2 $gb->cds()

   Name: $gb->cds()   -   get a list of CDS IDs

   Description:
         Returns the array of all feature IDs of CDS.
         Features are ignored when $gb->{FEATURE$i}->{on} OR
         $gb->{CDS$i}->{on} is 0.

         !CAUTION! the object name is actually the FEATURE ID,
         to enable access to all feature values. However, most of the
         time you do not need to be aware of this difference.

         eg.
           foreach ($gb->cds()){
               $gb->get_geneseq($_);
           }
           #prints all gene sequences.

         Option of "all" always returns all features regardless of the
         value of $gb->{$feature}->{on}.

=cut

=head2 $gb->tRNA()

   Name: $gb->tRNA()   -   get a list of feature IDs of tRNAs

   Description:
         Returns the array of all feature IDs of tRNAs.

=cut

=head2 $gb->rRNA()

   Name: $gb->rRNA()   -   get a list of feature IDs of rRNAs

   Description:
         Returns the array of all feature IDs of rRNAs.

=cut

=head2 $gb->intergenic()

   Name: $gb->intergenic()   -   get a list of IDs of intergenic regions

   Description:
         Returns the array of all IDs of intergenic regions. 
         Here "intergenic region" is defined as the region in a genome
         between coding and stable RNA genes. 

=cut

=head2 $gb->gene()

   Name: $gb->gene()   -   get a list of feature IDs of genes

   Description:
         Returns the array of all feature IDs of genes.

=cut

=head2 $gb->disable_pseudogenes()

   Name: $gb->disable_pseudogenes()   -   turns all pseudogenes off

   Description:
         Turns off all pseudogenes by setting $genome->{$feature}->{on}
         to 0 when $genome->{$feature}->{pseudo} is true.

=cut

=head2 $gb->next_feature()

   Name: $gb->next_feature()   -   get the next feature ID

   Description:
         Given a feature ID, returns the ID of the next feature.
         Second argument can be used to specify the type of the 
         next feature.

         eg. $gb->next_feature(FEATURE1234); # returns 'FEATURE1235'
             $gb->next_feature(FEATURE1234, 'tRNA'); 
             # returns next feature ID whose type is 'tRNA'

=cut

=head2 $gb->next_cds()

   Name: $gb->next_cds()   -   get the feature ID of next CDS

   Description:
         Given a feature ID, returns the ID of the next cds.
         This is same as $gb->next_feature($featureID, 'CDS');

=cut

=head2 $gb->previous_feature()

   Name: $gb->previous_feature()   -   get the previous feature ID

   Description:
         Given a feature ID, returns the ID of the previous feature.
         Second argument can be used to specify the type of the 
         next feature.

         eg. $gb->previous_feature(FEATURE1234); # returns 'FEATURE1233'
             $gb->previous_feature(FEATURE1234, 'tRNA'); 
             # returns previous feature ID whose type is 'tRNA'

=cut

=head2 $gb->previous_cds()

   Name: $gb->previous_cds()   -   get the feature ID of previous CDS

   Description:
         Given a feature ID, returns the ID of the previous cds.
         This is same as $gb->previous_feature($featureID, 'CDS');

=cut




=head2 $gb->startcodon()

   Name: $gb->startcodon()   -   get the start codon of the given CDS

   Description:
         Given a CDS ID, returns the start codon.

         eg. $gb->startcodon("FEATURE$i"); # returns 'atg'

=cut

=head2 $gb->stopcodon()

   Name: $gb->stopcodon()   -   get the stop codon of the given CDS

   Description:
         Given a CDS ID, returns the stop codon.

         eg. $gb->stopcodon("FEATURE$i"); # returns 'tag'

=cut

=head2 $gb->before_startcodon()

   Name: $gb->before_startcodon()   -   get the upstream sequence of the given CDS

   Description:
         Given a CDS ID and length, returns the sequence upstream of 
         start codon.

         eg. $gb->before_startcodon('CDS1', 100); 
             # returns 100 bp sequence upstream of the start codon of 'CDS1'.

   Options:
         Second argument specifying the length of sequence to retrieve is
         optional. (default: 100).

=cut

=head2 $gb->after_startcodon()

   Name: $gb->after_startcodon()   -   get the sequence downstream of start codon of the given CDS

   Description:
         Given a CDS ID and length, returns the sequence downstream of 
         start codon.

         eg. $gb->after_startcodon('CDS1', 100); 
             # returns 100 bp sequence downstream of the start codon of 'CDS1'.

   Options:
         Second argument specifying the length of sequence to retrieve is
         optional. (default: 100).

=cut

=head2 $gb->before_stopcodon()

   Name: $gb->before_stopcodon()   -   get the sequence upstream of stop codon of the given CDS

   Description:
         Given a CDS ID and length, returns the sequence upstream of 
         stop codon.

         eg. $gb->before_stopcodon('CDS1', 100); 
             # returns 100 bp sequence upstream of the stop codon of 'CDS1'.

   Options:
         Second argument specifying the length of sequence to retrieve is
         optional. (default: 100).

=cut

=head2 $gb->after_stopcodon()

   Name: $gb->after_stopcodon()   -   get the downstream sequence of the given CDS

   Description:
         Given a CDS ID and length, returns the sequence downstream of 
         stop codon.

         eg. $gb->after_stopcodon('CDS1', 100); 
             # returns 100 bp sequence downstream of the stop codon of 'CDS1'.

   Options:
         Second argument specifying the length of sequence to retrieve is
         optional. (default: 100).

=cut


=head2 $gb->around_startcodon()

   Name: $gb->around_startcodon()   -   get the sequence around the startcodon of the given CDS

   Description:
         Given a CDS ID, lengths before startcodon and after start codon, 
         returns the sequence around of start codon.

         eg. $gb->around_startcodon('FEATURE5239', 100, 100); 
             # returns 100 bp sequence before and after the start codon of 'CDS1',
             # including the start codon itself

   Options:
         Optional Fourth argument containing a string "without" returns only the sequence
         before and after the start codon, and without the stat codon itself.
         eg. $gb->around_startcodon('FEATURE5239', 100, 100, "without");

=cut



=head2 $gb->around_stopcodon()

   Name: $gb->around_stopcodon()   -   get the sequence around the stopcodon of the given CDS

   Description:
         Given a CDS ID, lengths before stopcodon and after stop codon, 
         returns the sequence around of stop codon.

         eg. $gb->around_stopcodon('FEATURE5239', 100, 100); 
             # returns 100 bp sequence before and after the stop codon of 'CDS1',
             # including the stop codon itself

   Options:
         Optional Fourth argument containing a string "without" returns only the sequence
         before and after the stop codon, and without the stat codon itself.
         eg. $gb->around_stopcodon('FEATURE5239', 100, 100, "without");

=cut



=head2 $gb->get_exon()

   Name: $gb->get_exon()   -   get a list of exon sequences of the given CDS

   Description:
         Given a CDS ID, returns the exon sequence.
         'complement' is properly parsed, and introns are spliced out.

         eg. $gb->get_exon('CDS1'); returns the 'CDS1' exon.

=cut


=head2 $gb->get_intron()

   Name: $gb->intron()   -   get a list of intron sequences of the given CDS

   Description:
         Given a CDS ID, returns the intron sequences as array of 
         sequences.

         eg. $gb->get_intron('CDS1'); 
             # returns ($1st_intron, $2nd_intron,..)

=cut

=head2 $gb->pos2feature()

   Name: $gb->pos2feature()   -   get a feature ID from position

   Description:
         Given a GenBank position (sequence starting from position 1) 
         returns the feature ID (ex. FEATURE123) of the feature at
         the given position. If multiple features exist for the given
         position, the first feature to appear is returned. Returns 
         NULL if no feature exists.

         When two positions are specified, all features within given 
         range is returned as an array of feature IDs.

=cut

=head2 $gb->pos2gene()

   Name: $gb->pos2gene()   -   get a feature ID of CDS from position

   Description:
         Given a GenBank position (sequence starting from position 1) 
         returns the feature ID (ex. FEATURE123) of the gene at
         the given position. If multiple genes exists for the given
         position, the first gene to appear is returned. Returns 
         NULL if no gene exists.

         When two positions are specified, all genes within given 
         range is returned as an array of feature IDs.

=cut

=head2 $gb->gene2id()

   Name: $gb->gene2id()   -   get a feature ID from canonical gene name

   Description:
         Given a GenBank gene name, returns the feature ID (ex. FEATURE123). 
         Returns NULL if no gene exists.

=cut

=head2 $gb->next_locus()

   Name: $gb->next_locus()   -   read the next locus and update the G instance

   Description:
         Reads the next locus.
         the G instance is then updated.

         eg. 
           do{
  
           }while($gb->next_locus());
           #  Enables multiple loci analysis.        

=cut

=head2 $gb->clone()

   Name: $gb->clone()   -   create a copy of the G instance

   Description:
         Returns cloned G instance, which is a new G instance with
         identical data. 

=cut

=head2 $gb->del_key()

   Name: $gb->del_key()   -   delete a data object from G instance

   Description:
         Given a object, deletes it from the G instance structure
         eg. $gb->del_key('FEATURE1'); # deletes 'FEATURE1' hash

=cut

=head2 $gb->reverse_strand()

   Name: $gb->reverse_strand()   -   create a G instance on complementary DNA strand

   Description:
         Returns a G instance for the complementary DNA strand. 
         All information, including the sequence and feature annotations
         is switched to reflect that of the complementary DNA strand. 
         In other words, gene order, direction of genes (either direct or 
         complement), and positions are reversed. 

   Usage: 
      $new = $gb->reverse_strand();

=cut

=head2 $gb->relocate_origin()

   Name: $gb->relocate_origin()   -   create a G instance starting at given position

   Description:
         Returns a G instance starting at given position, assuming circular
         chromosome. All information, including the sequence and feature 
         annotations are moved. Note that the given position is Perl position
         and NOT GenBank position. GenBank position -1 equals Perl position.

   Usage:
      $new = $gb->relocate_origin($position);

      This method would probably be most useful in conjunction with
      find_ori_ter(), to create a G instance starting from the 
      origin of replication, as follows:

        ($ori, $ter) = find_ori_ter($gb);
        $new = $gb->relocate_origin($ori);

      Several of related methods can be concatenated. For example, 
      to create a GenBank file of complementary DNA strand starting
      from the origin of replication, do the following:

        $gb->reverse_strand()->relocate_origin($ori)->output("out.gbk");

=cut


=head1 AUTHOR

Kazuharu Arakawa, gaou@sfc.keio.ac.jp

=cut

1;

