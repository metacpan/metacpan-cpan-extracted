package Bio::DB::BigWig;

#$Id$

use strict;
use warnings;
use Bio::DB::BigFile;
use Bio::DB::BigFile::Constants;
use Bio::DB::BigFile::Iterators;
use File::Spec;
use Carp 'croak';

use base 'Exporter';
our @EXPORT_OK = qw(binMean binVariance binStdev);

# $Id$
# high level interface to BigWig files

=head1 SYNOPSIS

   use Bio::DB::BigWig 'binMean';

   my $wig  = Bio::DB::BigWig->new(-bigwig=>'ExampleData/dpy-27-variable.bw',
				    -fasta=>'/tmp/elegans.fa');

   # Fetch individual intervals
   # fetch the individual data points in the wig file over a region of interest
   my @points = $wig->features(-seq_id=>'I',-start=>100,-end=>1000);
   for my $p (@points) {
      my $start = $p->start;
      my $end   = $p->end;
      my $val   = $p->score;
      print "$start..$end : $val\n";
   }

   # same thing but using a "segment" object
   my $segment = $wig->segment('I',100=>1000);
   for my $p ($segment->features) {
      my $start = $p->start;
      # etc.
   }

   # Same thing, but using an iterator.
   my $iterator = $wig->get_seq_stream(-seq_id=>'I',-start=>100,-end=>1000);
   while (my $p = $iterator->next_seq) {
      my $start = $p->start;
      # etc.
   }

   # dump whole thing out as a BEDGraph file
   my $iterator = $wig->get_seq_stream();
   while (my $p = $iterator->next_seq) {
      my $seqid = $p->seq_id;
      my $start = $p->start;
      my $end   = $p->end;
      my $val   = $p->score;
      print join("\t",$seqid,$start,$end,$val),"\n";
   }

   # Statistical summaries using "bin" feature type
   # Fetch 10 intervals across region 5M=>6M on chromosome I
   my @bins = $wig->features(-seq_id=>'I',
                             -start  => 5_000_000,
                             -end    => 6_000_000,
                             -type=>'bin:10');
   for my $b (@bins) {
      my $start = $b->start;
      my $end   = $b->end;
      print "$start..$end, mean = ",$b->mean,"\n";
   }

   # same thing, but get 100 intervals across all of chromosome I
   my @bins = $wig->features(-seq_id=>'I',
                             -type=>'bin:100');
   for my $b (@bins) {
      my $start = $b->start;
      # etc.
   }

   # same thing, but get summaries across entirety of each chromosome
   my @bins = $wig->features(-type=>'bin'); # same as "bin:1"
   for my $b (@bins) {
       my $chrom = $b->seq_id;
       print "$chrom mean val: ",$b->mean,"\n";
   }
   
   # alternative interface using the memory-efficient "summary" feature type

   # get statistical summaries across all chromosomes
   my @summary = $wig->features(-type=>'summary');# one for each chromosome
   for my $s (@summary) {
      print "chromosome ",$s->seq_id,"\n";
      my $stats = $s->statistical_summary(10);   # 10 evenly-spaced bins as an array ref
      print "\tmax  = ",$stats->[0]{maxVal},"\n";
      print "\tmean = ",binMean($stats->[0]),"\n";
   }

   # get statistical summary across just chromosome I
   my ($summary) = $wig->features(-seq_id=>'I',-type=>'summary'); 
   my $stats = $summary->statistical_summary(10);   # 10 evenly-spaced bins as an array ref
   print "\tmax  = ",$stats->[0]{maxVal},"\n";
   print "\tmean = ",binMean($stats->[0]),"\n";
   
   # get statistical summary across a subregion
   ($summary) = $wig->features(-seq_id => 'I',
                               -start  => 5_000_000,
                               -end    => 6_000_000,
                               -type   => 'summary');
   $stats = $summary->statistical_summary(10); # 10 bins across region

   # get an iterator across the intervals covered by a summary
   my $i = $summary->get_seq_stream();
   while (my $interval = $i->next_seq) {
      print $interval->start,'..',$interval->end,': ',$interval->score,'\n";
   }

