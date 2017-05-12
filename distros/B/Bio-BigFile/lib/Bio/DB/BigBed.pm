package Bio::DB::BigBed;

#$Id$

use strict;
use warnings;
use Bio::DB::BigWig qw(binMean binVariance binStdev);
use base 'Bio::DB::BigWig';
use Carp 'croak';

# Reexport these functions from BigWig
our @EXPORT_OK = qw(binMean binVariance binStdev);

=head1 SYNOPSIS

   use Bio::DB::BigBed 'binMean','binStdev';

   my $bed  = Bio::DB::BigBed->new(-bigbed=>'ExampleData/refSeqTest.flat.bb',
				    -fasta=>'/tmp/hg19.fa');

   # pull out all the features across a portion of chromosome 1
   my @features = $bed->features(-seq_id=>'chr1',
				 -start => 11704300,
				 -end   => 11914000);

   for my $f (@features) {
     my $start = $f->start;
     my $end   = $f->end;
     my $strand = $f->strand;
     my @CDS   = $f->get_SeqFeatures('CDS');
     my @UTRs  = $f->get_SeqFeatures('five_prime_UTR','three_prime_UTR');
     my $name  = $f->display_name;
     my $score = $f->score;
     my $itemRGB = $f->attributes('RGB');
   }

   # same thing, but using a memory-efficient iterator
   my $iterator = $bed->get_seq_stream(-seq_id=>'chr1',
				       -start => 11704300,
				       -end   => 11914000);
   while (my $f = $iterator->next_seq) {
       my $start = $f->start;
       # etc
   }

   # get statistical summaries using the "bin" feature type
   my @bin = $bed->features(-type  => 'bin:10',
                            -seq_id=>'chr1',
			    -start => 11704300,
			    -end   => 11914000);
   for my $b (@bin) {
      my $start    = $b->start;
      my $end      = $b->end;
      my $coverage = $b->count;   # number of features in this bin
      my $minScore = $b->minVal;  # tally of BED score fields
      my $maxScore = $b->maxVal;
      my $meanScore = $b->meanVal;
      my $stdevScore=$b->stdev;
   }

   # same thing, but using the "summary" feature type
   my ($summary) = $bed->features(-type => 'summary',
                                  -seq_id=>'chr1',
			          -start => 11704300,
			          -end   => 11914000);
   my $bins = $summary->statistical_summary(10);  
   my $start= $summary->start;
   my $len  = $summary->length;
   my $binwidth = $len/10;
   for my $b (@$bins) {
       my $coverage   = $b->{validCount};
       my $minScore   = $b->{minVal};
       my $maxScore   = $b->{maxVal};
       my $meanScore  = binMean($b);
       my $stdevScore = binStdev($b);
       $start += $binwidth;
   }

   # getting feature counts across whole chromosomes
   my @chrom_bins = $bed->features(-type=>'bin');
   for my $summary (@chrom_summaries) {
       print $summary->seq_id,": ",$summary->count,"\n";       
   }

   # same thing, but using the "summary" type
   my @chrom_bins = $bed->features(-type=>'summary');
   for my $summary (@chrom_summaries) {
       print $summary->seq_id,": ",$summary->score->{validCount},"\n";       
   }

   # Fetching features via the "segment" interface
   my $segment  = $bed->segment('chr1',11704300 => 11914000);
   my @features = $segment->features;

=head1 DESCRIPTION

This module provides a high-level interface to Jim Kent's BigBed
files, a type of indexed genome feature database that can be randomly
accessed across the network. Please see
http://genome.ucsc.edu/FAQ/FAQformat.html for information about
creating these files.

For the low-level interface, please see Bio::DB::BigFile. BigWig files
are supported by the module Bio::DB::BigWig.

=head2 Installation

Installation requires a compiled version of Jim Kent's source tree,
including the main library, jkweb.a. Please see the README in the
Bio-BigFile distribution directory for instructions.

=head2 BioPerl SeqFeature APi

This high-level interface places a BioPerl-compatible API on top of
the native Bio::DB::BigFile interface. This API will be famiiar to
users of the Bio::DB::SeqFeature and Bio::DB::GFF modules. You use the
features() and get_seq_stream() method to query the database for
features of various types. The features returned obey the
Bio::SeqFeatureI interface, and provide methods for accessing the
feature's type, coordinates, score, and subfeatures.

