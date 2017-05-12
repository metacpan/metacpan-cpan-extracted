package Bio::DB::USeq;

our $VERSION = '0.23';

=head1 NAME

Bio::DB::USeq - Read USeq archive database files

=head1 SYNOPSIS
    
    use Bio::DB::USeq;
    my $useq = Bio::DB::USeq->new('file.useq') or 
        die "unable to open file.useq!\n";
    
    # sequence IDs
    my @seq_ids = $useq->seq_ids;
    my $length = $useq->length($chr); # approximate, not exact
    
    ### Retrieving features
    # all features or observations across chromosome I
    my @features = $useq->features(
        -seq_id     => 'chrI',
        -type       => 'region', 
    );
    
    # same thing using a simple form
    # use an array of (chromosome, start, stop, strand)
    my @features = $useq->features('chrI');
    
    # same thing with a memory efficient iterator
    my $iterator = $useq->get_seq_stream(
        -seq_id     => 'chrI',
    );
    while (my $f = $iterator->next_seq) {
    	# each feature $f supports most SeqFeatureI methods
    }
    
    
    ### Retrieving simple scores
    my @scores = $useq->scores(
        -seq_id     => 'chrI',
        -start      => 1000,
        -end        => 2000
    );
    
    
    ### Same methods as above after defining an interval first
    my $segment = $useq->segment(
        -seq_id     => 'chrI',
        -start      => 1000,
        -end        => 2000,
    );
    my @scores   = $segment->scores;
    my @features = $segment->features;
    my $iterator = $segment->get_seq_stream;
    
    
    ### Efficient retrieval of positioned scores in 100 bins 
    # compatible with Bio::Graphics 
    my ($wig) = $useq->features(
        # assuming unstranded data here, otherwise two wiggle objects 
        # would be returned, one for each strand
        -seq_id     => 'chrI',
        -start      => 1000,
        -end        => 2000,
        -type       => 'wiggle:100',
    );
    my @bins = $wig->wiggle;
    my @bins = $wig->coverage; # same thing
    my ($bins) = $wig->get_tag_values('coverage'); # same thing
    
    
    ### Statistical summaries of intervals
    # compatible with Bio::Graphics
    my ($summary) = $useq->features(
        # assuming unstranded data here, otherwise two summaries 
        # would be returned, one for each strand
        -seq_id     => 'chrI',
        -start      => 1000,
        -end        => 2000,
        -type       => 'summary',
    );
    my $stats = $summary->statistical_summary(10);
    foreach (@$stats) {
        my $max = $_->{maxVal};
        my $mean = Bio::DB::USeq::binMean($_);
    }
    
    
    ### Stranded data using an iterator
    # could be used with either wiggle or summary features
    my $stream = $useq->get_seq_stream(
        -seq_id     => 'chrI',
        -start      => 1000,
        -end        => 2000,
        -type       => 'wiggle:100',
    );
    my ($forward, $reverse);
    if ($useq->stranded) {
        $forward = $stream->next_seq;
        $reverse = $stream->next_seq;
    }
    else {
        $forward = $stream->next_seq;
    }
    

=head1 DESCRIPTION

Bio::DB::USeq is a B<BioPerl> style adaptor for reading USeq files. USeq files 
are compressed, indexed data files supporting modern bioinformatic datasets, 
including genomic points, scores, and intervals. More information about the 
format can be found at L<http://useq.sourceforge.net/useqArchiveFormat.html>. 

USeq files are typically half the size of corresponding bigBed and bigWig files, 
due to a compact internal format and lack of internal zoom data. This adaptor, 
however, can still return statistics across different zoom levels in the same 
manner as big files, albeit at a cost of calculating these in realtime.

=head2 Generating useq files

USeq files may be generated using tools from the USeq package, available at 
L<http://useq.sourceforge.net>. They may be generated from native Bar files,
text Wig files, text Bed files, and UCSC bigWig and bigBed file formats.

=head2 Compatibility

The adaptor follows most conventions of other B<BioPerl>-style Bio::DB 
adaptors. Observations or features in the useq file archive are 
returned as SeqFeatureI compatible objects. 

Coordinates consumed and returned by the adaptor are 1-based, consistent 
with B<BioPerl> convention. This is not true of the useq file itself, which 
uses the interbase coordinate system.

Unlike wig and bigWig files, useq file archives support stranded data, 
which can make data collection much simpler for complex experiments.

See below for GBrowse compatibility.

=head2 Limitations

This adaptor is read only. USeq files, in general, are not modified 
or written with data. The exceptions are chromosome or global statistics 
are written to the F<archiveReadMe.txt> file inside the zip archive to 
cache for future queries.

No support for genomic sequence is included. Users who need access to 
genomic sequence should seek an alternative B<BioPerl> adaptor, such as 
L<Bio::DB::Fasta>.

Useq files do not have a native concept of type, primary_tag, or source 
attributes, as expected with GFF-based database adaptors. The features 
method does support special types (see below).

=head2 Requirements

The adaptor is a Perl-only implementation. It only requires the 
L<Archive::Zip> module for opening and reading the useq file archive. 
B<BioPerl> is required for working with SeqFeatures objects generated 
from useq file observations.

=head1 METHODS

=head2 Initializing the Bio::DB::USeq object

These are class methods for creating and working with the Bio::DB::USeq 
object itself.

=over 4

=item new

=item new($file)

=item new(-useq => $file)

This will create a new Bio::DB::USeq object. Optionally pass the path 
to a useq file archive to open immediately. There is not much to do 
unless you open a file.

Named arguments may be used to specify the file. Either -useq or -file 
may be used.

=item open($file)

Open a useq file archive. Useq files typically use the F<.useq> file 
extension. Returns true if successful. 

DO NOT open a subsequent useq file archive when one has already been 
opened. Please create a new object to open a new file.

=item clone

Force the object to re-open the useq archive file under a new file 
handle to make it clone safe. Do this in the child process before 
collecting data.

=item zip

Return the L<Archive::Zip> object representing the useq file archive.
Generally not recommended unless you know what you are doing.

=back

=head2 General information about the useq file

These are class methods for obtaining general information or 
metadata attributes regarding the contents of the file.

=over 4

=item stranded

Return true or false (1 or 0) indicating whether the contents of the 
useq file archive are recorded in a stranded fashion. 

=item attributes

Return an array of available attribute keys that were recorded in the 
useq file F<archiveReadMe.txt> member. These are key = value pairs 
representing metadata for the useq file. 

=item attribute($key)

Return the metadata attribute value for the specified key. These 
are recorded in the useq file F<archiveReadMe.txt> member. Returns 
undefined if the key does not exist.

=item type

Return the useq file metadata C<dataType> value.

=item genome

Return the useq file metadata C<versionedGenome> value.

=item version

Return the useq file metadata C<useqArchiveVersion> value.

=back

=head2 Chromosome Information

These are methods to obtain information about the chromosomes or reference 
sequences represented in the file archive. 

B<Note> that generating score statistics across one or more chromosomes may 
be computationally expensive. Therefore, chromosome statistics, once 
calculated, are cached in the useq file metadata for future reference. 
This necessitates writing to the useq zip archive. This is currently the 
only supported method for modifying the useq zip archive.

=over 4

=item seq_ids

Return an array of the chromosome or sequence identifiers represented 
in the useq file archive. The names are sorted ASCIIbetically before 
they are returned.

=item length($seq_id)

Return the length of the provided chromosome or sequence identifier. 
Note that this may not be the actual length in the reference genome, but 
rather the last recorded position of an observation for that chromosome. 
Hence, it should be used only as an approximation.

=item chr_mean($seq_id)

Return the mean score value across the entire chromosome.

=item chr_stdev($seq_id)

Return the score standard deviation across the entire chromosome.

=item chr_stats($seq_id)

Return a statistical summary across the entire chromosome. This 
is an anonymous hash with five keys: validCount, sumData, 
sumSquares, minVal, and maxVal. These are equivalent to the 
statistical summaries generated by the Bio::DB::BigWig adaptor.

=item global_mean

Return the mean score value across all chromosomes.

=item global_stdev

Return the mean score value across all chromosomes.

=item global_stats

Return a statistical summary across all chromosomes.

=back

=head2 Data accession

These are the primary methods for working with data contained in 
useq file archive. These should be familiar to most B<BioPerl> users. 

=over 4

=item features

Returns an array or array reference of SeqFeatureI compatible 
objects overlapping a given genomic interval. 

Coordinates of the interrogated regions must be supplied. At a 
minimum, the seq_id must be supplied. A start of 1 and an end 
corresponding to the length of the seq_id is used if not directly 
provided. Coordinates may be specified in two different manners,
either as a list of (seq_id, start, end, strand) or as one or 
more keyed values.
    
    my @features = $useq->features($seq_id, $start, $end);
    
    @features = $useq->features(
        -seq_id     => $seq_id,
        -start      => $start,
        -end        => $end,
    );

If the -iterator argument is supplied with a true value, then an 
iterator object is returned. See get_seq_stream() for details.

Bio::DB::USeq supports four different feature types. Feature 
types may be specified using the -type argument.

=over 4

=item region

=item interval

=item observation

The default feature type if the type argument is not specified. 
These are SeqFeatureI compatible objects representing observations 
in the useq file archive. These are compatible with the iterator.

=item chromosome

Returns SeqFeatureI compatible objects representing the 
reference sequences (chromosomes) listed in the useq file 
archive. These are not compatibile with the iterator.

=item wiggle

=item wiggle:$bins

=item coverage

=item coverage:$bins