=head1 DESCRIPTION

This module provides a high-level interface to Jim Kent's BigWig
files, a type of indexed genome feature database that can be randomly
accessed across the network. Please see
http://genome.ucsc.edu/FAQ/FAQformat.html for information about
creating these files.

For the low-level interface, please see Bio::DB::BigFile. BigBed files
are supported by the module Bio::DB::BigBed.

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


Please note that B<all> genomic coordinates consumed or returned by
this module are one-based closed intervals, identical to the BioPerl
standard. This is not true of the low level interfaces.


=head1 CLASS METHODS

The new() method allows you to create new instances of
Bio::DB::BigWig.

=over 4

=item B<$bw = Bio::DB::BigWig-E<gt>new(-bigwig=E<gt>$bw_path,-fasta=E<gt>$fa_path)>
=item B<$bw = Bio::DB::BigWig-E<gt>new($bw_path)>

Create a new Bio::DB::BigWig object. The B<-bigwig> argument
(required) points to the path to the indexed .bw file you wish to
open. Alternatively, you may pass an http: or ftp: URL in order to
open a remote BigWig file. A shorter version of new() allows you to
pass a single argument consisting of the BigWig file path.

The optional B<-fasta> argument provides a path to a FASTA file
containing the genome sequence corresponding to the original WIG
file. All DNA sequences come from this file, so annoying and confusing
things will happen if use the wrong genome build. The file B<must> use
chromosome/contig identifiers that match those in the WIG file from
which the BigWig was built. 

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

=cut

sub new {
    my $self = shift;
    my %args = $_[0] =~ /^-/ ? @_ : (-bigwig=>shift);

    my $bw_path       = $args{-bigwig}||$args{-dsn}  or croak "-bigwig argument required";
    my $fa_path       = $args{-fasta};
    my $dna_accessor  = $self->new_dna_accessor($fa_path);
    
    if ($self->is_remote($bw_path)) {
	Bio::DB::BigFile->set_udc_defaults;
    }
    else {
	-e $bw_path or croak "$bw_path does not exist";
	-r _  or croak "is not readable";
    }

    my $bw = Bio::DB::BigFile->bigWigFileOpen($bw_path)
	or croak "$bw_path open: $!";

    return bless {
	bw => $bw,
	fa => $dna_accessor
    },ref $self || $self;
}

=head1 OBJECT METHODS

The following are public methods available to Bio::DB::BigWig objects.

=head2 Accessors

Here are read-only accessors that give you limited access to the
contents of the BigWig object. In the method synopses given
below, B<$bigwig> is a Bio::DB::BigWig object.

=over 4

=item B<$bigfile = $bigwig-E<gt>bf>

Return the low-level Bio::DB::BigFile underlying the object.

=cut

sub bf { shift->{bw} }

=item B<$bigfile = $bigwig-E<gt>bigwig>

An alias for bf().

=cut

sub bigwig { shift->bw }

sub bw { shift->{bw} }

=item B<$fasta = $bigwig-E<gt>fa>

Return the DNA accessor (usually a Bio::DB::Fasta object) which the
object uses to fetch the sequence of the reference genome.

=cut

sub fa { shift->{fa} }

=back

=cut

sub segment {
    my $self = shift;
    my ($seqid,$start,$end) = @_;

    if ($_[0] =~ /^-/) {
	my %args = @_;
	$seqid = $args{-seq_id} || $args{-name};
	$start = $args{-start};
	$end   = $args{-stop}    || $args{-end};
    } else {
	($seqid,$start,$end) = @_;
    }

    my $size = $self->bw->chromSize($seqid) or return;

    $start ||= 1;
    $end   ||= $size-1;

    return unless $start >= 1 && $start < $size;
    return unless $end   >= 1 && $end   < $size;

    return Bio::DB::BigFile::Segment->new(-bf    => $self,
					  -seq_id=> $seqid,
					  -start => $start,
					  -end   => $end);
}

=head2 Retrieving intervals and summary statistics