The BED format does not provide a way of identifying the type of
features; however it provides for the ability to specify feature
subparts ("blocks") and a boundary between the "thick" and "thin"
portions of the feature when it is rendered on the UCSC Genome
Browser. When this module encounters a feature whose blockCount field
is greater than zero, the feature's primary_tag() method will default
to "mRNA"; otherwise it defaults to "region". In the former case,
blocks will be turned into subfeatures named "CDS", "five_prime_UTR"
and "three_prime_UTR" based on the values in the thickStart and
thickEnd columns. This heuristic may be inappropriate for BED lines
that represent non-coding features such as cDNA alignments; in such
cases, explicitly request a type of "feature" or "region" when
fetching features from the database.

The Bio::DB::BigWig API is also compatible with Bio::DasI, in which
one defines a region of the genome using the segment() method, and
then fetches features from the segment by calling its features()
method.

Please note that B<all> genomic coordinates consumed or returned by
this module are one-based closed intervals, identical to the BioPerl
standard. This is not true of the low level interfaces.

=head1 CLASS METHODS

The new() method allows you to create new instances of
Bio::DB::BigBed.

=over 4

=item B<$bw = Bio::DB::BigBed-E<gt>new(-bigbed=E<gt>$bb_path,-fasta=E<gt>$fa_path)>
=item B<$bw = Bio::DB::BigBed-E<gt>new($bw_path)>

Create a new Bio::DB::BigBed object. The B<-bigbed> argument
(required) points to the path to the indexed BigBed file you wish to
open. Alternatively, you may pass an http: or ftp: URL in order to
open a remote BigBed file. A shorter version of new() allows you to
pass a single argument consisting of the BigBed file path.

The optional B<-fasta> argument provides a path to a FASTA file
containing the genome sequence corresponding to the original BED
file. All DNA sequences come from this file, so annoying and confusing
things will happen if use the wrong genome build. The file B<must> use
chromosome/contig identifiers that match those in the BED file from
which the BigBed was built.

This module uses the BioPerl Bio::DB::Fasta libary to build an index
of the FASTA file, which means that the directory in which the FASTA
file resides must be writable by the current process the first time
you use it. Alternately, you can pass the B<-fasta> option a
previously-opened Perl object that supports a B<seq()> method. This
method takes three arguments consisting of the chromosome/contig name
and the start and end coordinates of the region of interest in 1-based
coordinates. It returns the DNA as a plain string.

    my $dna_string = $object->seq($seqid,$start,$end);

Suitable implementations include Bio::DB::SeqFeature::Store (part of
BioPerl) and Bio::DB::Sam::Fai, part of the Bio::SamTools package. You
are of course welcome to implement your own Fasta object.

When opening a remote file on an FTP or HTTP server, the directory
returned by Bio::DB::BigFile->udcGetDefaultDir must be writable
(usually '/tmp/udcCache'). The new() method will attempt to catch the
case in which this directory is not writable and instead set the cache
to /tmp/udcCache_###, where ### is the current username. For better
control over this behavior, you may set the environment variable
UDC_CACHEDIR before creating the BigWig file.


=back

=head1 OBJECT METHODS

The following are public methods available to Bio::DB::BigBed objects.

=head2 Accessors

Here are read-only accessors that give you limited access to the
contents of the BigBed object. In the method synopses given
below, B<$bigbed> is a Bio::DB::BigBed object.

=over 4

=item B<$bigfile = $bigbed-E<gt>bf>

Return the low-level Bio::DB::BigFile underlying the object.

=item B<$bigfile = $bigbed-E<gt>bb>

An alias for bf().

=item B<$fasta = $bigbed-E<gt>fa>

Return the DNA accessor (usually a Bio::DB::Fasta object) which the
object uses to fetch the sequence of the reference genome.

=back

=head2 Retrieving individual features

This section describes methods that return features corresponding
individual BED lines.

=over 4

=item B<@features = $bigbed-E<gt>features(@args)>

This method is the workhorse for retrieving various types of intervals
and summary statistics from the BigBed database. It takes a series of
named arguments in the format (-argument1 => value1, -argument2 =>
value2, ...) and returns a list of zero or more BioPerl
Bio::SeqFeatureI objects.