Returns an array of SeqFeatureI compatible objects for each 
strand requested. If the useq file contains stranded data, 
and no strand is requested, then two objects will be 
returned representing each strand.

Each object contains an array representing scores across 
the requested coordinates. This object is designed to be 
backwards compatible with coverage features from the 
L<Bio::DB::Sam> adaptor for use with L<Bio::Graphics> and GBrowse. 
Note that only scores are returned, not a true depth coverage 
in the sense of the L<Bio::DB::Sam> coverage types. 

By default, the wiggle or coverage array is provided at 1 
bp resolution. To improve efficiency with large regions, 
the wiggle array may be limited by using a bin option, 
where the interrogated interval is divided into the number 
of bins requested.

To retrieve the scores, call the wiggle() or coverage() method.

For example, to request wiggle scores in 100 equal bins across 
the interval, see the following example. The wiggle and 
coverage types are synonymous.
  
  my ($wiggle) = $useq->features(
      -seq_id       => $chromosome,
      -start        => $start,
      -end          => $end,
      -type         => 'wiggle:100',
  );
  my @scores = $wiggle->wiggle;
  @scores    = $wiggle->coverage;

Wiggle objects may also be obtained with a get_seq_stream() 
iterator objects.

=item summary

=item summary:$bins

Returns an array of SeqFeatureI compatibile Summary objects 
for each strand requested. If the useq file contains stranded 
data, and no strand is requested, then two objects will be 
returned representing each strand.

Each Summary object can then be used to call statistical 
summaries for one or more bins across the interval. Each 
statistical summary is an anonymous hash with five keys: 
validCount, sumData, sumSquares, minVal, and maxVal. From 
these values, a mean and standard deviation may also be 
calculated.
  
  my ($summary) = $useq->features(
      -seq_id       => $chromosome,
      -start        => $start,
      -end          => $end,
      -type         => 'summary',
  );
  my @stats  = $summary->statistical_summary(100);
  foreach my $stat (@stats) {
  	 my $count = $stat->{validCount};
  	 my $sum   = $stat->{sumData};
  	 my $mean  = $sum / $count;
  }

Statistical summaries are equivalent to those generated by the 
L<Bio::DB::BigWig> adaptor and may be used interchangeably. They 
are compatible with the L<Bio::Graphics> modules.

Summary objects may also be obtained with a get_seq_stream() 
iterator object.

=back

=item get_seq_stream

This is a memory efficient data accessor. An iterator object is 
returned for an interval specified using coordinate values in the 
same manner as features(). Call the method next_seq() on the 
iterator object to retrieve the observation SeqFeature objects 
one at a time. The iterator is compatible with region, wiggle, 
and summary feature types. 
    
    # establish the iterator object
    my $iterator = $useq->get_seq_stream(
        -seq_id     => $seq_id,
        -start      => $start,
        -end        => $end,
        -type       => 'region',
    );
    
    # retrieve the features one at a time
    while (my $f = $iterator->next_seq) {
    	# each feature $f is either a 
    	# Bio::DB::USeq::Feature, 
    	# a Bio::DB::USeq::Wiggle, or 
    	# a Bio::DB::USeq::Summary object 
    }

=item scores

This is a simplified data accessor that only returns the score 
values overlapping an interrogated interval, rather than 
assembling each observation into a SeqFeature object. The scores 
are not associated with genomic coordinates, but are generally 
in ascending position order across the interval, with the 
exception of collecting scores from both strands, where the 
scores from the forward strand come first.

Provide the interval coordinates in the same manner as the 
features() method. Stranded data collection is supported.
    
    my @scores = $useq->scores(
        -seq_id     => $seq_id,
        -start      => $start,
        -end        => $end,
    );

=item segment

This returns a L<Bio::DB::USeq::Segment> object, which is a SeqFeatureI 
compatible segment object corresponding to the specified coordinates. 
From this object, one can call the features(), scores(), or 
get_seq_stream() methods directly. Keyed options or location 
information need not be provided. Stranded segments are 
supported. 
    
    my $segment = $useq->segment(
        -seq_id     => $seq_id,
        -start      => $start,
        -end        => $end,
    );
    my @scores   = $segment->scores;
    my @features = $segment->features('wiggle:100');
    my $iterator = $segment->get_seq_stream('region');

=item get_features_by_location

Convenience method for returning features restricted by location.

=item get_feature_by_id

=item get_feature_by_name

Compatibility methods for returning a specific feature or 
observation in the USeq file. Text fields, if present, are not 
indexed in the USeq file, preventing efficient searching of names. 
As a workaround, an ID or name comprised of "$seq_id:$start:$end" 
may be used, although a direct search of coordinates would be 
more efficient.
	
	my $feature = $useq->get_feature_by_id("$seq_id:$start:$end");
	

=back

=head1 ADDITIONAL CLASSES

These are additional class object that may be returned by various 
methods above.

=head2 Bio::DB::USeq::Feature objects

These are SeqFeatureI compliant objects returned by the features() 
or next_seq() methods. They support the following methods.
    
    seq_id
    start
    end
    strand
    score
    type 
    source (returns the useq archive filename)
    name (chromosome:start..stop)
    Bio::RangeI methods

Additionally, chromosome and global statistics are also available 
from any feature, as well as from Segment, Wiggle, Iterator, and 
Summary objects. See the corresponding USeq methods for details.
    
=head2 Bio::DB::USeq::Segment objects

This is a SeqFeatureI compliant object representing a genomic segment 
or interval. These support the following methods.

=over 4

=item features

=item features($type)

=item get_seq_stream

=item get_seq_stream($type)

=item scores

Direct methods for returning features or scores. Coordinate information 
need not be provided. See the corresponding Bio::DB::USeq methods for 
more information.

=item wiggle

=item wiggle($bins)

=item coverage

=item coverage($bins)

=item statistical_summary

=item statistical_summary($bins)

Convenience methods for returning wiggle (coverage) or summary features 
over the segment. If desired, the number of bins may be specified. See 
the features() method for more information.

=item slices

Returns an array of splice member names that overlap this segment.
See L<USEQ SLICES> for more information.

=back

=head2 Bio::DB::USeq::Iterator objects

This is an iterator object for retrieving useq observation SeqFeatureI 
objects in a memory efficient manner by returning one feature at a time.

=over 4

=item next_seq

=item next_feature

Returns the next feature present in the interrogated interval. Features  
are generally returned in ascending coordinate order. Returns undefined 
when no features are remaining in the interval. Features may include 
either region or wiggle types, depending on how the iterator object was 
established. See features() and get_seq_stream() methods for more 
information.

=back

=head2 Bio::DB::USeq::Wiggle objects

These are SeqFeatureI compliant objects for backwards compatibility with 
L<Bio::Graphics> and GBrowse. They support the wiggle() and coverage() 
methods, which returns an array of scores over the interrogated region. By 
default, the array is equal to the length of the region (1 bp resolution), 
or may be limited to a specified number of bins for efficiency. See the 
features() method for more information.

=over 4

=item wiggle

=item coverage

The scores are stored as an array in the coverage attribute. For 
convenience, the wiggle() and coverage() methods may be used to retrieve 
the array or array reference of scores.

=item statistical_summary

Generate a statistical summary hash for the collected wiggle scores 
(not the original data). This method is not entirely that useful; best 
to use the summary feature type in the first place.

=item chromosome and global statistics

Chromosome and global statistics, including mean and standard deviation, 
are available from wiggle objects. See the corresponding USeq methods 
for details.

=back

=head2 Bio::DB::USeq::Summary objects

These are SeqFeatureI compliant Summary objects, similar to those 
generated by the L<Bio::DB::BigWig> database adaptor. As such, they are 
compatible with L<Bio::Graphics> and GBrowse. 

Summary objects can generate statistical summaries over a specified 
number of bins (default is 1 bin, or the entire requested region). 
Each statistical summary is an anonymous hash consisting of five 
keys: validCount, sumData, sumSquares, minVal, and maxVal. From 
these values, a mean and standard deviation may be calculated.

For convenience, three exported functions are available for calculating 
the mean and standard deviation from a statistical summary hash. 
See L<EXPORTED FUNCTIONS> for more information.

Use statistical summaries in the following manner.
    
    my $stats = $summary->statistical_summary(10);
    my $stat  = shift @$stats;
    my $min   = $stat->{minVal};
    my $max   = $stat->{maxVal};
    my $mean  = $stat->{sumData} / $stat->{validCount};

=over 4

=item statistical_summary

=item statistical_summary($bins)

Generate a statistical summary hash for one or more bins across the 
interrogated region. Provide the number of bins desired. If a feature 
type of "summary:$bins" is requested through the features() or 
get_seq_stream() method, then $bins number of bins will be used. 
The default number of bins is 1.

=item score

Generate a single statistical summary over the entire region.

=item chromosome and global statistics

Chromosome and global statistics, including mean and standard deviation, 
are available from summary objects. See the corresponding USeq methods 
for details.

=back

=head1 EXPORTED FUNCTIONS

Three subroutine functions are available for export to assist 
in calculating the mean, variance, and standard deviation from 
statistical summaries. These functions are identical to those 
from the L<Bio::DB::BigWig> adaptor and may be used interchangeably. 

They are not exported by default; they must explicitly listed.
    
    use Bio::DB::USeq qw(binMean binStdev);
    my $stats = $summary->statistical_summary(10);
    my $stat  = shift @$stats;
    my $mean  = binMean($stat);
    my $stdev = binStdev($stat);

=over 4

=item binMean( $stat )

Calculate the mean from a statistical summary anonymous hash.

=item binVariance( $stat )