This section describes methods that return lists of intervals and
summary statistics from the BigWig object. Most of the methods are
oriented towards retrieving information about the distribution of
values in the WIG file. Summary information typically consists of the
following fields:

  Key                Value
  ---            ---------

  validCount     Number of intervals in the bin

  maxVal         Maximum value in the bin

  minVal         Minimum value in the bin

  sumData        Sum of the intervals in the bin

  sumSquares     Sum of the squares of the intervals in the bin

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

For your convenience, Bio::DB::BigWig optionally exports functions
that perform these calculations for you. Please see L</EXPORTED
FUNCTIONS> below.

The following methods allow you to query the BigWig file:

=over 4

=item B<@features = $bigwig-E<gt>features(@args)>

This method is the workhorse for retrieving various types of intervals
and summary statistics from the BigWig database. It takes a series of
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
primary_id(), primary_tag() and score(). Typically, the seq_id, start,
end and score are of the greatest interest.

Three different feature types are accepted, each one with slightly
different properties:

I<region>,I<interval>

Features retrieved using either of these types will represent the raw
intervals and values present in the original WIG file (the two are
equivalent, "region" is preferred because it is a Sequence Ontology
term, but "interval" is probably more natural). Note that this
operation may consume a lot of memory and be processor-intensive. It
is almost always better to create an iterator using get_seq_stream().

These features have the following useful methods:

  $feature->seq_id()     The chromosome/contig name
  $feature->start()      Start of the interval
  $feature->end()        End of the interval
  $feature->score()      Score for the interval
  $feature->primary_id() Primary ID for the interval

Due to floating point precision issues at the BigWig C level, the
scores may be very slightly different from the originals.

Here is a simple script that dumps out the contents of chromosome I in
BedGraph format:

 use Bio::DB::BigWig;

  my $wig  = Bio::DB::BigWig->new(-bigwig=>$path);
  my @features = $wig->features(-seq_id=>'I',-type=>'region');
  for my $p (@features) {
     my $seqid = $p->seq_id;
     my $start = $p->start;
     my $end   = $p->end;
     my $val   = $p->score;
     print join("\t",$seqid,$start,$end,$val),"\n";
 }

I<bin:#count>

A type named "bin:" followed by an integer will divide each
chromosome/contig into the indicated number of summary bins, and
return one feature for each bin. For example, type "bin:100" will
return 100 evenly-spaced bins across each chromosome/contig. 

The returned bin features have the same methods as those returned by
the "region"/"interval" types, except that the start() and end()
methods return the boundaries of the bin rather than any individual
interval reported in the WIG file. Instead of returning a single
value, the score() method returns a hash of statistical summary
information containing the keys B<validCount>, B<maxVal>, B<minVal>,
B<sumData> and B<sumSquares> as described earlier.

In addition, the bin objects add the following convenience methods:

 $bin->count()    Same as $bin->score->{validCount}
 $bin->minVal()   Same as $bin->score->{minVal}
 $bin->maxVal()   Same as $bin->score->{maxVal}
 $bin->mean()     The mean of values in the bin (from the formula above)
 $bin->variance() The variance of values in the bin (ditto)
 $bin->stdev()    The standard deviation of values in the bin (ditto)

If no number is specified (i.e. you search for type "bin"), then an
interval of "1" is assumed. You will receive one bin spanning each
chromosome/contig.

I<summary>

This feature type is similar to "bin" except that instead of returning
one feature for each binned interval on the genome, it returns a
single object from which you can retrieve summary statistics across
fixed-width bins in a more memory-efficient manner. Call the object's
statistical_summary() method with the number of bins you need to get
an array ref of bins length. Each element of the array will be a
hashref containing the B<minVal>, B<maxVal>, B<sumData>, B<sumSquares>
and B<validCount> keys. The following code illustrates how this works:

 use Bio::DB::BigWig 'binMean','binStdev';
 my $wig = Bio::DB::BigWig->new(-bigwig=>$path);
 my @chroms = $wig->features(-type=>'summary');

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

"summary" features have a score() method which returns a statistical
summary hash across the entire region. They also have a
get_seq_stream() method which returns a feature iterator across the
region they cover.

 my $summary = $c->score;