The following arguments are recognized:

   Argument     Description                         Default
   --------     -----------                         -------

   -seq_id      Chromosome or contig name defining  All chromosomes/contigs.
                the range of interest.

   -start       Start of the range of interest.     1

   -end         End of the range of interest        Chromosome/contig end

   -type        Type of feature to retrieve         'region'
                    (see below). 

   -iterator    Boolean, which if true, returns     undef (false)
                an iterator across the list rather
                than the list itself.

Each returned feature supports the standard Bio::SeqFeatureI methods,
including seq_id(), start(), end(), strand(), display_name(),
primary_id(), primary_tag(), score(), and get_SeqFeatures() methods.


The B<-type> argument selects the type of feature that will be
returned from the database. If no type is specified, then this module
will fetch all individual BED features and assign them a primary tag
of either "region" or "mRNA" based on the blockCount heuristic as
described earlier.

The features() (and related) calls recognize five feature types:

I<region>,I<feature>,I<mRNA>

Features retrieved using any of these types represent the raw BED
lines. There is no effective difference among the three, but they are
provided as aliases to make code more readable. "region" is preferred
for non-coding BED lines because it is a Sequence Ontology
term. "mRNA" is preferred for coding features.

I<bin:#count>

A type named "bin:" followed by an integer will divide each
chromosome/contig into the indicated number of summary bins, and
return one feature for each bin. For example, type "bin:100" will
return 100 evenly-spaced bins across each chromosome/contig. 

I<summary>

This feature type is similar to "bin" except that instead of returning
one feature for each binned interval on the genome, it returns a
single object from which you can retrieve summary statistics across
fixed-width bins in a more memory-efficient manner.

Working with the features returned by each of these types is discussed
under L</Working with features>.

The next few methods are basically convenience interfaces to the
features() method:

=item B<@features = $bigbed-E<gt>get_features_by_type($type)>

This method returns all features of the specified type from the BigBed
file without regard to their location

=item B<@features = $bigbed-E<gt>get_features_by_location($seqid,$start,$end)>

=item B<@features = $bigbed-E<gt>get_features_by_location(@named_args)>

get_features_by_location() retrieves features across a specified
interval of the genome. In its three-argument form, it accepts the ID
of the chromosome/contig, the start position and the end position of
the desired range. If start or end are omitted, they default to the
beginning and end of the chromosome respectively.

In the named-argument form, it behaves essentially identically to
features().

Typical usage to fetch 100 bins across the region of chromosome "I"
from 1Mb to 2Mb:

  my @bins = $bigbed->get_features_by_location(-seq_id => 'I',
                                               -start  => 1_000_000,
                                               -end    => 2_000_000,
                                               -type   => 'bins:100');

  foreach (@bins) {
      print $_->start,'..',$_->end,': ',$_->mean,"\n";
  }


=item B<$feature  = $bigbed-E<gt>get_feature_by_id($id)>

This method uses a BED line feature's primary ID to retrieve the
feature. Because BED files don't actually use IDs, the ID is
constructed from the feature's name (if any), chromosome coordinates,
strand and block count. This is usually, but not necessarily, unique.

The feature's primary ID can be retrieved by calling its primary_id()
method.

It is not possible (and not usually desired) to fetch features of type
"bin" or "summary" in this manner.

=item B<@features = $bigbed-E<gt>get_features_by_name($name)>

=item B<@features = $bigbed-E<gt>get_features_by_alias($name)>

=item B<@features = $bigbed-E<gt>get_features_by_attribute(%attributes)>

=item B<$feature  = $bigbed-E<gt>get_feature_by_name($name)>

These methods are supported for compatibility with like-named methods
in BioPerl's Bio::DB::SeqFeature::Store class. However they do not do
anything useful, as these are not properties of BED data.

=item B<$iterator = $bigbed-E<gt>get_seq_stream(@args)>

This method is identical to calling
$bigbed->features(-iterator=>1,@args), and returns an iterator object
that will fetch the result of the query by calling next_seq
repeatedly:

  my $i = $bigbed->get_seq_stream(-seq_id => 'I',
                                  -start  => 1_000_000,
                                  -end    => 2_000_000,
                                  -type   => 'bins:100');

  while (my $b = $i->next_seq;
      print $b->start,'..',$b->end,': ',$b->mean,"\n";
  }


=head1 Working with Features

The three types of features returned by this interface are "region"
(also known as "feature" and "mRNA" depending on context), "bin" and
"summary." The first type is used for retrieving information about
individual BED lines. The second and third are used for obtaining
statistical summary information about features spanning a region of
the genome.