Calculate the variance from a statistical summary anonymous hash.

=item binStdev( $stat )

Calculate the standard deviation from a statistical summary anonymous hash.

=back

=head1 USEQ SLICES

Genomic observations are recorded in groups, called slices, of 
usually 10000 observations at a time. Each slice is a separate 
zip file member in the useq file archive. These methods are for 
accessing information about each slice. In general, accessing 
data through slices is a lower level operation. Users should 
preferentially use the main data accessors.

The following are Bio::DB::USeq methods available for working 
with slices.

=over 4

=item slices

Returns an array of all the slice member names present in the 
useq archive file.

=item slice_feature($slice)

Return a L<Bio::DB::USeq::Segment> object representing the slice interval. 
The features(), get_seq_stream(), and scores() methods are supported.

=item slice_seq_id($slice)

Return the chromosome or sequence identifier associated with a slice.

=item slice_start($slice)

Return the start position of the slice interval.

=item slice_end($slice)

Return the end position of the slice interval.

=item slice_strand($slice)

Return the strand of the slice interval.

=item slice_type($slice)

Return the file type of the slice member. This corresponds to the 
file extension of the slice zip member and indicates how to parse 
the binary member. Each letter in the type corresponds to a data 
type, be it integer, short, floating-point, or text. See the 
useq file documentation for more details.

=item slice_obs_number($slice)

Return the number of observations recorded in the slice interval.

=back

=head1 GBROWSE COMPATIBILITY

The USeq adaptor has support for L<Bio::Graphics> and GBrowse. 
It will work with the segments glyph for intervals, 
the wiggle_xyplot glyph for displaying mean scores, and the 
wiggle_whiskers glyph for displaying detailed statistics.

Initialize the USeq database adaptor.
    
    [data1:database]
    db_adaptor    = Bio::DB::USeq
    db_args       = -file /path/to/data1.useq

Displaying simple intervals with the segments glyph.
    
    [data1_segments]
    database      = data1
    feature       = region
    glyph         = segments
    stranded      = 1

Displaying scores using the wiggle_xyplot glyph. 
You may set the bins to whatever number is appropriate (in 
this example, 1000), or leave blank (not recommended, 
defaults to 1 bp resolution).
    
    [data1_xyplot]
    database      = data1
    feature       = wiggle:1000
    glyph         = wiggle_xyplot
    graph_type    = histogram
    autoscale     = chromosome

Displaying scores using the wiggle_whiskers glyph. Note that 
generating statistical summaries are computationally more expensive 
than simple bins of mean values as with the wiggle feature type.
    
    [data1_whiskers]
    database      = data1
    feature       = summary
    glyph         = wiggle_whiskers
    graph_type    = histogram
    autoscale     = chromosome

=head1 PERFORMANCE

Because the Bio::DB::USeq is implemented as a Perl-only module, 
performance is subject to the limitations of Perl execution itself and 
the size of the data that needs to be parsed. In general when collecting
score data, requesting scores is the fastest mode of operation, followed 
by wiggle feature types, and finally summary feature types. 

In comparison to UCSC bigWig files, the USeq format is typically much 
faster when viewing intervals where the entire interval is represented by 
one or a few internal slices. This is especially true for repeated queries 
over the same or neighboring intervals, as the slice contents are retained 
in memory. As the number of internal slices that must be loaded into memory 
increases, for example querying intervals of hundreds of kilobases in size, 
performance will begin to lag as each internal slice must be parsed into 
memory. This is where the UCSC bigWig file format with internal zoom levels 
of summary statistics can outperform, at the cost of file complexity and size.

=cut


require 5.010000;
use strict;
use Carp qw(carp cluck croak confess);
use Archive::Zip qw( :ERROR_CODES );
use File::Spec;

use base 'Exporter';
our @EXPORT_OK = qw(binMean binVariance binStdev);

1;

#### USeq initialization ####

sub new {
	my $class = shift;
	my $self = {
		'name'            => undef,
		'zip'             => undef,
		'stranded'        => undef,
		'seq_ids'         => {},
		'metadata'        => {},
		'coord2file'      => {},
		'file2attribute'  => {},
		'buffer'          => {},
	};
	bless $self, $class;
	
	# check for arguments
	my %args;
	if (@_) {
		if ($_[0] =~ /^-/) {
			%args = @_;
		}
		else {
			$args{-file} = shift;
		}
	}
	
	# open file
	my $file = $args{-file} || $args{-useq} || undef;	
	if ($file) {
		return unless ($self->open($file)); # open must return true 
	}
	
	# done
	return $self;
}

sub open {
	my $self = shift;
	
	# check file
	my $filename = shift;
	unless ($filename) {
		cluck("no file name passed!\n");
		return;
	}
	unless ($filename =~ /\.useq$/i) {
		carp "'$filename' is not a .useq archive file!\n";
		return;
	}
	if ($self->slices) {
		cluck "Only load one useq file per object!\n";
		return;
	}
	
	# open the archive
	my $zip = Archive::Zip->new();
	my $error = $zip->read($filename);
	unless ($error == AZ_OK) {
		carp " unable to read USeq archive '$filename'! Error $error\n";
		return;
	}
	$self->{'zip'} = $zip;
	(undef, undef, $self->{'name'}) = File::Spec->splitpath($filename);
	
	# parse the contents
	return unless ($self->_parse_members);
	# we delay parsing metadata unless it is requested
	
	# success
	return 1;
}

sub clone {
	my $self = shift;
	return unless $self->{'zip'};
	my $file = $self->zip->fileName;
	my $zip = Archive::Zip->new();
	my $error = $zip->read($file);
	unless ($error == AZ_OK) {
		carp " unable to read USeq archive '$file'! Error $error\n";
		return;
	}
	$self->{'zip'} = $zip;
	return 1;
}

sub zip {
	return shift->{'zip'};
}

sub name {
	return shift->{'name'};
}



#### General USeq information ####

sub seq_ids {
	my $self = shift;
	return sort {$a cmp $b} keys %{ $self->{'seq_ids'} };
}

sub length {
	my $self = shift;
	my $seq_id = shift or return;
	if (exists $self->{'seq_ids'}{$seq_id}) {
		return $self->{'seq_ids'}{$seq_id};
	}
}

sub stranded {
	return shift->{'stranded'};
}

sub attributes {
	my $self = shift;
	$self->_parse_metadata unless %{ $self->{'metadata'} };
	return (sort {$a cmp $b} keys %{ $self->{'metadata'} });
}

sub attribute {
	my $self = shift;
	my $key = shift;
	return $self->attributes unless $key;
	$self->_parse_metadata unless %{ $self->{'metadata'} };
	if (exists $self->{'metadata'}{$key}) {
		return $self->{'metadata'}{$key};
	}
	return;
}

sub type {
	return shift->attribute('dataType');
}

sub version {
	return shift->attribute('useqArchiveVersion');
}

sub genome {
	return shift->attribute('versionedGenome');
}

sub chr_stats {
	my $self = shift;
	my $seq_id = shift or return;
	my $delay_write = shift; # option to delay rewriting the metadata
	$self->_parse_metadata unless %{ $self->{'metadata'} };
	
	# return the chromosome stats
	if (exists $self->{metadata}{"chromStats_$seq_id"}) {
		my @data = split(',', $self->{metadata}{"chromStats_$seq_id"});
		my %stat = (
			'validCount'    => $data[0],
			'sumData'       => $data[1],
			'sumSquares'    => $data[2],
			'minVal'        => $data[3],
			'maxVal'        => $data[4],
		);
		return \%stat;
	}
	
	# chromosome stats must be generated
	my @slices = $self->_translate_coordinates_to_slices(
		$seq_id, 1, $self->length($seq_id), 0);
	$self->_clear_buffer(@slices);
	my $stat = $self->_stat_summary(1, $self->length($seq_id), \@slices);
	
	# then associate with the metadata
	$self->{'metadata'}{"chromStats_$seq_id"} = join(',', map { $stat->{$_} } 
		qw(validCount sumData sumSquares minVal maxVal) );
	$self->_rewrite_metadata unless $delay_write;
	
	return $stat;
}

sub chr_mean {
	my $self = shift;
	my $seq_id = shift or return;
	return Bio::DB::USeq::binMean( $self->chr_stats($seq_id) );
}

sub chr_stdev {
	my $self = shift;
	my $seq_id = shift or return;
	return Bio::DB::USeq::binStdev( $self->chr_stats($seq_id) );
}

sub global_stats {
	# this is an expensive proposition, because it must parse through every 
	# slice in the archive
	my $self = shift;
	$self->_parse_metadata unless %{ $self->{'metadata'} };
	
	# return the chromosome stats
	if (exists $self->{metadata}{globalStats}) {
		my @data = split(',', $self->{metadata}{globalStats});
		my %stat = (
			'validCount'    => $data[0],
			'sumData'       => $data[1],
			'sumSquares'    => $data[2],
			'minVal'        => $data[3],
			'maxVal'        => $data[4],
		);
		return \%stat;
	}
	
	# calculate new genome-wide statistics from individual chromosome stats
	my $count = 0;
	my $sum;
	my $sum_squares;
	my $min;
	my $max;
	foreach my $seq_id ($self->seq_ids) {
		my $stats = $self->chr_stats($seq_id, 1); # delay writing metadata
		$count       += $stats->{validCount};
		$sum         += $stats->{sumData};
		$sum_squares += $stats->{sumSquares};
		$min          = $stats->{minVal} if (!defined $min or $stats->{minVal} < $min);
		$max          = $stats->{maxVal} if (!defined $max or $stats->{maxVal} < $max);
	}
	
	# assemble the statistical summary hash
	my %stat = (
		'validCount'    => $count,
		'sumData'       => $sum || 0,
		'sumSquares'    => $sum_squares || 0,
		'minVal'        => $min || 0,
		'maxVal'        => $max || 0,
	);
	
	# update metadata
	$self->{'metadata'}{'globalStats'} = join(',', map { $stat{$_} } 
		qw(validCount sumData sumSquares minVal maxVal) );
	$self->_rewrite_metadata;
	
	return \%stat;
}

