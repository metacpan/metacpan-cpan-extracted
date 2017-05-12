package Bio::DB::BigFile;

# $Id$

use strict;
use warnings;

=head1 NAME

Bio::DB::BigFile -- Low-level interface to BigWig & BigBed files

=head1 SYNOPSIS

   use Bio::DB::BigFile;
   use Bio::DB::BigFile::Constants;

   my $wig       = Bio::DB::BigFile->bigWigFileOpen('hg18_methylcytosine.bw');

   # query each of the intervals (fixed or variable step values)
   my $intervals = $wig->bigWigIntervalQuery('chr1',5_000_000 => 8_000_000);
   for (my $i=$intervals->head;$i;$i=$i->next) {
      my $start = $i->start;
      my $end   = $i->end;
      my $val   = $i->val;
   }

   # get 500 bins of statistical summary data
   my $summary = $bigWigSummaryArray('chr1',5_000_000=>8_000_000,bbiSumMean,500);
   for (my $i=0;$i<$bin;$i++) {
      print "bin $i: ",$summary->[$i],"\n";
   }

   # get 500 bins of extended summary data
   my $summary_e = $bigWigSummaryArrayExtended('chr1',5_000_000=>8_000_000,500);
   for (my $i=0;$i<$bin;$i++) {
      my $s = $summary_e->[$i];
      print "bin $i: min=$s->{minVal} max=$s->{maxVal} sum=$s->{sumData}\n";
   }

   # single summary over a bin
   my $mean = $wig->bigWigSingleSummary('chr1',5_000_000=>6_000_000,bbiSumMean);

=head1 DESCRIPTION

This module provides a low-level interface to Jim Kent's BigWig and
BigBed files, which are indexed genome feature databases that can be
randomly accessed across the network. Please see
http://genome.ucsc.edu/FAQ/FAQformat.html for information about
creating these files.

For the high-level interface, please see Bio::DB::BigWig and
Bio::DB::BigBed.

=head1 INSTALLATION

Installation requires a compiled version of Jim Kent's source tree,
including the main library, jkweb.a. Please see the README in the
Bio::DB::BigFile distribution directory for instructions.

=head1 CLASS METHODS

Please note that B<all> genomic coordinates consumed or returned by
this module are zero-based half-open intervals. This is not true of
the "high level" interfaces.

=over 4

=item $wig = Bio::DB::BigFile->bigWigFileOpen('/path/to/file.bw');

Open a preexisting BigWig file and return its object handle. The
returned object object will be of type Bio::DB::bbiFile.

=item $bed = Bio::DB::BigFile->bigBedFileOpen('/path/to/file.bb');

Open a preexisting BigBed file and return its object handle. The
returned object object will be of type Bio::DB::bbiFile.

=item Bio::DB::BigFile->createBigWig($infile,$chrom_sizes,$outfile,$args)

Create a BigWig file from a text .wig file (without track definition
lines). The arguments are identical to those used by the UCSC
wigToBigWig utility.

$infile is the path to the input .wig file.

$chrom_sizes points to a file of chromosome sizes formatted in two
whitespace-separated columns consisting of chromosome name and size.

$outfile is a path to the BigWig file you wish to create.

$args is a hash reference containing the following options:

   Option        Value               Default
   ------        -----               -------

   blockSize     Record block size   1024   

   itemsPerSlot  Record batching      512

   clipDontDie   If values are given    1
                 that fall outside
                 chromosome boundaries
                 then warn, but don't
                 exit.

   compress      Compress the BigWig    1
                 file to save space.

If an exception occurs (for example, the output location is not
writable), then this method will terminate the process. The exception
cannot be caught by an eval {}.

Note that there is no equivalent method for creating BigBed files, and
this method may also be deprecated in the future. Jim Kent recommends
using the wigToBigWig and bedToBigBed command-line utilities instead.

=item Bio::DB::BigFile->udcSetDefaultDir('/path/')