To get the mean and stdev across the entire chromosome containing the
summary feature, call its chr_mean() and chr_stdev() methods:

 my $mean  = $c->chr_mean;
 my $stdev = $c->chr_stdev;

To get the global mean and stdev across the entire genome containing
the summary feature, call its global_mean() and global_stdev() methods:

 my $mean  = $c->global_mean;
 my $stdev = $c->global_stdev;

The summary object's chr_stats() and global_stats() methods return a
hashref containing the statistical summary for the chromosome and
genome respectively.

 my $stats  = $c->global_stats;
 my $stats = $c->chr_stats;

To receive the underlying bigwig database from a summary feature, you
may call its bigwig() method:

  my $bigfile = $c->bigwig;

If the argument -iterator=>1 is present, then instead of returning an
array of features, the method call will return a single object that
has a next_seq() method. Each time next_seq() is called it will return
a retrieved feature in a memory-efficient manner. Here is a script
that will dump the entire BigWig file out in BedGraph format:

 use Bio::DB::BigWig;

  my $wig  = Bio::DB::BigWig->new(-bigwig=>$path);
  my $iterator = $wig->features(-iterator=>1,-type=>'region');
  while (my $p $iterator->next_seq) {
     my $seqid = $p->seq_id;
     my $start = $p->start;
     my $end   = $p->end;
     my $val   = $p->score;
     print join("\t",$seqid,$start,$end,$val),"\n";
 }

The next few methods are basically convenience interfaces to the
features() method:

=item B<@features = $bigwig-E<gt>get_features_by_type($type)>

This method returns all features of the specified type from the BigWig
file without regard to their location

=item B<@features = $bigwig-E<gt>get_features_by_location($seqid,$start,$end)>

=item B<@features = $bigwig-E<gt>get_features_by_location(@named_args)>

get_features_by_location() retrieves features across a specified
interval of the genome. In its three-argument form, it accepts the ID
of the chromosome/contig, the start position and the end position of
the desired range. If start or end are omitted, they default to the
beginning and end of the chromosome respectively.

In the named-argument form, it behaves essentially identically to
features().

Typical usage to fetch 100 bins across the region of chromosome "I"
from 1Mb to 2Mb:

  my @bins = $bigwig->get_features_by_location(-seq_id => 'I',
                                               -start  => 1_000_000,
                                               -end    => 2_000_000,
                                               -type   => 'bins:100');

  foreach (@bins) {
      print $_->start,'..',$_->end,': ',$_->mean,"\n";
  }


=item B<@features = $bigwig-E<gt>get_features_by_name($name)>

=item B<@features = $bigwig-E<gt>get_features_by_alias($name)>

=item B<@features = $bigwig-E<gt>get_features_by_attribute(%attributes)>

=item B<$feature  = $bigwig-E<gt>get_feature_by_id($id)>

=item B<$feature  = $bigwig-E<gt>get_feature_by_name($name)>

These methods are supported for compatibility with like-named methods
in BioPerl's Bio::DB::SeqFeature::Store class. However they do not do
anything useful, as these are not properties of WIG data.

=item B<$iterator = $bigwig-E<gt>get_seq_stream(@args)>

This method is identical to calling
$bigwig->features(-iterator=>1,@args), and returns an iterator object
that will fetch the result of the query by calling next_seq
repeatedly:

  my $i = $bigwig->get_seq_stream(-seq_id => 'I',
                                  -start  => 1_000_000,
                                  -end    => 2_000_000,
                                  -type   => 'bins:100');

  while (my $b = $i->next_seq;
      print $b->start,'..',$b->end,': ',$b->mean,"\n";
  }

=cut

sub get_features_by_type {
    my $self = shift;
    return $self->features(-type=>\@_);
}