sub global_mean {
	my $self = shift;
	return Bio::DB::USeq::binMean( $self->global_stats );
}

sub global_stdev {
	my $self = shift;
	return Bio::DB::USeq::binStdev( $self->global_stats );
}

#### slice information ####

sub slices {
	my $self = shift;
	return sort {$a cmp $b} keys %{ $self->{'file2attribute'} };
}

sub slice_seq_id {
	my $self = shift;
	my $slice = shift or return;
	return $self->{'file2attribute'}{$slice}->[0];
}

sub slice_start {
	my $self = shift;
	my $slice = shift or return;
	return $self->{'file2attribute'}{$slice}->[1];
}

sub slice_end {
	my $self = shift;
	my $slice = shift or return;
	return $self->{'file2attribute'}{$slice}->[2];
}

sub slice_strand {
	my $self = shift;
	my $slice = shift or return;
	return $self->{'file2attribute'}{$slice}->[3];
}

sub slice_type {
	my $self = shift;
	my $slice = shift or return;
	return $self->{'file2attribute'}{$slice}->[4];
}

sub slice_obs_number {
	my $self = shift;
	my $slice = shift or return;
	return $self->{'file2attribute'}{$slice}->[5];
}

sub slice_feature {
	my $self = shift;
	my $slice = shift or return;
	return Bio::DB::USeq::Segment->new(
		-seq_id     => $self->{'file2attribute'}{$slice}->[0],
		-start      => $self->{'file2attribute'}{$slice}->[1],
		-stop       => $self->{'file2attribute'}{$slice}->[2],
		-strand     => $self->{'file2attribute'}{$slice}->[3],
		-type       => $self->{'file2attribute'}{$slice}->[4],
		-source     => $self->name,
		-name       => $slice,
	);
}





#### Feature and data access ####

sub segment {
	my $self = shift;
	
	# arguments can be chromo, start, stop, strand
	my ($seq_id, $start, $stop, $strand) = $self->_get_coordinates(@_);
	return unless $self->length($seq_id); # make sure chromosome is represented
	
	return Bio::DB::USeq::Segment->new(
		-seq_id     => $seq_id,
		-start      => $start,
		-end        => $stop,
		-strand     => $strand,
		-type       => 'segment',
		-source     => $self->name,
		-useq       => $self,
	);
}

sub features {
	my $self = shift;
	my %args = @_;
	
	# check for type
	my $type;
	$args{-type} ||= $args{-types} || $args{-primary_tag} || 'region';
	if (ref $args{-type} and ref $args{-type} eq 'ARRAY') {
		$type = $args{-type}->[0] || 'region';
		$args{-type} = $type;
	}
	else {
		$type = $args{-type};
	}
	
	# return an appropriate feature
	if ($type =~ /chromosome/) {
		# compatibility to return chromosome features
		my @chromos = map {
			Bio::DB::USeq::Feature->new(
				-seq_id => $_,
				-start  => 1,
				-end    => $self->length($_),
				-type   => $type,
				-source => $self->name,
				-name   => $_,
			)
		} $self->seq_ids;
		return wantarray ? @chromos : \@chromos;
	}
	elsif ($type =~ /region|interval|observation|coverage|wiggle|summary/) {
		# region or segment are individual observation features
		# coverage or wiggle are for efficient score retrieval with 
		# backwards compatibility with Bio::Graphics
		# summary are statistical summaries akin to Bio::DB::BigFile
		
		# set up an iterator
		my $iterator = $self->get_seq_stream(%args);
		return unless $iterator;
		
		# if user requested an iterator
		if (exists $args{-iterator} and $args{-iterator}) {
			return $iterator;
		}
		
		# collect the features
		my @features;
		while (my $f = $iterator->next_seq) {
			push @features, $f;
		}
		return wantarray ? @features : \@features;
	}
	else {
		confess "unknown type request '$type'!\n";
	}
}


sub get_features_by_type {
	# does not work without location information
	cluck "please use features() method instead";
	return;
}


sub get_features_by_location {
	my $self = shift;
	
	# arguments can be chromo, start, stop, strand
	my ($seq_id, $start, $stop, $strand) = $self->_get_coordinates(@_);
	
	return $self->features($seq_id, $start, $stop, $strand);
}


sub get_feature_by_id {
	# much as Bio::DB::BigWig fakes the id, so we will too here
	# I don't know how necessary this really is
	my $self = shift;
	
	# id will be encoded as chr:start:end ?
	my $id = shift;
	my ($seq_id, $start, $end, $type) = split /:/, $id;
	
	my @list = $self->features(
		-seq_id   => $seq_id,
		-start    => $start,
		-end      => $end,
		-type     => $type || undef,
	);
	return unless @list;
	return $list[0] if scalar @list == 1;
	foreach my $f (@list) {
		return $f if ($f->start == $start and $f->end == $end);
	}
	return;
}


sub get_feature_by_name {
	return shift->get_feature_by_id(@_);
}


sub get_seq_stream {
	my $self = shift;
	
	# arguments can be chromo, start, stop, strand
	my ($seq_id, $start, $stop, $strand) = $self->_get_coordinates(@_);
	return unless $self->length($seq_id); # make sure chromosome is represented
	
	# check for type
	my %args = @_;
	my $type;
	$args{-type} ||= $args{-types} || $args{-primary_tag} || 'region';
	if (ref $args{-type} and ref $args{-type} eq 'ARRAY') {
		$type = $args{-type}->[0] || 'region';
	}
	else {
		$type = $args{-type};
	}
	
	return Bio::DB::USeq::Iterator->new(
		-seq_id     => $seq_id,
		-start      => $start,
		-end        => $stop,
		-strand     => $strand,
		-type       => $type,
		-source     => $self->name,
		-useq       => $self,
	);
}


sub scores {
	my $self = shift;
	
	# arguments can be chromo, start, stop, strand
	my ($seq_id, $start, $stop, $strand) = $self->_get_coordinates(@_);
	return unless $self->length($seq_id); # make sure chromosome is represented
	
	# determine which slices to retrieve
	my @slices = $self->_translate_coordinates_to_slices(
		$seq_id, $start, $stop, $strand);
	return unless @slices;
	$self->_clear_buffer(@slices);
	
	# collect the scores from each of the requested slices
	my $scores = $self->_scores($start, $stop, \@slices);
	
	return wantarray ? @$scores : $scores;
}






#### Private methods ####

sub _parse_metadata {
	my $self = shift;
	
	# the metadata file should always be present in a USeq file
	my $readMe = $self->{'zip'}->contents('archiveReadMe.txt');
	unless ($readMe) {
		carp " USeq file is malformed! It does not contain an archiveReadMe.txt file\n";
		return;
	}
	
	# parse the archive file
	# this is a simple text file, each line is key = value
	$self->{'metadata'}{'comments'} = [];
	foreach (split /\n/, $readMe) {
		if (/^#/) {
			push @{ $self->{'metadata'}{'comments'} }, $_ unless $_ =~ /validCount/;
			next;
		}
		if (/^\s*([^=\s]+)\s*=\s*(.+)\s*$/) {
			# separate key = value pairs tolerating whitespace
			# key may contain anything excluding = and whitespace
			$self->{'metadata'}{$1} = $2;
		}
	}
	return 1;
}


sub _parse_members {
	my $self = shift;
	
	# there is a lot of information encoded in each zip member file name
	# the chromosome, strand, coordinates of represented interval, and file type
	# this parses and indexes this metadata into a usable format
	
	my @errors;
	foreach my $member ($self->{'zip'}->memberNames) {
		
		# archive readMe
		next if ($member eq 'archiveReadMe.txt');
			
		# data file
		my ($chromo, $strand, $start, $stop, $number, $extension) = 
			($member =~ /^([\w\-\.]+)([\+\-\.])(\d+)\-(\d+)\-(\d+)\.(\w+)$/i);
		
		# check extracted metadata
		unless ($chromo and $strand and defined $start and defined $stop and 
			$number and $extension) {
			push @errors, "  data slice $member";
			next;
		}
		
		# check stranded data
		unless (defined $self->{'stranded'}) {
			if ($strand eq '.') {
				$self->{'stranded'} = 0;
			}
			else {
				$self->{'stranded'} = 1;
			}
		}
		
		# check seq_ids 
		# record the length for each seq_id, which may or may not be entirely 
		# accurate, since it is just the last interval position
		if (exists $self->{'seq_ids'}{$chromo} ) {
			if ($stop > $self->{'seq_ids'}{$chromo}) {
				$self->{'seq_ids'}{$chromo} = $stop;
			}
		}
		else {
			$self->{'seq_ids'}{$chromo} = $stop;
		}
		
		# convert to BioPerl convention
		$strand = $strand eq '+' ? 1 : $strand eq '.' ? 0 : $strand eq '-' ? -1 : 0;
		$start += 1;
		
		# store the member details for each member slice
		$self->{'file2attribute'}{$member} = 
			[$chromo, $start, $stop, $strand, $extension, $number];
		
		# store the member details
		# hash hash array array
		# chromosome -> strand -> [ [start, member],... ]
		if (exists $self->{'coord2file'}{$chromo}{$strand}) {
			push @{ $self->{'coord2file'}{$chromo}{$strand} }, [$start, $stop, $member];
		}
		else {
			$self->{'coord2file'}{$chromo}{$strand} = [ [$start, $stop, $member] ];
		}
	}
	
	# sort the coord2file arrays by increasing start position
	foreach my $chromo (keys %{ $self->{coord2file} }) {
		foreach my $strand (keys %{ $self->{coord2file}{$chromo} }) {
			@{ $self->{coord2file}{$chromo}{$strand} } =  
				sort { $a->[0] <=> $b->[0] } 
				@{ $self->{coord2file}{$chromo}{$strand} };
		}
	}
	
	# check parsing
	if (@errors) {
		carp "Errors parsing data slice filenames:\n" . join("\n", @errors) . "\n";
	}
	unless (%{ $self->{'coord2file'} }) {
		carp "no data slices present in USeq archive!\n";
		return;
	}
	
	return 1;
}