=head2 The Feature type

These features, which are retrieved by specifying a type of "region",
"feature" or "mRNA", represent individual BED lines. These are also
the type of features that are returned when you do not specify a type
explicitly. They have the following useful methods:

  $feature->seq_id()       The chromosome/contig name
  $feature->start()        Start of the feature
  $feature->end()          End of the feature
  $feature->primary_tag()  Type of the feature ("region", "feature" or "mRNA")
  $feature->strand()       Feature strand (if present in the BED line)
  $feature->display_name() The feature name (if present)
  $feature->score()        Score for the feature (if present)
  $feature->primary_id()   Primary ID for the interval

In addition, features support the get_SeqFeatures() method, which is
called like this:

  @subfeats = $feature->getSeqFeatures()

This will return a list of subfeatures corresponding to the block
structure specified in the BED line. The boundaries of the blocks are
found using the features' start() and end() methods:

  for my $block (@subfeats) {
     my $start = $block->start;
     my $end   = $block->end;
     print "$start..$end";
  }

The start and end coordinates are given in chromosome coordinates.

The BioPerl API requires that features and subfeatures have primary
tags. If the main (parent) feature is of type "mRNA" (either
determined via the blocks heuristic or requested explicitly), then
subfeatures will have primary tags "CDS", "five_prime_UTR" and/or
"three_time_UTR". If the main feature has the type "region", then the
subfeatures will have primary tags "thickregion" and "thinregion",
based on where they are with respect to the thickStart and thinStart
BED fields. Similarly, a feature of type "feature" will have subparts
of type "thickfeature" and "thinfeature".

Notice that the module will split blocks in two at the thickStart and
thickEnd positions.

I<bin:#count>

A type named "bin:" followed by an integer will divide each
chromosome/contig into the indicated number of summary bins, and
return one feature for each bin. For example, type "bin:100" will
return 100 evenly-spaced bins across each chromosome/contig.

The returned bins have all the same methods as those returned by the
"region" type, except that the start() and end() methods return the
boundaries of the bin rather than any individual interval reported in
the BED file. Instead of returning a single integer value, the score()
method returns a hash of reference to statistical summary information:

  Key            Value
  ---            ---------

  validCount     Number of intervals in the bin

  maxVal         Maximum value in the bin

  minVal         Minimum value in the bin

  sumData        Sum of the intervals in the bin

  sumSquares     Sum of the squares of the intervals in the bin

In addition, the bin objects add the following convenience methods:

 $bin->count()    Same as $bin->score->{validCount}
 $bin->minVal()   Same as $bin->score->{minVal}
 $bin->maxVal()   Same as $bin->score->{maxVal}
 $bin->mean()     The mean of values in the bin (from the formula above)
 $bin->variance() The variance of values in the bin (ditto)
 $bin->stdev()    The standard deviation of values in the bin (ditto)

From these values one can determine the mean, variance and standard
deviation across one or more genomic intervals. The formulas are as
follows:

 sub mean {
    my ($sumData,$validCount) = @_;
    return $sumData/$validCount;
 }

 sub variance {
    my ($sumData,$sumSquares,$validCount) = @_;
    my $var = $sumSquares - $sumData*$sumData/$validCount;
    if ($validCount > 1) {
	$var /= $validCount-1;
    }
    return 0 if $var < 0;
    return $var;
 }

 sub stdev {
     my ($sumData,$sumSquares,$validCount) = @_;
     my $variance = variance($sumData,$sumSquares,$validCount);
     return sqrt($variance);
 }

Note that in the calculation of variance, there is a chance of getting
very small negative numbers in a tight distribution due to floating
point rounding errors. Hence the check for variance < 0. To pool bins,
simply sum the individual values.

For your convenience, this module optionally exports functions that
perform these calculations for you. Please see L</EXPORTED FUNCTIONS>
below.

If no bin count is specified, then a value of 1 is assumed. This will
return one bin spanning the entirety of the region specified. For
example:

  my ($bin) = $bigbed->features(-seq_id=>'chr1',
                                -start=>1,-end=>120_000_000,
				-type => 'bin');
  print  "Features on chr1:1..120,000,000 : ",$bin->count,"\n";

  my ($bin) = $bigbed->features(-seq_id=>'chr1',-type=>'bin');
  print "Features on chr1: ",$bin->count,"\n";

  my @bins  = $bigbed->features(-type=>'bin'); # no position specified
  for my $bin (@bins) {
     my $chr = $bin->seq_id;
     print "Features on $chr: ",$bin->count,"\n";
  }