sub get_features_by_location {
    my $self = shift;
    if ($_[0] =~ /^-/) { # named argument form
	return $self->features(@_);
    } else {
	my ($seqid,$start,$end) = @_;
	return $self->features(-seq_id => $seqid,
			       -start  => $start,
			       -end    => $end);
    }

}
# kind of a cheat because there are no real IDs in bed/bigwig files
# we simply encode the location and other identifying information
# into the id
sub get_feature_by_id {
    my $self = shift;
    my $id   = shift;
    my ($chr,$start,$end,$type) = split ':',$id;
    my @f = $self->get_features_by_location(-seq_id=>$chr,
					    -start => $start,
					    -end   => $end,
					    -type  => $type || undef
	);
    @f or return;
    return $f[0] if @f == 1; # yay!
    
    @f = grep {$_->start == $start && $_->end == $end} @f;
    return $f[0] if @f == 1;

    warn "Did not find a single feature with id $id. Returning first one.";
    return $f[0]; # lie
}

sub get_features_by_name  { return; } # this doesn't do anything
sub get_feature_by_name   { return; } # this doesn't do anything
sub get_features_by_alias { return; } # this doesn't do anything
sub get_features_by_attribute { return; } # this doesn't do anything

sub features {
    my $self    = shift;
    my %options;

    if (@_ && $_[0] !~ /^-/) {
	%options = (-type => $_[0]);
    } else {
	%options = @_;
    }

    my $iterator = $self->get_seq_stream(%options);
    return $iterator if $options{-iterator};
    return unless $iterator;
    
    my @result;
    while (my $f = $iterator->next_seq) {
	push @result,$f;
    }

    return @result;
}

sub get_seq_stream {
    my $self    = shift;
    my %options;

    if (@_ && $_[0] !~ /^-/) {
	%options = (-type => $_[0]);
    } else {
	%options = @_;
    }
    $options{-type} ||= $options{-types};

    if (ref $options{-type} && ref $options{-type} eq 'ARRAY') {
	warn "This module only supports fetching one feature type at a time. Picking first one."
	    if @{$options{-type}}>1;
	$options{-type} = $options{-type}->[0];
    }

    my $iterator_class = $self->_type_to_iterator($options{-type});
    
    # first deal with the problem of the user not specifying the chromosome
    return Bio::DB::BigFile::GlobalIterator->new($self,$iterator_class,\%options)
	unless $options{-seq_id};

    # now deal with the problem of the user not specifying either the
    # start or the end position
    my $size           = $self->bw->chromSize($options{-seq_id});
    $options{-start} ||= 1;   # that was easy!
    $options{-end}   ||= $size;

    # clip
    $options{-start} = 1     if $options{-start} < 1;
    $options{-end}   = $size if $options{-end}   > $size;
    
    return unless $options{-seq_id} && $options{-start} && $options{-end};

    return $iterator_class->new($self,\%options);
}

=item B<@seq_ids = $bw->seq_ids>

This method returns the names of all the chromosomes/contigs known to
the BigWig file.

=cut

sub seq_ids {
    my $self = shift;
    my $bw   = $self->bw;
    my $chrom_list = $bw->chromList;
    my @list;
    for (my $c=$chrom_list->head;$c;$c=$c->next) {
	push @list,$c->name;
    }
    return @list;
}

=item B<$length = $bw->length($seqid)>

Given the ID of a chromosome or contig, this returns its size in
bases. If the sequence ID is unknown, returns undef.

=cut

sub length {
    my $self = shift;
    my $seqid = shift;
    return $self->bw->chromSize($seqid);
}

sub _type_to_iterator {
    my $self = shift;
    my $type = shift;

    return 'Bio::DB::BigWig::IntervalIterator' unless $type;

    return 'Bio::DB::BigWig::BinIterator'      if $type =~ /^bin/;
    return 'Bio::DB::BigWig::SummaryIterator'  if $type =~ /^summary/;
    return 'Bio::DB::BigWig::IntervalIterator' if $type =~ /^(region|interval)/;
    return 'Bio::DB::BigFile::EmptyIterator';
}

=item B<$dna = $bw-E<gt>seq($seqid,$start,$end)>

Given a sequence ID and a range, this method returns the DNA bases (a
string, not a Bio::PrimarySeq object) if a DNA accessor or FASTA path
was defined at object creation time. Otherwise it will return undef.

=back

=cut

sub seq {
    my $self = shift;
    my ($seqid,$start,$end) = @_;
    my $fa   = $self->fa or return;
    return $fa->can('seq')            ? $fa->seq($seqid,$start,$end)
          :$fa->can('fetch_sequence') ? $fa->fetch_sequence($seqid,$start,$end)
          : undef;
}