sub _get_coordinates {
	my $self = shift;
	
	my ($seq_id, $start, $stop, $strand);
	if ($_[0] =~ /^\-/) {
		my %args = @_;
		$seq_id = $args{'-seq_id'} || $args{'-chromo'} || undef;
		$start  = $args{'-start'}  || $args{'-pos'}    || undef;
		$stop   = $args{'-end'}    || $args{'-stop'}   || undef;
		$strand = $args{'-strand'} || '0'; # unstranded
	}
	else {
		($seq_id, $start, $stop, $strand) = @_;
	}
	unless ($seq_id) {
		cluck "no sequence ID provided!";
		return;
	}
	$start ||= 1;
	$stop  ||= $self->length($seq_id);
	$strand ||= 0;
	return ($seq_id, $start, $stop, $strand);
}


sub _translate_coordinates_to_slices {
	my $self = shift;
	my ($seq_id, $start, $stop, $strand) = @_;
	return unless (exists $self->{'coord2file'}{$seq_id});
	
	# check strand request
	my $both = 0;
	if ($strand == 0) {
		# strand was not specified,
		# but collect from both strands if we have stranded data
		$both = 1 if $self->stranded;
	}
	else {
		# strand was specified, 
		# but convert it to unstranded if the data is not stranded
		$strand = 0 unless $self->stranded;
	}
	
	# look for the overlapping slices
	my @slices;
	if ($both) {
		# need to collect from both strands
		# plus strand first
		foreach my $slice ( @{ $self->{'coord2file'}{$seq_id}{1} }) {
			# each slice is [start, stop, name]
			next if $start > $slice->[1]; # end
			last if $stop  < $slice->[0]; # start
			push @slices, $slice->[2];
		}
	
		# minus strand next
		foreach my $slice ( @{ $self->{'coord2file'}{$seq_id}{-1} }) {
			# each slice is [start, stop, name]
			next if $start > $slice->[1]; # end
			last if $stop  < $slice->[0]; # start
			push @slices, $slice->[2];
		}
	}
	
	# specific strand
	else {
		foreach my $slice ( @{ $self->{'coord2file'}{$seq_id}{$strand} }) {
			# each slice is [start, stop, name]
			next if $start > $slice->[1]; # end
			last if $stop  < $slice->[0]; # start
			push @slices, $slice->[2];
		}
	}
	
	return @slices;
}


sub _clear_buffer {
	my $self = shift;
	
	# make a quick hash of wanted slices
	my %wanted = map {$_ => 1} @_;
	
	# delete the existing buffers of slices we do not want
	foreach (keys %{ $self->{buffer} }) {
		delete $self->{buffer}{$_} unless exists $wanted{$_};
	}
}

sub _load_slice {
	my $self = shift;
	my $slice = shift;
	return unless $slice;
	return if (exists $self->{'buffer'}{$slice});
	$self->{'buffer'}{$slice} = [];
	
	my $type = $self->slice_type($slice);
	if    ($type eq 's')    { $self->_load_s_slice($slice) }
	elsif ($type eq 'sf')   { $self->_load_sf_slice($slice) }
	elsif ($type eq 'st')   { $self->_load_st_slice($slice) }
	elsif ($type eq 'ss')   { $self->_load_ss_slice($slice) }
	elsif ($type eq 'ssf')  { $self->_load_ssf_slice($slice) }
	elsif ($type eq 'sst')  { $self->_load_sst_slice($slice) }
	elsif ($type eq 'ssft') { $self->_load_ssft_slice($slice) }
	elsif ($type eq 'i')    { $self->_load_i_slice($slice) }
	elsif ($type eq 'if')   { $self->_load_if_slice($slice) }
	elsif ($type eq 'it')   { $self->_load_it_slice($slice) }
	elsif ($type eq 'ii')   { $self->_load_ii_slice($slice) }
	elsif ($type eq 'iif')  { $self->_load_iif_slice($slice) }
	elsif ($type eq 'iit')  { $self->_load_iit_slice($slice) }
	elsif ($type eq 'iift') { $self->_load_iift_slice($slice) }
	elsif ($type eq 'is')   { $self->_load_is_slice($slice) }
	elsif ($type eq 'isf')  { $self->_load_isf_slice($slice) }
	elsif ($type eq 'ist')  { $self->_load_ist_slice($slice) }
	elsif ($type eq 'isft') { $self->_load_isft_slice($slice) }
	else {
		croak "unable to load slice '$slice'! Unsupported slice type $type\n";
	}
	
	# sanity check
	if (scalar @{ $self->{buffer}{$slice} } != $self->slice_obs_number($slice)) {
		croak "slice load failed! Only loaded ", scalar @{ $self->{buffer}{$slice} }, 
			" observations when expecting ", $self->slice_obs_number($slice), "!\n";
	}
}


sub _load_s_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>(s>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1;
	push @{ $self->{buffer}{$slice} }, [$position, $position, undef];
	
	# remaining observations
	while (@data) {
		$position += (shift @data) + 32768;
		push @{ $self->{buffer}{$slice} }, [$position, $position, undef];
	}
}

sub _load_sf_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>f>(s>f>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1;
	push @{ $self->{buffer}{$slice} }, [$position, $position, shift(@data)];
	
	# remaining observations
	while (@data) {
		$position += (shift @data) + 32768;
		push @{ $self->{buffer}{$slice} }, [$position, $position, shift(@data)];
	}
}

sub _load_st_slice {
	my $self = shift;
	my $slice = shift;
	
	# convert the unpacked data into start, stop, (score), text
	
	# load the slice contents
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 8; # go ahead and set index up to first observation text
	my (undef, $position, $t) = unpack('si>s>', substr($contents, 0, $i));
		# initial null, position, text_length
	$position += 1;
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position, undef, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		my ($p, $t) = unpack('s>s>', substr($contents, $i, 4));
		$i += 4;
		$position += $p + 32768;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position, undef, $text];
		$i += $t;
	}
}

sub _load_ss_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>s>(s>s>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, no score
	# first observation
	my $position = (shift @data) + 1; # interbase to base
	my $position2 = $position + (shift @data) + 32767; # 32768 - 1
	push @{ $self->{buffer}{$slice} }, [$position, $position2, undef];
	
	# remaining observations
	while (@data) {
		$position += (shift @data) + 32768;
		$position2 = $position + (shift @data) + 32767;
		push @{ $self->{buffer}{$slice} }, [$position, $position2, undef];
	}
}

sub _load_ssf_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>s>f>(s>s>f>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1; # interbase to base
	my $position2 = $position + (shift @data) + 32767; # 32768 - 1
	push @{ $self->{buffer}{$slice} }, [$position, $position2, shift(@data)];
	
	# remaining observations
	while (@data) {
		$position += (shift @data) + 32768;
		$position2 = $position + (shift @data) + 32767;
		push @{ $self->{buffer}{$slice} }, [$position, $position2, shift(@data)];
	}
}

sub _load_sst_slice {
	my $self = shift;
	my $slice = shift;
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 10; # go ahead and set index up to first observation text
	my (undef, $position, $l, $t) = unpack('si>s>s>', substr($contents, 0, $i));
		# initial null, position, length, text_length
	$position += 1; # interbase to base
	my $position2 = $position + $l + 32767; # 32768 - 1
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position2, undef, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $l, $t) = unpack('s>s>s>', substr($contents, $i, 6));
		$i += 6;
		$position += $p + 32768;
		$position2 = $position + $l + 32767;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position2, undef, $text];
		$i += $t;
	}
}

sub _load_ssft_slice {
	my $self = shift;
	my $slice = shift;
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 14; # go ahead and set index up to first observation text
	my (undef, $position, $l, $s, $t) = unpack('si>s>f>s>', substr($contents, 0, $i));
		# initial null, position, length, score, text_length
	$position += 1; # interbase to base
	my $position2 = $position + $l + 32767; # 32768 - 1
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position2, $s, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $l, $s, $t) = unpack('s>s>f>s>', substr($contents, $i, 10));
		$i += 10;
		$position += $p + 32768;
		$position2 = $position + $l + 32767;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position2, $s, $text];
		$i += $t;
	}
}

sub _load_i_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>(i>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1;
	push @{ $self->{buffer}{$slice} }, [$position, $position, undef];
	
	# remaining observations
	while (@data) {
		$position += (shift @data);
		push @{ $self->{buffer}{$slice} }, [$position, $position, undef];
	}
}