When the BigWig/BigBed library accesses remote Big{Wig,Bed} files, it
creates a series of cache files located in /tmp/udcCache by
default. To change the location of the cache files, call this method,
passing it the path to the preferred directory.

=item $path = Bio::DB::BigFile->udcGetDefaultDir()

This class method returns the current UDC cache default directory.

=back

=head1 OBJECT METHODS

Once a Bio::DB::bbiFile object is created, you can query it using the
methods described in this section.

Please note that B<all> genomic coordinates consumed or returned by
this module are zero-based half-open intervals. This is not true of
the "high level" interfaces.

=head2 BigWig File Methods

=over 4

=item $wig->bigWigIntervalDump($seqid,$start,$end [,$max,$fh])

For the indicated region (chromosome,start,end), convert the BigWig
file into text WIG format and write it to standard output. If $max is
provided, then limit the dump to $max values. If $fh is provided, then
write to the indicated file handle. Note that only real filehandles
work: tied filehandles such as IO::String will cause a core dump.

=item $chromosome_list = $wig->chromList()

Return the head to a linked list of chromosomes known to the BigWig
file. The head of the list has one method named head() which returns
the first Bio::DB::ChromInfo object. Each ChromInfo object has the
following methods:

   next()     Return the next ChromInfo in the list, or undef if
               this is the last element in the list.

   name()     Return the name of the chromosome.

   id()       Return the ID of the chromosome (usually a small
               integer).

   size()     Return the size of the chromosome.

For example, to iterate over all chromosomes known to the BigWig:

   my $list  = $wig->chromList();
   my $next  = $list->head;
   while ($next) {
      print $next->name,": ",$next->size,"\n";
      $next = $next->next;
   }

Do not undef the list object while you are still iterating through its
chromInfo objects.

=item $size = $wig->chromSize('chr1')

Return the size of a single named chromosome, or undef if there is no
chromosome of this size.

=item $interval_head = $wig->bigWigIntervalQuery($chrom,$start,$end)

For the region indicated by the chromosome name, start and end, return
the head of a linked list of Bio::DB::bbiInterval objects for which
there is wig file data. Each interval corresponds to a single data
line in the original WIG file.

The head of the list has one method named head(), which returns the
first Bio::DB::bbiInterval object. Each object has the following
methods:

   next()   Return the next bbiInterval object in the list, or undef if
             this is the last element in the list.

   start()  The start of this interval
 
   end()    The end of this interval

   value()  The numeric value of this interval

For example, to iterate over all intervals on the first megabase of
chromosome 3:

   my $list  = $wig->bigWigIntervalQuery('chr3',0=>1_000_000);
   my $next  = $list->head;
   while ($next) {
      print $next->start,"..",$next->end,": ",$next->val,"\n";
      $next = $next->next;
   }

Do not undef the list head object while you are still iterating
through its elements.

=item $summaryarray = $wig->bigWigSummaryArray($chrom,$start,$end,$operation,$bins)

For the region indicated by $chrom, $start and $end, divide the
interval into $bins subregions and compute summary information
according to $operation. The result is returned in an array reference
of $bins elements in length.

The operation is one of the following, defined in
Bio::DB::BigFile::Constants:

  Constant       Operation
  --------       ---------

  bbiSumMean     The mean value of all intervals in the bin.

  bbiSumMax      The maximum value of all intervals in the bin.

  bbiSumMin      The minimum value of all intervals in the bin.

  bbiSumCoverage The count of all intervals in the bin.

  bbiSumStandardDeviation  The standard deviation of all intervals in
                           the bin.

For example, to divide the first megabase of chromosome 3 into 100
bins and find the mean value of the intervals in each bin:

  my $bins = $wig->bigWigSummaryArray('chr3',0=>1_000_000,bbiSumMean,100);

  for my $value (@$bins) {
    print $value,"\n";
  }

If the interval is invalid, returns undef.

=item $value = $wig->bigWigSingleSummary($chrom,$start,$end,$operation)