sub is_remote {
    my $self = shift;
    my $path = shift;
    return $path =~ /^(http|ftp):/;
}

sub new_dna_accessor {
    my $self     = shift;
    my $accessor = shift;

    return unless $accessor;

    if (-e $accessor) {  # a file, assume it is a fasta file
	eval "require Bio::DB::Fasta" unless Bio::DB::Fasta->can('new');
	my $a = Bio::DB::Fasta->new($accessor)
	    or croak "Can't open FASTA file $accessor: $!";
	return $a;
    }

    if (ref $accessor && $self->can_do_seq($accessor)) {
	return $accessor;  # already built
    }

    return;
}

sub can_do_seq {
    my $self = shift;
    my $obj  = shift;
    return 
	UNIVERSAL::can($obj,'seq') ||
	UNIVERSAL::can($obj,'fetch_sequence');
}

=head2 Segments

Several "segment" methods allows you to define a range on the genome
and retrieve information across it.

=over 4

=item B<$segment = $bigwig-E<gt>segment($seqid,$start,$end)>
=item B<$segment = $bigwig-E<gt>segment(-seq_id=>$seqid, -start=E<gt>$start, -end=E<gt>$end)>

The segment() method returns a Bio::DB::BigFile::Segment object. It
has two forms. In the positional form, pass it the sequence ID
(chromosome or contig name), and start and end positions of the
range. Start defaults to 1 if missing or undef, and end defaults to
the full length of the chromosome/contig. The named form takes the
named arguments B<-seq_id>, B<-start> and B<-end>.

=back

Once a segment is defined, the following methods are available:

=over 4

=item B<@features = $segment-E<gt>features([$type])>

Return a list of features that overlap the segment. You may us this to
retrieve statistical summary information about the segment or
subranges of the segment, or to return the underlying WIG values. The
optional $type argument allows you to select what type of information
to retrieve. Options are B<bin> to retrieve statistical information as
a series of bin features spanning the segment, B<summary> to retrieve
a single summary object describing the entire segment, or B<region> to
retrieve the intervals defined in the original WIG file (the type
named B<interval> is an alias for 'region'). If no type is given, then
B<region> is assumed. See the discussion of the
Bio::DB::WigFile->features() method for a more in-depth discussion of
how this works.

=item B<$iterator = $segment-E<gt>get_seq_stream([$type])>

This method returns an iterator across the segment. Call the
iterator's next_seq() method repeatedly to step through the features
contained within the segment in a memory-efficient manner:

  my $iterator = $segment->get_seq_stream('region');
  while (my $f = $iterator->next_seq) {
      print $f->score,"\n";
  }

=item B<$seqid = $segment-E<gt>seq_id>

=item B<$start = $segment-E<gt>start>

=item B<$end   = $segment-E<gt>end>

These methods return the chromosome/contig name, start and end of the
segment range, respectively.

=back

=head1 EXPORTED FUNCTIONS

These convenience functions are optionally exportable. You must
explicitly request them, as in: 

 use Bio::DB::BigWig qw(binMean binVariance, binStdev);

=over 4

=item B<$mean = binMean($feature-E<gt>score)>

Return the mean of a summary statistics hash, such as those returned
by the bin and summary feature score() method. This will also suitable
for the elements of the array ref returned by summary features'
statistical_summary() method.

=cut

sub binMean {
    my $score = shift;
    return unless $score->{validCount};
    $score->{sumData}/$score->{validCount};
}

=item B<$variance = binVariance($feature-E<gt>score)>

As above, but returns the variance of the summary statistics.

=cut

sub binVariance {
    my $score = shift;
    my $var = $score->{sumSquares} - $score->{sumData}**2/$score->{validCount};
    if ($score->{validCount} > 1) {
	$var /= $score->{validCount}-1;
    }
    return 0 if $var < 0;
    return $var;

}

=item B<$sd = binStdev($feature-E<gt>score)>

As above, but returns the standard deviaton of the summary statistics.

=back

=cut

sub binStdev {
    my $score = shift;
    return sqrt(binVariance($score));
}