sub _load_if_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>f>(i>f>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1;
	push @{ $self->{buffer}{$slice} }, [$position, $position, shift(@data)];
	
	# remaining observations
	while (@data) {
		$position += (shift @data);
		push @{ $self->{buffer}{$slice} }, [$position, $position, shift(@data)];
	}
}

sub _load_it_slice {
	my $self = shift;
	my $slice = shift;
	
	# convert the unpacked data into start, stop, (score), text
	
	# load the slice contents
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 10; # go ahead and set index up to first observation text
	my (undef, $position, $t) = unpack('si>i>', substr($contents, 0, $i));
		# initial null, position, text_length
	$position += 1;
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position, undef, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $t) = unpack('i>s>', substr($contents, $i, 6));
		$i += 6; 
		$position += $p + 32768;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position, undef, $text];
		$i += $t;
	}
}

sub _load_ii_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>i>(i>i>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1; # interbase to base
	my $position2 = $position + (shift @data) -1; 
	push @{ $self->{buffer}{$slice} }, [$position, $position2, undef];
	
	# remaining observations
	while (@data) {
		$position += (shift @data);
		$position2 = $position + (shift @data) - 1;
		push @{ $self->{buffer}{$slice} }, [$position, $position2, undef];
	}
}

sub _load_iif_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>i>f>(i>i>f>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1; # interbase to base
	my $position2 = $position + (shift @data) - 1;
	push @{ $self->{buffer}{$slice} }, [$position, $position2, shift(@data)];
	
	# remaining observations
	while (@data) {
		$position += (shift @data);
		$position2 = $position + (shift @data) - 1;
		push @{ $self->{buffer}{$slice} }, [$position, $position2, shift(@data)];
	}
}

sub _load_iit_slice {
	my $self = shift;
	my $slice = shift;
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 12; # go ahead and set index up to first observation text
	my (undef, $position, $l, $t) = unpack('si>i>s>', substr($contents, 0, $i));
		# initial null, position, length, text_length
	$position += 1; # interbase to base
	my $position2 = $position + $l - 1;
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position2, undef, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $l, $t) = unpack('i>i>s>', substr($contents, $i, 10));
		$i += 10;
		$position += $p;
		$position2 = $position + $l - 1;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position2, undef, $text];
		$i += $t;
	}
}

sub _load_iift_slice {
	my $self = shift;
	my $slice = shift;
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 16; # go ahead and set index up to first observation text
	my (undef, $position, $l, $s, $t) = unpack('si>i>f>s>', substr($contents, 0, $i));
		# initial null, position, length, score, text_length
	$position += 1; # interbase to base
	my $position2 = $position + $l - 1;
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position2, $s, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $l, $s, $t) = unpack('i>i>f>s>', substr($contents, $i, 14));
		$i += 14;
		$position += $p;
		$position2 = $position + $l - 1;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position2, $s, $text];
		$i += $t;
	}
}

sub _load_is_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>s>(i>s>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1; # interbase to base
	my $position2 = $position + (shift @data) + 32767; # 32768 - 1
	push @{ $self->{buffer}{$slice} }, [$position, $position2, undef];
	
	# remaining observations
	while (@data) {
		$position += (shift @data);
		$position2 = $position + (shift @data) + 32767;
		push @{ $self->{buffer}{$slice} }, [$position, $position2, undef];
	}
}

sub _load_isf_slice {
	my $self = shift;
	my $slice = shift;
	
	# unpack the data slice zip member
	my $number = $self->slice_obs_number($slice);
	my ($null, @data) = unpack("si>s>f>(i>s>f>)$number", $self->zip->contents($slice) );
	
	# convert the unpacked data into start, stop, score
	# first observation
	my $position = (shift @data) + 1; # interbase to base
	my $position2 = $position + (shift @data) + 32767; # 32768 - 1
	push @{ $self->{buffer}{$slice} }, [$position, $position2, shift(@data)];
	
	# remaining observations
	while (@data) {
		$position += (shift @data);
		$position2 = $position + (shift @data) + 32767;
		push @{ $self->{buffer}{$slice} }, [$position, $position2, shift(@data)];
	}
}

sub _load_ist_slice {
	my $self = shift;
	my $slice = shift;
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 10; # go ahead and set index up to first observation text
	my (undef, $position, $l, $t) = unpack('si>s>s>', substr($contents, 0, $i));
		# initial null, position, length, text_length
	$position += 1; # interbase to base
	my $position2 = $position + $l + 32767; # 32768 - 1
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position2, undef, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $l, $t) = unpack('i>s>s>', substr($contents, $i, 8));
		$i += 8;
		$position += $p;
		$position2 = $position + $l + 32767;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position2, undef, $text];
		$i += $t;
	}
}

sub _load_isft_slice {
	my $self = shift;
	my $slice = shift;
	my $contents = $self->zip->contents($slice);
	
	# first observation
	my $i = 14; # go ahead and set index up to first observation text
	my (undef, $position, $l, $s, $t) = unpack('si>s>f>s>', substr($contents, 0, $i));
		# initial null, position, length, score, text_length
	$position += 1; # interbase to base
	my $position2 = $position + $l + 32767; # 32768 - 1
	my $text = unpack("A$t", substr($contents, $i, $t));
	push @{ $self->{buffer}{$slice} }, [$position, $position2, $s, $text];
	$i += $t;
	
	# remaining observations
	my $p; # position offset
	while ($i < CORE::length($contents)) {
		($p, $l, $s, $t) = unpack('i>s>f>s>', substr($contents, $i, 12));
		$i += 12;
		$position += $p;
		$position2 = $position + $l + 32767;
		$text = unpack("A$t", substr($contents, $i, $t));
		push @{ $self->{buffer}{$slice} }, [$position, $position2, $s, $text];
		$i += $t;
	}
}

sub _scores {
	my $self = shift;
	my ($start, $stop, $slices) = @_;
	return unless @$slices;
	
	# collect the scores from each of the requested slices
	my @scores;
	foreach my $slice (@$slices) {
		
		# load and unpack the data
		$self->_load_slice($slice);
		
		# find the overlapping observations
		# each observation is [start, stop, score]
		# quickly find a jump point and start from there through the rest of buffer
		my $data = $self->{'buffer'}{$slice};
		for my $d ($self->_jump($data, $start) .. $#{$data}) {
			# check for overlap 
			if ($data->[$d][0] <= $stop and $data->[$d][1] >= $start) {
				push @scores, $data->[$d][2] if defined $data->[$d][2];
			}
			last if $data->[$d][0] > $stop;
		}
	}
	return \@scores;
}

sub _mean_score {
	my $self = shift;
	my ($start, $stop, $slices) = @_;
	return unless @$slices;
	
	# collect the scores from each of the requested slices
	my $sum;
	my $count = 0;
	foreach my $slice (@$slices) {
		
		# load and unpack the data
		$self->_load_slice($slice);
		
		# find the overlapping observations
		# each observation is [start, stop, score]
		# quickly find a jump point and start from there through the rest of buffer
		my $data = $self->{'buffer'}{$slice};
		for my $d ($self->_jump($data, $start) .. $#{$data}) {
			# check for overlap 
			if ($data->[$d][0] <= $stop and $data->[$d][1] >= $start) {
				if ($data->[$d][2]) {
					$sum += $data->[$d][2];
					$count++;
				}
			}
			last if $data->[$d][0] > $stop;
		}
	}
	return $count ? $sum / $count : undef;
}

sub _stat_summary {
	my $self = shift;
	my ($start, $stop, $slices) = @_;
	return unless @$slices;
	
	# initialize the statistical scores
	my $count = 0;
	my $sum;
	my $sum_squares;
	my $min;
	my $max;
	
	# collect the scores from each of the requested slices
	foreach my $slice (@$slices) {
		
		# load and unpack the data
		$self->_load_slice($slice);
		
		# find the overlapping observations
		# each observation is [start, stop, score]
		# quickly find a jump point and start from there through the rest of buffer
		my $data = $self->{'buffer'}{$slice};
		for my $d ($self->_jump($data, $start) .. $#{$data}) {
			# check for overlap 
			if ($data->[$d][0] <= $stop and $data->[$d][1] >= $start) {
				if ($data->[$d][2]) {
					$count++;
					$sum += $data->[$d][2];
					$sum_squares += ($data->[$d][2] * $data->[$d][2]);
					$min = $data->[$d][2] if (!defined $min or $data->[$d][2] < $min);
					$max = $data->[$d][2] if (!defined $max or $data->[$d][2] > $max);
				}
			}
			last if $data->[$d][0] > $stop;
		}
	}
	
	# assemble the statistical summary hash
	my %summary = (
		'validCount'    => $count,
		'sumData'       => $sum || 0,
		'sumSquares'    => $sum_squares || 0,
		'minVal'        => $min || 0,
		'maxVal'        => $max || 0,
	);
	return \%summary;
}

sub _jump {
	my $self = shift;
	my ($data, $start) = @_;
	
	# jump increment of 100 observations
	# with a typical slice of 10000 observations, we can quickly cover the 
	# whole slice in < 100 loop iterations
	my $jump = 100;
	while ($jump < $#{$data}) {
		if ($data->[$jump][0] >= $start) {
			$jump -= 100; # go back a bit so we don't miss anything
			last;
		}
		$jump += 100;
	}
	return $jump;
}