I<summary>

This feature type is similar to "bin" except that instead of returning
one feature for each binned interval on the genome, it returns a
single object from which you can retrieve summary statistics across
fixed-width bins in a more memory-efficient manner. Call the object's
statistical_summary() method with the number of bins you need to get
an array ref of bins length. Each element of the array will be a
hashref containing the B<minVal>, B<maxVal>, B<sumData>, B<sumSquares>
and B<validCount> keys. The following code illustrates how this works:

 use Bio::DB::BigBed 'binMean','binStdev';

 my $bed    = Bio::DB::BigBed->new(-bigbed=>$path);
 my @chroms = $bed->features(-type=>'summary');

 for my $c (@chroms) {
    my $seqid   = $c->seq_id;
    my $c_start = $c->start;

    my $stats     = $c->statistical_summary(10);
    my $bin_width = $c->length/@$stats;
    my $start     = $c_start;

    for my $s (@$stats) {
        my $mean  = binMean($s);
        my $stdev = binStdev($s);
        my $end   = $start + $bin_width-1;
        print "$seqid:",int($start),'..',int($end),": $mean +/- $stdev\n";
    } continue {
       $start += $c_start;
    }
 }

The "summary" features also has a score() method which returns a
statistical summary hash across the entire region.

=cut

sub new {
    my $self = shift;
    my %args = $_[0] =~ /^-/ ? @_ : (-bigbed=>shift);
    
    my $bb_path       = $args{-bigbed}  or croak "-bigbed argument required";
    my $fa_path       = $args{-fasta};
    my $dna_accessor  = $self->new_dna_accessor($fa_path);
    
    unless ($self->is_remote($bb_path)) {
	-e $bb_path or croak "$bb_path does not exist";
	-r _  or croak "is not readable";
    } else {
	Bio::DB::BigFile->set_udc_defaults;
    }

    my $bb = Bio::DB::BigFile->bigBedFileOpen($bb_path)
	or croak "$bb_path open: $!";

    return bless {
	bw => $bb,
	fa => $dna_accessor
    },ref $self || $self;
}

sub bb     { shift->bw  }
sub bigbed { shift->bw }

sub _type_to_iterator {
    my $self = shift;
    my $type = shift;

    return 'Bio::DB::BigBed::FeatureIterator'  unless $type;

    return 'Bio::DB::BigBed::BinIterator'      if $type =~ /^bin/;
    return 'Bio::DB::BigBed::SummaryIterator'  if $type =~ /^summary/;
    return 'Bio::DB::BigBed::FeatureIterator'  if $type =~ /^(region|feature|mRNA)/;
    return 'Bio::DB::BigFile::EmptyIterator';
}

# kind of a cheat because there are no real IDs in bed/bigwig files
# we simply encode the location and other identifying information
# into the id
sub get_feature_by_id {
    my $self = shift;
    my $id   = shift;
    my ($name,$chr,$start,$end,$strand,$parts) = split ':',$id;
    my @f = $self->get_features_by_location(-seq_id=>$chr,
					    -start => $start,
					    -end   => $end,
					    -strand=> $strand);
    @f or return;
    return $f[0] if @f == 1; # yay!

    @f = grep { $_->display_name eq $name } @f    if defined $name;
    return $f[0] if @f == 1;

    @f = grep { $_->get_SeqFeatures == $parts} @f if $parts;
    return $f[0] if @f == 1;

    warn "Did not find a single feature with id $id. Returning first one.";
    return $f[0]; # lie
}



############################################################

package Bio::DB::BigBed::FeatureIterator;
use base 'Bio::DB::BigFile::IntervalIterator';
use Carp 'croak';

sub _query_method   { 'bigBedIntervalQuery'      }

sub _feature_method { 'Bio::DB::BigBed::Feature' }