Return statistical summary information about a single
interval. $operation corresponds to one of the constants described in
bigWigSummaryArray().

=item $summaryarray=$wig->bigWigSummaryArrayExtended($chrom,$start,$end,$bins)

This method is similar to bigWigSummaryArray(), except that instead of
returning an arrayref of numeric values, the returned arrayref points
to a list of hashes describing the contents of each bin. Hash keys are
the following:

  Key                Value
  ---            ---------

  validCount     Number of intervals in the bin

  maxVal         Maximum value in the bin

  minVal         Minimum value in the bin

  sumData        Sum of the intervals in the bin

  sumSquares     Sum of the squares of the intervals in the bin

sumData and sumSquares can be used to compute the mean and standard
deviation of the bin, and to compute these values when multiple bins
are combined.

For example, to calculate the means of 100 bins across an interval:


  my $bins = $wig->bigWigSummaryArrayExtended('chr3',0=>1_000_000,100);
  for (my $i=0;$i<@$bins;$i++) {
    my $mean = $bins->[$i]{sumData}/$bins->[$i]{validCount};
  }

=item $summaryobj=$wig->bigWigSummary($chrom,$start,$end,$bins)

This is similar to the previous method, except that it returns a
summary object rather than an arrayref. This object, of type
Bio::DB::bbiExtendedSummary, has the following methods:

  $summaryobj->size()             Number of bins in the summary.

  $summaryobj->validCount($bin)   Count of intervals in bin $bin.

  $summaryobj->minVal($bin)       Minimum value in bin $bin.

  $summaryobj->maxVal($bin)       Maximum value in bin $bin.

  $summaryobj->sumData($bin)      Sum of the values in bin $bin.

  $summaryobj->sumSquares($bin)   Sum of the squares of the values in
                                   bin $bin

This method may be slightly more memory-efficient than
bigWigSummaryArrayExtended.

=item $arrayref = $wig->bigWigBinStats($chrom,$start,$end,$bins)

This is similar to the previous two methods, but returns a reference
to an array of objects with vaidCount(), minVal(), maxVal(), sumData()
and sumSquares() methods.

Example:

  my $bins = $wig->bigWigBinStats('chr3',0=>1_000_000,100);
  for (my $i=0;$i<@$bins;$i++) {
    my $mean = $bins->[$i]->sumData()/$bins->[$i]->validCount();
  }

This method is about 30% slower than the previous methods, and may be
deprecated in the future.

=back

=head2 BigBed File Methods

These methods apply to previously opened BigBed files.

=over 4

=item $count = $bed->bigBedItemCount()

Returns the number of items in the BigBed file.

=item $chromosome_list = $bed->chromList()

This is identical to the BigWig chromList() method and returns an
object that points to a linked list of chromosome information objects.

=item $list_head = $bed->bigBedIntervalQuery($chrom,$start,$end [,$max])

For the indicated interval, return the head to a linked list of BigBed
interval objects (Bio::DB::BigBedInterval). $max specifies the maximum
number of items to return; unlimited if absent or 0. The head object
has a single method named head() that returns the first interval
object. Each interval object has the following methods:

  next()     Return the next interval in the list
  start()    Start of this interval
  end()      End of this interval
  rest()     Return a string corresponding to all of
              the BED fields following the end field.
              This will be whitespace-delimited, but
              otherwise unparsed.

Here is a simple bigBedToBed file dumper:

 my $chroms = $bed->chromList;
 for (my $c = $chroms->head; $c; $c=$c->next) {
    dump_chrom($c);
 }

 sub dump_chrom {
     my $chrom = shift;
     my $name  = $chrom->name;
     my $size  = $chrom->size;
     my $intervals = $bed->bigBedIntervalQuery($name,0,$size);
     for (my $i=$intervals->head;$i;$i=$i->next) {
	 print join("\t",$name,$i->start,$i->end,$i->rest),"\n";
     }
 }

=item $summaryarray = $wig->bigBedSummaryArray($chrom,$start,$end,$operation,$bins)