############################################################

package Bio::DB::BigWig::IntervalIterator;

use base 'Bio::DB::BigFile::IntervalIterator';

sub _query_method { 'bigWigIntervalQuery' }

sub _feature_method {'Bio::DB::BigWig::Feature'}

############################################################

package Bio::DB::BigWig::BinIterator;
use base 'Bio::DB::BigFile::BinIterator';
use Carp 'croak';

sub _query_method   { 'bigWigSummaryArrayExtended' }
sub _feature_method { 'Bio::DB::BigWig::Bin'       }


##################################################################
package Bio::DB::BigWig::SummaryIterator;

use base 'Bio::DB::BigFile::SummaryIterator';

sub _query_class { 'Bio::DB::BigWig::Summary' }


##################################################################

package Bio::DB::BigWig::Feature;
use base 'Bio::SeqFeature::Lite';

sub new {
    my $self = shift;
    my $feat = $self->SUPER::new(@_);
    my %args = @_;
    $feat->{fa} = $args{-fa} if $args{-fa};
    return $feat;
}

sub dna {
    my $self = shift;
    my $fa     = $self->{fa} or return 'N' x $self->length;
    my $seq_id = $self->seq_id;
    my $start  = $self->start;
    my $end    = $self->end;
    return $fa->can('seq')            ? $fa->seq($seq_id,$start,$end)
          :$fa->can('fetch_sequence') ? $fa->fetch_sequence($seq_id,$start,$end)
          :'N' x $self->length;
}

sub seq {
    my $self = shift;
    return Bio::PrimarySeq->new(-seq=>$self->dna);
}

sub primary_id {
    my $self = shift;
    my $id   = join (':',$self->seq_id,$self->start,$self->end,$self->type);
    if (my $dbid = $self->attributes('dbid')) {
	return "$dbid:$id";
    } else {
	return $id;
    }
}

sub id { shift->primary_id }

sub set_attributes {
    my $self = shift;
    $self->{attributes} = shift;
}

# allow attributes to be used in place of some methods
sub _faux_method {
    my $self   = shift;
    my $method = shift;
    my $m      = "SUPER::$method";
    return $self->attributes($method) || eval {$self->$m};
}
sub display_name { shift->_faux_method('display_name') }
sub method       { shift->_faux_method('method')       }
sub source       { shift->_faux_method('source')       }
sub type         { 
    my $self = shift;
    my $type = $self->attributes('type');
    return $type if $type;
    return join(':',$self->method,$self->source) if $self->method && $self->source;
    return $self->SUPER::type;
}

##################################################################
package Bio::DB::BigWig::Bin;

use base 'Bio::DB::BigWig::Feature';

sub minVal {
    shift->score->{minVal};
}

sub maxVal {
    shift->score->{maxVal};
}

sub mean {
    Bio::DB::BigWig::binMean(shift->score);
}

sub count { shift->score->{validCount} }

sub variance {
    Bio::DB::BigWig::binVariance(shift->score);
}

sub stdev {
    Bio::DB::BigWig::binStdev(shift->score);
}




##################################################################

package Bio::DB::BigWig::Summary;
use base 'Bio::DB::BigWig::Feature';

sub new {
    my $self = shift;
    my $feat = $self->SUPER::new(@_);
    my %args = @_;
    $feat->{bf} = $args{-bf} if $args{-bf};
    return $feat;
}

sub statistical_summary {
    my $self = shift;
    my $bins = shift;
    $bins ||= 1;

    my $bf = $self->{bf}->bf or return;
    return $bf->bigWigSummaryArrayExtended($self->seq_id,
					   $self->start-1,
					   $self->end,
					   $bins);
}

sub gff3_string {
    my $self = shift;
    {
	no warnings;
	local *Bio::DB::BigWig::Summary::score = \&mean_score;
	my $string  = $self->SUPER::gff3_string(@_);
	chomp($string);
	my $stats   = $self->statistical_summary(1000);
	my @coverage = map {sprintf('%.4f',Bio::DB::BigWig::binMean($_))} @$stats;
	$string .= ";coverage=".join('%2C',@coverage);
	$string .= "\n";
	return $string;
    }
}