sub _make_feature {
    my $self     = shift;
    my ($raw_item,$type) = @_;
    my $method   = $self->_feature_method;
    my ($name,$score,$strand,
	$thickStart,$thickEnd,$itemRGB,
	$blockCount,$blockSizes,$blockStarts)  = split /\s+/,$raw_item->rest;

    $strand = defined $strand ? $strand eq '-' ? -1 
	                                       : +1 
			      : 0;

    my @children;
    if ($blockCount && $blockCount > 0) {
	$type    ||= 'mRNA';
	my $bits = $self->split_gene_bits($type,
                                          $raw_item->start,$raw_item->end,$strand,
					  $thickStart,$thickEnd,
					  $blockCount,$blockSizes,$blockStarts);
	my $fa = $self->{bigfile}->fa;
	@children= map {
	    $method->new(-fa     => $fa,
			 -seq_id => $self->{seq_id},
			 -start  => $_->[0],
			 -end    => $_->[1],
			 -type   => $_->[2],
			 -strand => $strand);
	} @$bits;
    } else {
	$type ||= 'region';
    }
    

    my @args = (-seq_id => $self->{seq_id},
		-start  => $raw_item->start+1,
		-end    => $raw_item->end,
		-type   => $type,
		-strand => $strand,
		-fa     => $self->{bigfile}->fa);
    push @args,(-display_name => $name)             if defined $name;
    push @args,(-score        => $score)            if defined $score;
    push @args,(-attributes   => {RGB => $itemRGB}) if defined $itemRGB;
    push @args,(-segments     => \@children)        if @children;
    
    return $method->new(@args);
}


sub split_gene_bits {
    my $self = shift;
    my ($type,
        $chromStart,$chromEnd,$strand,
	$thickStart,$thickEnd,
	$numBlocks,$blockSizes,
	$blockStarts) = @_;

    my ($leftThin,$rightThin,$thick);

    if ($type eq 'mRNA') {
	$thick = 'CDS';
	($leftThin,$rightThin) = $strand >= 0 ? ('five_prime_UTR', 'three_prime_UTR') 
	                                      : ('three_prime_UTR','five_prime_UTR');
    } else {
	$thick      = "thick${type}";
	$leftThin   = $rightThin = "thin${type}";
    }

    # no internal structure, so just create UTRs and one CDS in the middle
    # remember that BED format uses 0-based indexing, hence the +1s
    unless ($blockSizes) {  
	my @bits = ([$chromStart+1,$thickStart,$leftThin],
		    [$thickStart+1,$thickEnd,$thick],
		    [$thickEnd+1,$chromEnd,$rightThin]);
	return \@bits;
    }

    # harder -- we have internal exons
    my @block_sizes  = split ',',$blockSizes;
    my @block_starts = split ',',$blockStarts;
    croak "Invalid BED file: blockSizes != blockStarts"
	unless @block_sizes == @block_starts && @block_sizes == $numBlocks;

    my @bits;
    for (my $i=0;$i<@block_starts;$i++) {
	my $start = $chromStart + $block_starts[$i];	
	my $end   = $chromStart + $block_starts[$i] + $block_sizes[$i];

	if ($start < $thickStart) {
	    if ($end < $thickStart) {          # UTR wholly contained in an exon
		push @bits,[$start+1,$end,$leftThin];
	    }
	    elsif ($end >= $thickStart) {      # UTR partially contained in an exon
		push @bits,[$start+1,$thickStart,$leftThin];
		push @bits,[$thickStart+1,$end,'CDS'];
	    }
	}

	elsif ($start < $thickEnd) {
	    if ($end <= $thickEnd) {           # CDS wholly contained in an exon
		push @bits,[$start+1,$end,'CDS'];
	    }
	    elsif ($end > $thickEnd) {         # CDS partially contained in an exon
		push @bits,[$start+1,$thickEnd,'CDS'];
		push @bits,[$thickEnd+1,$end,$rightThin];
	    }
	}

	elsif ($start > $thickEnd) {
	    push @bits,[$start+1,$end,$rightThin];  # UTR wholly contained in an exon
	}

	else {
	    croak "Programmer error when calculating UTR bounds";
	}

    }

    return \@bits;
}

############################################################

package Bio::DB::BigBed::Feature;
use base 'Bio::DB::BigWig::Feature';

sub primary_id {
    my $self = shift;
    my $chr    = $self->seq_id;
    my $start  = $self->start;
    my $end    = $self->end;
    my $strand = $self->strand||'';
    my $parts  = $self->get_SeqFeatures;
    my $name   = $self->display_name ||'';
    return join ':',$name,$chr,$start,$end,$strand,$parts;
}

############################################################

package Bio::DB::BigBed::BinIterator;
use base 'Bio::DB::BigFile::BinIterator';