sub _rewrite_metadata {
	my $self = shift;
	return unless (-w $self->zip->fileName);
	my $md = $self->{'metadata'};
	
	# generate new metadata as an array
	my @new_md;
	push @new_md, "useqArchiveVersion = " . $md->{useqArchiveVersion};
	push @new_md, @{ $md->{comments} } if exists $md->{comments};
	push @new_md, "dataType = " . $md->{dataType};
	push @new_md, "versionedGenome = " . $md->{versionedGenome};
	
	# additional keys that may be present
	foreach (keys %$md) {
		next if /useqArchiveVersion|dataType|versionedGenome|comments|chromStats|globalStats/;
		push @new_md, "$_ = $md->{$_}";
	}
	
	# global and chromosome stats
	push @new_md, 
		"# Bio::DB::USeq statistics validCount,sumData,sumSquares,minVal,maxVal";
	push @new_md, "globalStats = $md->{globalStats}" if exists $md->{globalStats};
	foreach (sort {$a cmp $b} keys %$md) {
		push @new_md, "$_ = $md->{$_}" if /chromStats/;
	}
	
	# write the new metadata to the zip Archive
	$self->{'zip'}->contents('archiveReadMe.txt', join("\n", @new_md));
	$self->{'zip'}->overwrite;
	$self->clone; # not sure if this is necessary, but just in case we reopen the zip
}


######## Exported Functions ########
# these are borrowed from Bio::DB::BigWig from Lincoln Stein

sub binMean {
    my $score = shift;
    return 0 unless $score->{validCount};
    $score->{sumData}/$score->{validCount};
}

sub binVariance {
    my $score = shift;
    return 0 unless $score->{validCount};
    my $var = $score->{sumSquares} - $score->{sumData}**2/$score->{validCount};
    if ($score->{validCount} > 1) {
	$var /= $score->{validCount}-1;
    }
    return 0 if $var < 0;
    return $var;
}

sub binStdev {
    my $score = shift;
    return sqrt(binVariance($score));
}




######## Other Classes #############

package Bio::DB::USeq::Feature;
use base 'Bio::SeqFeature::Lite';

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

sub type {
	# Bio::SeqFeature::Lite mangles the type and returns 
	# primary_tag:source if both are set
	# this may wreck havoc with parsers when the type already has a :
	# as in wiggle:1000
	my $self = shift;
	return $self->{type};
}

sub chr_stats {
	my $self = shift;
	return unless exists $self->{useq};
	return $self->{useq}->chr_stats( $self->seq_id );
}

sub chr_mean {
	my $self = shift;
	return unless exists $self->{useq};
	return $self->{useq}->chr_mean( $self->seq_id );
}

sub chr_stdev {
	my $self = shift;
	return unless exists $self->{useq};
	return $self->{useq}->chr_stdev( $self->seq_id );
}

sub global_stats {
	my $self = shift;
	return unless exists $self->{useq};
	return $self->{useq}->global_stats( $self->seq_id );
}

sub global_mean {
	my $self = shift;
	return unless exists $self->{useq};
	return $self->{useq}->global_mean( $self->seq_id );
}

sub global_stdev {
	my $self = shift;
	return unless exists $self->{useq};
	return $self->{useq}->global_stdev( $self->seq_id );
}




package Bio::DB::USeq::Segment;
use base 'Bio::DB::USeq::Feature';

sub new {
    my $class = shift;
    my %args = @_;
    my $segment = $class->SUPER::new(@_);
    $segment->{'useq'} = $args{'-useq'} if exists $args{'-useq'};
    return $segment;
}

sub scores {
	my $self = shift;
	return $self->{'useq'}->scores(
		-seq_id => $self->seq_id,
		-start  => $self->start,
		-end    => $self->end,
		-strand => $self->strand,
	);
}

sub features {
	my $self = shift;
	my $type = shift;
	$type ||= 'region';
	return $self->{'useq'}->features(
		-seq_id => $self->seq_id,
		-start  => $self->start,
		-end    => $self->end,
		-strand => $self->strand,
		-type   => $type,
	);
}

sub get_seq_stream {
	my $self = shift;
	my $type = shift;
	$type ||= 'region';
	return Bio::DB::USeq::Iterator->new(
		-seq_id => $self->seq_id,
		-start  => $self->start,
		-end    => $self->end,
		-strand => $self->strand,
		-source => $self->source,
		-type   => $type,
		-useq   => $self->{useq},
	);
}

sub slices {
	my $self = shift;
	my @slices = $self->{'useq'}->_translate_coordinates_to_slices(
		$self->seq_id, $self->start, $self->end, $self->strand
	);
	return wantarray ? @slices : \@slices;
}

sub coverage {
	my $self = shift;
	my $bins = shift;
	$bins ||= $self->length;
	return $self->features("coverage:$bins");
}

sub wiggle {
	my $self = shift;
	my $bins = shift;
	$bins ||= $self->length;
	return $self->features("wiggle:$bins");
}

sub statistical_summary {
	my $self = shift;
	my $bins = shift;
	$bins ||= 1;
	return $self->features("summary:$bins");
}


package Bio::DB::USeq::Iterator;
use base 'Bio::DB::USeq::Feature';

sub new {
    my $class = shift;
	
    # create object
	my %args = @_;
	my $useq = $args{'-useq'} or 
    	die "Bio::DB::USeq::Iterator cannot be created without a -useq argument";
    my $iterator = $class->SUPER::new(@_);
    $iterator->{'useq'} = $useq;
	
	# determine which members to retrieve
	my @slices = $useq->_translate_coordinates_to_slices(
		$args{-seq_id}, 
		$args{-start}, 
		$args{-end}, 
		$args{-strand},
	);
	$useq->_clear_buffer(@slices);
	
	# how we set up the iterator depends on the feature type requested
	# we need to add specific information to iterator object 
	
	if ($iterator->type =~ /region|interval|observation/) {
		# useq observation features are simple
		$iterator->{'wiggle'} = 0;
		
		# prepare specific iterator information
		$iterator->{'slices'} = [ @slices ];
		$iterator->{'current_slice'} = undef;
		$iterator->{'current_index'} = undef;
		
		return $iterator;
	}
	
	# otherwise we work with more complex wiggle or summary features
	$iterator->{'wiggle'} = $iterator->type =~ /summary/ ? 2 : 1;
	
	# we could have data from one or more strands
	if ($iterator->strand == 0 and $useq->stranded) {
		# separate the slices into each respective strand
		my @f;
		my @r;
		foreach (@slices) {
			if ($useq->slice_strand($_) == 1) {
				push @f, $_;
			}
			else {
				push @r, $_;
			}
		}
		$iterator->{slices} = [\@f, \@r];
	}
	else {
		# only one strand to work with
		$iterator->{slices} = [ \@slices ];
	}
	
	# check for type and bins
	my ($bin, $step);
	if ($iterator->type =~ /:(\d+)$/i) {
		$bin  = $1;
		my $length = $iterator->length;
		$bin  = $length if $bin > $length;
		$step = $length/$bin;
	}
	$iterator->{bin}  = $bin;
	$iterator->{step} = $step;
	
	return $iterator;
}

sub next_seq {
	my $self = shift;
	
	if ($self->{'wiggle'} == 1) {
		return $self->_next_wiggle;
	}
	elsif ($self->{'wiggle'} == 2) {
		return $self->_next_summary;
	}
	else {
		return $self->_next_region;
	}
}

sub next_feature {return shift->next_seq}

sub _next_region {
	my $self = shift;
	my $useq = $self->{'useq'};
	
	# get current information
	my $slice = $self->{'current_slice'} || shift @{ $self->{'slices'} } || undef;
	my $index = $self->{'current_index'} || 0;
	
	# load current slice
	return unless $slice;
	$useq->_load_slice($slice);
	my $data = $useq->{buffer}{$slice};
	my $last_index = $useq->slice_obs_number($slice) - 1;
	
	# walk through the slice
	while ($slice) {
		# check current observation for overlap
		if ($data->[$index][0] <= $self->end and $data->[$index][1] >= $self->start) {
			
			# prepare for the next call
			if ($index == $last_index) {
				# this is the last observation
				$self->{current_slice} = shift @{ $self->{'slices'} } || undef;
				$self->{current_index} = 0;
			}
			else {
				$self->{current_index} = $index + 1;
				$self->{current_slice} = $slice;
			}
			
			# return the found feature
			return Bio::DB::USeq::Feature->new(
				-seq_id     => $self->seq_id,
				-start      => $data->[$index][0],
				-end        => $data->[$index][1],
				-strand     => $useq->slice_strand($slice),
				-score      => $data->[$index][2],
				-source     => $self->source,
				-type       => $self->type,       
				-name       => defined $data->[$index][3] ? $data->[$index][3] :
					join(':', $self->seq_id, $data->[$index][0], $data->[$index][1]),
			)
		}
		
		# gone beyond the requested region
		if ($data->[$index][0] > $self->end) {
			# reset the slice, although unlikely there are anymore
			$slice = shift @{ $self->{'slices'} } || undef;
			if ($slice) {
				$useq->_load_slice($slice);
				$data = $useq->{buffer}{$slice};
			}
			$self->{current_slice} = $slice;
			$index = 0;
			$self->{current_index} = $index;
			next;
		}
		
		# no luck, prepare for next observation
		if ($index == $last_index) {
			# reset the slice, although unlikely there are anymore
			$slice = shift @{ $self->{'slices'} } || undef;
			if ($slice) {
				$useq->_load_slice($slice);
				$data = $useq->{buffer}{$slice};
			}
			$self->{current_slice} = $slice;
			$index = 0;
			$self->{current_index} = $index;
		}
		else {
			$index++;
		}
	}
	return;
}