For the region indicated by $chrom, $start and $end, divide the
interval into $bins subregions and compute summary information
according to $operation. The result is returned in an array reference
of $bins elements in length.

The operation is one of the following, defined in Bio::DB::BigFile::Constants:

  Constant       Operation
  --------       ---------

  bbiSumMean     The mean value of all intervals in the bin.

  bbiSumMax      The maximum value of all intervals in the bin.

  bbiSumMin      The minimum value of all intervals in the bin.

  bbiSumCoverage The count of all intervals in the bin.

  bbiSumStandardDeviation  The standard deviation of all intervals in
                           the bin.

For example, to divide the first megabase of chromosome 3 into 100
bins and find the mean value of the intervals in each bin:

  my $bins = $wig->bigBedSummaryArray('chr3',0=>1_000_000,bbiSumMean,100);

  for my $value (@$bins) {
    print $value,"\n";
  }

If the interval is invalid, returns undef.

=item $summaryarray=$wig->bigBedSummaryArrayExtended($chrom,$start,$end,$bins)

This method is similar to bigBedSummaryArray(), except that instead of
returning an arrayref of numeric values, the returned arrayref points
to a list of hashes describing the contents of each bin. Hash keys are
the following:

  Key                Value
  ---            ---------

  validCount     Number of intervals in the bin

  maxVal         Maximum value in the bin

  minVal         Minimum value in the bin

  sumData        Sum of the intervals in the bin

  sumSquares     Sum of the squares of the intervals in the bin

sumData and sumSquares can be used to compute the mean and standard
deviation of the bin, and to compute these values when multiple bins
are combined.

For example, to calculate the means of 100 bins across an interval:

  my $bins = $wig->bigBedSummaryArrayExtended('chr3',0=>1_000_000,100);
  for (my $i=0;$i<@$bins;$i++) {
    my $mean = $bins->[$i]{sumData}/$bins->[$i]{validCount};
  }

=item $summaryobj=$wig->bigBedSummary($chrom,$start,$end,$bins)

This is similar to the previous method, except that it returns a
summary object rather than an arrayref. This object, of type
Bio::DB::bbiExtendedSummary, has the following methods:

  $summaryobj->size()             Number of bins in the summary.

  $summaryobj->validCount($bin)   Count of intervals in bin $bin.

  $summaryobj->minVal($bin)       Minimum value in bin $bin.

  $summaryobj->maxVal($bin)       Maximum value in bin $bin.

  $summaryobj->sumData($bin)      Sum of the values in bin $bin.

  $summaryobj->sumSquares($bin)   Sum of the squares of the values in
                                   bin $bin

This method may be slightly more memory-efficient than
bigBedSummaryArrayExtended.

=item $sql = $bed->bigBedAutoSqlText()

Return the autoSQL text associated with this BigBed file, if any.

=item $as_object = $bed->bigBedAs()

Return a parsed object corresponding to the AutoSQL data. See AutoSQL
Methods for a description of what you can do with this object.

=back

=head2 AutoSQL Methods

The bigBedAs() method returns a parsed AutoSQL definition object of
type Bio::DB::asObject. A full description of this object is beyond
the scope of this document; please see the Jim Kent include file
asParse.h for definitions of the various objects and methods that are
not discussed in detail.

B<Bio::DB::asObject>

This corresponds to a SQL table and its linked C definition.

=over 4

=item $asObject = $as->next

Return the next asObject in a linked list.

=item $string = $as->name

Return the name of the object.

=item $string = $as->comment

Return the comment for the object.

=item $bool = $as->isTable

Return true if the object is a SQL table.

=item $bool = $as->isSimple

Return true if the object is a simple object.

=item $column_list = $as->columnList

Returns a linked list of autosql object columns.

=back

B<Bio::DB::asColumn>

This corresponds to a column in a SQL table and its corresponding C
struct field.

=over 4

=item $as_column = $ac->next

Return the next column in the linked list.

=item $string = $ac->name

Column name.

=item $string = $ac->comment