sub _query_method   { 'bigBedSummaryArrayExtended' }
sub _feature_method {'Bio::DB::BigBed::Feature'    }


##################################################################
package Bio::DB::BigBed::SummaryIterator;
use base 'Bio::DB::BigFile::SummaryIterator';

sub _query_class { 'Bio::DB::BigBed::Summary' }


##################################################################
package Bio::DB::BigBed::Summary;
use base 'Bio::DB::BigWig::Summary';

sub statistical_summary {
    my $self = shift;
    my $bins = shift;
    $bins ||= 1024;

    my $bf = $self->{bf}->bf or return;
    return $bf->bigBedSummaryArrayExtended($self->seq_id,
					   $self->start-1,
					   $self->end,
					   $bins);
}

=head1 Using BigBed objects with Bio::Graphics

Recent versions of the Bio::Graphics module (see L<Bio::Graphics>)
directly supports the "summary" feature type via the wiggle_whiskers
glyph. This glyph uses different color intensities to summarize the
mean, standard deviation, min and max of bins across the range. You do
not have to specify the bin size -- the glyph will choose a bin that
is most appropriate for the width of the drawing. Typical usage is
like this:

 use Bio::DB::BigBed;
 use Bio::Graphics;

 my $path      = 'ExampleData/refSeqTest.flat.bb';
 my $bed       = Bio::DB::BigBed->new($path) or die;
 my ($summary) = $bed->features(-seq_id=>'chr1',
 			        -type=>'summary');

 my $panel     = Bio::Graphics::Panel->new(-width   => 800,
					   -segment => $summary,
					   -key_style => 'between',
					   -pad_left => 10,
					   -pad_right=>18,
    );
 # add the scalebar
 $panel->add_track($summary,
		  -glyph => 'arrow',
		  -tick  => 2,
		  -label => 'chrI',
    );

 # add the whisker
 $panel->add_track($summary,
		  -glyph => 'wiggle_whiskers',
		  -height => 80,
		  -key   => 'Summary statistics',
    );
 print $panel->png;

In addition, you can draw individual BED lines using the "region" or
"mRNA" feature types in conjunction with the glyphs of your
choice. This example displays the same BED data from chromosome 1
using the "generic", "segments" and "gene" glyphs:

 use Bio::DB::BigBed;
 use Bio::Graphics;

 my $path      = 'ExampleData/refSeqTest.flat.bb';
 my $bed       = Bio::DB::BigBed->new($path) or die;
 my $segment   = $bed->segment('chr1',11689000 => 11979000) or die;
 my @features  = $segment->features();

 my $panel     = Bio::Graphics::Panel->new(-width     => 800,
					  -segment   => $segment,
					  -key_style => 'between',
					  -pad_left  => 10,
					  -pad_right =>18,
    );

 # add the scalebar
 $panel->add_track($segment,
		  -glyph => 'arrow',
		  -tick  => 2,
		  -label => 'chrI',
    );

 # add the data as a generic glyph
 $panel->add_track(\@features,
		  -glyph => 'box',
		  -key   => 'Generic representation',
    );

 # add the data as a segments glyph
 $panel->add_track(\@features,
		  -glyph => 'segments',
		  -key   => 'Segments representation',
    );

 # add the data as a gene glyph
 $panel->add_track(\@features,
		  -glyph => 'gene',
		  -key   => 'Gene representation',
    );


 print $panel->png;

=head1 Using BigWig objects and GBrowse

The Generic Genome Browser version 2.0 (http://www.gmod.org/gbrowse)
can treat a BigWig file as a track database. A typical configuration
will look like this:

 [BigWig:database]
 db_adaptor    = Bio::DB::BigWig
 db_args       = -bigwig /var/www/data/dpy-27-variable.bw
	         -fasta  /var/www/data/elegans-ws190.fa

 [BigWigIntervals]
 feature  = summary
 database = BigWig
 glyph    = wiggle_whiskers
 min_score = -1
 max_score = +1.5
 key       = DPY-27 ChIP-chip

=head1 SEE ALSO

L<Bio::DB::BigFile>, L<Bio::Perl>, L<Bio::Graphics>, L<Bio::Graphics::Browser2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@oicr.on.caE<gt>.
E<lt>lincoln.stein@bmail.comE<gt>

Copyright (c) 2010 Ontario Institute for Cancer Research.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

1;