sub score {
    my $self = shift;
    my $arry = $self->statistical_summary(1);
    return $arry->[0];
}


sub mean_score { 
    my $self = shift;
    my $arry = $self->statistical_summary(1);
    my $score = $arry->[0];
    my $count = $score->{validCount} or return 0;
    return sprintf('%0.4f',$score->{sumData}/$count);
};

sub get_seq_stream {
    my $self = shift;
    return $self->{bf}->get_seq_stream(-seq_id=>$self->seq_id,
				       -start =>$self->start,
				       -end   =>$self->end);
}

sub bigwig { shift->{bf}->bf }

sub chr_mean {
    my $self  = shift;
    my $chr_stats = $self->chr_stats or return;
    return Bio::DB::BigWig::binMean($chr_stats);
}

sub chr_stdev {
    my $self  = shift;
    my $chr_stats = $self->chr_stats or return;
    return Bio::DB::BigWig::binStdev($chr_stats);
}

sub chr_stats {
    my $self = shift;
    return $self->{_chr_stats} if exists $self->{_chr_stats};
    my $seqid = $self->seq_id;
    my $f   = $self->{bf}->segment(-seq_id=>$seqid) or return;
    my $s   = $self->bigwig->bigWigSummaryArrayExtended($f->seq_id,
							$f->start-1,
							$f->end,
							1);
    return $self->{_chr_stats} = $s->[0];
}

sub global_mean {
    my $self = shift;
    return Bio::DB::BigWig::binMean($self->global_stats);
}

sub global_stdev {
    my $self = shift;
    return Bio::DB::BigWig::binStdev($self->global_stats);
}

sub global_stats {
    my $self = shift;
    return $self->{_global_stats} if exists $self->{_global_stats};
    my @c     = $self->{bf}->seq_ids;
    my %stats;
    for my $seqid (@c) {
	my $start = 0;
	my $end   = $self->bigwig->chromSize($seqid);
	my $s   = $self->bigwig->bigWigSummaryArrayExtended($seqid,
							    $start,
							    $end,
							    1) or next;
	$s = $s->[0];
	$stats{validCount} += $s->{validCount};
	$stats{sumData}    += $s->{sumData};
	$stats{sumSquares} += $s->{sumSquares};
	$stats{minVal}      = _min($stats{minVal},$s->{minVal});
	$stats{maxVal}      = _max($stats{maxVal},$s->{maxVal});
    }
    return $self->{_chr_stats} = \%stats;
}

sub _min {
    return $_[0] unless defined $_[1];
    return $_[1] unless defined $_[0];
    return $_[0] < $_[1] ? $_[0] : $_[1];
}
sub _max {
    return $_[0] unless defined $_[1];
    return $_[1] unless defined $_[0];
    return $_[0] < $_[1] ? $_[1] : $_[0];
}

##################################################################
package Bio::DB::BigFile::Segment;
use base 'Bio::DB::BigWig::Summary';

sub features {
    my $self = shift;
    return $self->{bf}->features(-seq_id => $self->seq_id,
				 -start  => $self->start,
				 -end    => $self->end,
				 -type   => $_[0]);
}

sub get_seq_stream {
    my $self = shift;
    return $self->{bf}->get_seq_stream(-seq_id => $self->seq_id,
				       -start  => $self->start,
				       -end    => $self->end,
				       -type   => $_[0]);
}

=head1 Using BigWig objects with Bio::Graphics

Recent versions of the Bio::Graphics module (see L<Bio::Graphics>)
directly supports the "summary" feature type via the wiggle_whiskers
glyph. This glyph uses different color intensities to summarize the
mean, standard deviation, min and max of bins across the range. You do
not have to specify the bin size -- the glyph will choose a bin that
is most appropriate for the width of the drawing. Typical usage is
like this:

 use Bio::DB::BigWig;
 use Bio::Graphics;

 my $path      = 'ExampleData/dpy-27-variable.bw';
 my $wig       = Bio::DB::BigWig->new($path) or die;
 my ($summary) = $wig->features(-seq_id=>'I',
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