Column comment.

=item $as_column_type = $ac->lowType

Column type, a Bio::DB::asTypeInfo object.

=item $string    = $ac->obName

=item $string    = $ac->obType

=item $as_column = $ac->linkedSize

=item $int       = $ac->fixedSize

=item $string    = $ac->linkedSizeName

=item $bool      = $ac->isList

=item $bool      = $ac->isArray

Not documented here.

=back

B<Bio::DB::asTypeInfo>

This corresponds to the SQL and C struct types of an autosql column.

=over 4

=item $int = $ati->type

Numeric ID of this type.

=item $string = $ati->name

AutoSQL name for the type.

=item $string = $ati->sqlName

SQL name for the type.

=item $string = $ati->cName

C struct name for the type.

=item $bool = $ati->isUnsigned

=item $bool = $ati->stringy

=item $bool = $ati->listyName

=item $bool = $ati->nummyName

=item $bool = $ati->outFormat

Not documented here.

=back


=cut

use Carp 'croak';
use base qw(DynaLoader);
use File::Spec;
use Bio::DB::BigFile::Constants;
our $VERSION = '1.07';

bootstrap Bio::DB::BigFile;

sub createBigWig {
    my $self = shift;
    my ($inFile,$chrom_sizes,$outFile,$args) = @_;
    my %defaults = (blockSize   =>1024,
		    itemsPerSlot=>512,
		    clipDontDie => 1,
		    compress    => 1);
    $args ||= {};
    my %merged_args = (%defaults,%$args);
    $self->bigWigFileCreate($inFile,$chrom_sizes,
			    @merged_args{qw(blockSize itemsPerSlot clipDontDie compress)},
			    $outFile);
}

sub set_udc_defaults {
    my $class = shift;

    if (my $override = $ENV{UDC_CACHEDIR}) {
	Bio::DB::BigFile->udcSetDefaultDir($override);
	return;
    }

    my $path = Bio::DB::BigFile->udcGetDefaultDir();
    return if -w $path;
    my $tmp    = File::Spec->tmpdir();
    my ($user) = getpwuid($<);
    $user    ||= $<;
    $path      = File::Spec->catfile($tmp,"udcCache_$user");
    Bio::DB::BigFile->udcSetDefaultDir($path);
}


package Bio::DB::bbiFile;

# this method is fun but slow

sub bigWigBinStats {
    my $self = shift;
    my $extended_summary = $self->bigWigSummary(@_);
    my @tie;
    tie @tie,'Bio::DB::BigWig::binStats',$extended_summary;
    return \@tie;
}


package Bio::DB::BigWig::binStats;

use base 'Tie::Array';
use Carp 'croak';

sub TIEARRAY {
    my $class = shift;
    my $summary = shift;
    $summary 
	or croak "Usage: tie(\@array,'$class',\$summary), where \$summary is a Bio::DB::BigWigExtendedSummary object";
    return bless \$summary,ref($class) || $class;
}

sub FETCH {
    my $self  = shift;
    my $index = shift;
    return Bio::DB::BigWig::binStatElement->new($$self,$index);
}

sub FETCHSIZE {
    my $self = shift;
    return $$self->size;
}

package Bio::DB::BigWig::binStatElement;

sub new {
    my $class = shift;
    my ($base,$index) = @_;
    return bless [$base,$index],ref $class || $class;
}

sub validCount {
    my $self = shift;
    $self->[0]->validCount($self->[1]);
}

sub minVal {
    my $self = shift;
    $self->[0]->minVal($self->[1]);
}

sub maxVal {
    my $self = shift;
    $self->[0]->maxVal($self->[1]);
}

sub sumData {
    my $self = shift;
    $self->[0]->sumData($self->[1]);
}

sub sumSquares {
    my $self = shift;
    $self->[0]->sumSquares($self->[1]);
}

=head1 SEE ALSO

L<Bio::Perl>, L<Bio::Graphics>, L<Bio::Graphics::Browser2>

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