sub _next_wiggle {
	my $self = shift;
	my $useq = $self->{'useq'};
	
	# determine which slices to retrieve
	my $slices = shift @{ $self->{slices} };
	return unless $slices;
	
	# more information
	my $start = $self->start;
	my $stop  = $self->end;
	my $step  = $self->{step};
	
	# check whether we are working with binned wiggle or not
	my @scores;
	if ($self->{bin} and $step > 1) {
		# we will be collecting the mean score value in bins
		
		# collect the scores for each bin
		for (my $begin = $start; $begin < $stop; $begin += $step) {
			
			# round off coordinates to integers
			# beginning point and step may not be integers
			my $s = int($begin + 0.5); 
			my $e = int($s + $step - 0.5); # start + step - 1 + 0.5
			
			# collect the scores from each of the requested slices
			if (scalar @$slices > 1) {
				# more than one slice, identify which subset of slices to collect from
				# may or may not be all of the current slices
				my @sub_slices;
				foreach my $slice (@$slices) {
					next if $s > $useq->slice_end($slice);
					next if $e < $useq->slice_start($slice);
					push @sub_slices, $slice;
				}
				push @scores, $useq->_mean_score($s, $e, \@sub_slices);
			}
			else {
				push @scores, $useq->_mean_score($s, $e, $slices);
			}
		}
	}
	else {
		# otherwise we collect in one step and associate scores at bp resolution
		# collect the scores from each of the requested slices and 
		# assemble them into a hash of values

		# correlate scores with position
		my %pos2score;
		foreach my $slice (@$slices) {

			# load and unpack the data
			$useq->_load_slice($slice);

			# find the overlapping observations
			# each observation is [start, stop, score]
			# quickly find a jump point and start from there through the rest of buffer
			my $data = $useq->{'buffer'}{$slice};
			for my $d ($useq->_jump($data, $start) .. $#{$data}) {
				# check for overlap 
				if ($data->[$d][0] <= $stop and $data->[$d][1] >= $start) {
					foreach my $p ( $data->[$d][0] .. $data->[$d][1] ) {
						$pos2score{$p} = $data->[$d][2];
					}
				}
				last if $data->[$d][0] > $stop;
			}
		}

		# convert positioned scores into an array
		foreach (my $s = $start; $s <= $stop; $s++) {
			push @scores, exists $pos2score{$s} ? $pos2score{$s} : undef;
			# for Bio::Graphics it is better to store undef than 0 
			# which can do wonky things with graphs
		}
	}

	# generate the wiggle object
	my $strand = $useq->slice_strand( $slices->[0] ) || 0;
	return Bio::DB::USeq::Wiggle->new(
		-seq_id     => $self->seq_id,
		-start      => $start,
		-end        => $stop,
		-strand     => $strand,
		-type       => $self->type,
		-source     => $self->source,
		-attributes => { 'coverage' => [ \@scores ] },
		-name       => $strand == 1 ? 'Forward' : 
			$strand == -1 ? 'Reverse' : q(),
		-useq       => $useq,
	);
}

sub _next_summary {
	my $self = shift;
	
	# determine which slices to retrieve
	my $slices = shift @{ $self->{slices} };
	return unless $slices;
	
	# all of the real statistical work is done elsewhere
	# just return the summary object
	my $strand = $self->{useq}->slice_strand( $slices->[0] ) || 0;
	return Bio::DB::USeq::Summary->new(
		-seq_id     => $self->seq_id,
		-start      => $self->start,
		-end        => $self->end,
		-strand     => $strand,
		-type       => $self->type,
		-source     => $self->source,
		-name       => $strand == 1 ? 'Forward' : 
			$strand == -1 ? 'Reverse' : q(),
		-useq       => $self->{'useq'},
		-slices     => $slices,
		-bin        => $self->{bin},
		-step       => $self->{step},
	);
}



package Bio::DB::USeq::Wiggle;
use base 'Bio::DB::USeq::Feature';
# Wiggle scores are stored in the coverage attribute for backwards 
# compatibility with Bio::Graphics. 

sub new {
    my $class = shift;
    my $wig = $class->SUPER::new(@_);
    my %args = @_;
	my $useq = $args{'-useq'} or 
    	die "Bio::DB::USeq::Wiggle cannot be created without a -useq argument";
    $wig->{useq} = $useq;
    return $wig;
}

sub coverage {
	my $self = shift;
	my ($coverage) = $self->get_tag_values('coverage');
	return wantarray ? @$coverage : $coverage;
}

sub wiggle {
	return shift->coverage;
}

# Borrowed from Bio::SeqFeature::Coverage from Bio::DB::Sam
sub gff3_string {
    my $self = shift;
    my $gff3 = $self->SUPER::gff3_string(@_);
    my $coverage = $self->escape(join(',',$self->coverage));
    $gff3 =~ s/coverage=[^;]+/coverage=$coverage/g;
    return $gff3;
}

sub statistical_summary {
	# this is just for the wiggle scores, not original data
		# This is a fake statistical_summary to fool Bio::Graphics into 
		# calculating chromosome or global statistics like a BigWig adaptor.
		# A real statistical_summary call would provide the number of bins,
		# so return null if bins is present.
		# We could calculate a real statistical summary, but that would be an 
		# expensive circuitous route after we just collected wiggle scores.
		# Better to request the correct feature type in the first place.
	my $self = shift;
	my $bins = shift;
	return if $bins && $bins > 1; 
	
	# initialize the statistical scores
	my $count = 0;
	my $sum;
	my $sum_squares;
	my $min;
	my $max;
	
	# generate a statistical summary of just the wiggle scores
	foreach my $s ($self->coverage) {
		$count++;
		next unless defined $s;
		$sum += $s;
		$sum_squares += $s * $s;
		$min = $s if (!defined $min or $s < $min);
		$max = $s if (!defined $max or $s > $max); 
	}
	
	# return the statistical hash
	my %stat = (
		'validCount' => $count,
		'sumData'    => $sum || 0,
		'sumSquares' => $sum_squares || 0,
		'minVal'     => $min || 0,
		'maxVal'     => $max || 0,
	);
	return \%stat;
}

sub get_seq_stream {
	my $self = shift;
	return Bio::DB::USeq::Iterator->new(
		-seq_id     => $self->seq_id,
		-start      => $self->start,
		-end        => $self->end,
		-strand     => $self->strand,
		-type       => 'region',
		-source     => $self->source,
		-useq       => $self->{useq},
	);
}




package Bio::DB::USeq::Summary;
use base 'Bio::DB::USeq::Feature';

sub new {
    my $class = shift;
    my $summary = $class->SUPER::new(@_);
    my %args = @_;
	my $useq = $args{'-useq'} or 
    	die "Bio::DB::USeq::Summary cannot be created without a -useq argument";
    $summary->{useq} = $useq;
    $summary->{slices} = $args{-slices} if exists $args{-slices};
    $summary->{bin}    = $args{-bin}    if exists $args{-bin};
    $summary->{step}   = $args{-step}   if exists $args{-step};
    return $summary;
}

sub statistical_summary {
	my $self = shift;
	my $useq = $self->{useq};
	
	# get the number of bins to calculate the statistical summaries
	my $bin = shift;
	$bin ||= $self->{bin} if exists $self->{bin};
	$bin ||= 1;
	my $step = $self->{step} if exists $self->{step};
	$step ||= $self->length / $bin;
	
	# get the slices
	my $slices = $self->{slices} if exists $self->{slices};
	unless ($slices) {
		# this should already be established, but just in case
		my @a = $useq->_translate_coordinates_to_slices($self->seq_id, 
				$self->start, $self->end, $self->strand);
		$useq->_clear_buffer(@a);
		$slices = \@a;
	}
	
	# collect the statistical summaries for each bin
	my @summaries;
	for (my $begin = $self->start; $begin < $self->end; $begin += $step) {
		
		# round off coordinates to integers
		# beginning point and step may not be integers
		my $s = int($begin + 0.5); 
		my $e = int($s + $step - 0.5); # start + step - 1 + 0.5
		
		# collect the scores from each of the requested slices
		if (scalar @$slices > 1) {
			# more than one slice, identify which subset of slices to collect from
			# may or may not be all of the current slices
			my @sub_slices;
			foreach my $slice (@$slices) {
				next if $s > $useq->slice_end($slice);
				next if $e < $useq->slice_start($slice);
				push @sub_slices, $slice;
			}
			push @summaries, $useq->_stat_summary($s, $e, \@sub_slices);
		}
		else {
			push @summaries, $useq->_stat_summary($s, $e, $slices);
		}
	}
	
	# return the reference to the statistical summaries
	return \@summaries;
}

sub score {
	my $self = shift;
	my $a = $self->statistical_summary(1);
	return $a->[0];
}

sub gff3_string {
	# this is going to be a little convoluted, since what we 
	# really want here is coverage, which is easier to calculate with means, 
	# rather than doing statistical summaries and calculate means from those
	my $self = shift;
	my ($wig) = $self->{useq}->features(
		# this should only return one feature because we have specific strand
		-seq_id     => $self->seq_id,
		-start      => $self->start,
		-end        => $self->end,
		-strand     => $self->strand,
		-type       => 'coverage:1000',
	);
	return $wig->gff3_string;
}

sub get_seq_stream {
	my $self = shift;
	return Bio::DB::USeq::Iterator->new(
		-seq_id     => $self->seq_id,
		-start      => $self->start,
		-end        => $self->end,
		-strand     => $self->strand,
		-type       => 'region',
		-source     => $self->source,
		-useq       => $self->{useq},
	);
}

=head1 AUTHOR

 Timothy J. Parnell, PhD
 Dept of Oncological Sciences
 Huntsman Cancer Institute
 University of Utah
 Salt Lake City, UT, 84112

This package is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0. 
