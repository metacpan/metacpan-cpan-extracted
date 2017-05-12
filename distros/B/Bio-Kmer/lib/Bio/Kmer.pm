#!/usr/bin/env perl

# Kmer.pm: a kmer counting module
# Author: Lee Katz <lkatz@cdc.gov>

=pod SCRIPT CATEGORIES

CPAN

=cut


package Bio::Kmer 0.07;
require 5.12.0;

use strict;
use warnings;

use List::Util qw/max/;
use File::Basename qw/basename fileparse dirname/;
use File::Temp qw/tempdir tempfile/;
use Data::Dumper;
use IO::Uncompress::Gunzip;

use threads;
use threads::shared;
use Thread::Queue;

use Exporter qw/import/;
our @EXPORT_OK = qw(
           );

our @fastqExt=qw(.fastq.gz .fastq .fq .fq.gz);
our @fastaExt=qw(.fasta .fna .faa .mfa .fas .fa);
our @bamExt=qw(.sorted.bam .bam);
our @vcfExt=qw(.vcf.gz .vcf);
our @richseqExt=qw(.gbk .gbf .gb .embl);
our @sffExt=qw(.sff);
our @samExt=qw(.sam .bam);

our $fhStick :shared; # Helps us open only one file at a time


# TODO if 'die' is imported by a script, redefine
# sig die in that script as this function.
local $SIG{'__DIE__'} = sub { my $e = $_[0]; $e =~ s/(at [^\s]+? line \d+\.$)/\nStopped $1/; die("$0: ".(caller(1))[3].": ".$e); };

=pod

=head1 NAME

Bio::Kmer

=head1 SYNOPSIS

A module for helping with kmer analysis.

  use strict;
  use warnings;
  use Bio::Kmer;
  
  my $kmer=Bio::Kmer->new("file.fastq.gz",{kmercounter=>"jellyfish",numcpus=>4});
  my $kmerHash=$kmer->kmers();
  my $countOfCounts=$kmer->histogram();

=head1 DESCRIPTION

A module for helping with kmer analysis. The basic methods help count kmers and can produce a count of counts.  Currently this module only supports fastq format.  Although this module can count kmers with pure perl, it is recommended to give the option for a different kmer counter such as Jellyfish.

=pod

=head1 METHODS

=over

=item new

Create a new instance of the kmer counter.  One object per file. 

  Applicable arguments:
  Argument     Default    Description
  kmercounter  perl       What kmer counter software to use.
                          Choices: Perl, Jellyfish.
  kmerlength   21         Kmer length
  numcpus      1          This module uses perl 
                          multithreading with pure perl or 
                          can supply this option to other 
                          software like jellyfish.
  gt           1          If the count of kmers is fewer 
                          than this, ignore the kmer. This 
                          might help speed analysis if you 
                          do not care about low-count kmers.

  Examples:
  my $kmer=Bio::Kmer->new("file.fastq.gz",{kmercounter=>"jellyfish",numcpus=>4});

=back

=cut

sub new{
  my($class,$seqfile,$settings)=@_;

  die "ERROR: need a sequence file" if(!$seqfile);
  die "ERROR: could not locate the sequence file" if(!-e $seqfile);

  # Set optional parameter defaults
  $$settings{kmerlength}  ||=21;
  $$settings{numcpus}     ||=1;
  $$settings{gt}          ||=1;
  $$settings{kmercounter} ||="perl";

  # Initialize the object and then bless it
  my $self={
    seqfile    =>$seqfile,
    kmerlength =>$$settings{kmerlength},
    numcpus    =>$$settings{numcpus},
    tempdir    =>tempdir("Kmer.pm.XXXXXX",TMPDIR=>1,CLEANUP=>1),
    gt         =>$$settings{gt},
    kmercounter=>$$settings{kmercounter},

    # Values that will be filled in after analysis
    _kmers     =>{},
  };
  # Add in some other temporary files
  ($$self{kmerfileFh},$$self{kmerfile})      = tempfile("KMER.XXXXXX", DIR=>$$self{tempdir}, SUFFIX=>".tsv");
  ($$self{histfileFh},$$self{histfile})      = tempfile("HIST.XXXXXX", DIR=>$$self{tempdir}, SUFFIX=>".tsv");
  ($$self{jellyfishdbFh},$$self{jellyfishdb})= tempfile("JF.XXXXXX",   DIR=>$$self{tempdir}, SUFFIX=>".jf");

  # Make some values lc
  $$self{$_}=lc($$self{$_}) for(qw(kmercounter));

  # Set an exact parameter for the kmer counter
  if($$self{kmercounter}=~ /(pure)?.*perl/){
    $$self{kmercounter}="perl";
  } elsif($self->{kmercounter} =~ /jellyfish/){
    $$self{kmercounter}="jellyfish";
  }

  bless($self);

  $self->count; # start off the kmer counting ASAP

  return $self;
}

# Count kmers with faster programs in this order of
# priority: jellyfish (TODO: KAnalyze)
# and lastly, pure perl.
sub count{
  my($self)=@_;

  my $seqfile=$self->{seqfile};
  my $kmerlength=$self->{kmerlength};

  my $kmerHash={};

  if($self->{kmercounter} eq "perl"){
    $self->countKmersPurePerl($seqfile,$kmerlength);
  } elsif($self->{kmercounter} eq "jellyfish"){
    # TODO make JF DB file $self->{jellyfishDb} and do not return
    # a kmer count
    $self->countKmersJellyfish($seqfile,$kmerlength);
  } else {
    die "ERROR: I do not understand the kmer counter $self->{kmercounter}";
  }
}

=pod

=over

=item query

Query the set of kmers with your own query

  Arguments: query (string)
  Returns:   Count of kmers. 
              0 indicates that the kmer was not found.
             -1 indicates an invalid kmer (e.g., invalid length)

=back

=cut

sub query{
  my($self,$query)=@_;

  if(length($query) != $self->{kmerlength}){
    return -1;
  }

  my $count=0;
  if($self->{kmercounter} eq "perl"){
    my $kmers=$self->kmers();
    $count=$$kmers{uc($query)} || 0;
  } elsif($self->{kmercounter} eq "jellyfish"){
    open(my $queryFh, "jellyfish query ".$self->{jellyfishdb}." |") or die "ERROR: could not run jellyfish query: $!";
    my $db=$self->{jellyfishdb};
    my $tmp=`jellyfish query $db $query`;
    die "ERROR: could not run jellyfish query" if $?;
    chomp($tmp);
    (undef,$count)=split(/\s+/,$tmp);
  }
  
  return $count;
}

=pod

=over

=item histogram

Count the frequency of kmers.

  Arguments: none
  Returns:   Reference to an array of counts. The index of 
             the array is the frequency.

=back

=cut

sub histogram{
  my($self)=@_;
  my %hist=();
  my @hist=(0); # initialize the histogram with a count of zero kmers happening zero times
  #$hist[0]=4**$self->{kmerlength}; # or maybe it should be initialized to the total number of possibilities.

  #if(!values(%{ $self->{_kmers} } )){
  #  die "ERROR: kmers have not been counted yet. Run Kmer->count before running Kmer->histogram";
  #}

  for my $kmercount(values(%{ $self->kmers() } )){
    $hist{$kmercount}++;
  }

  # Turn this hash into an array
  for(1..max(keys(%hist))){
    $hist[$_] = $hist{$_} || 0;
    #$hist[0]=$hist[0] - $hist[$_]; # subtract off from the total space of possible kmers
  }

  $self->{hist}=\@hist;
  return \@hist;
}

sub countKmersPurePerl{
  my($self,$seqfile,$kmerlength)=@_;

  # Multithreading
  my $seqQ=Thread::Queue->new;
  my @thr;
  for(0..$self->{numcpus}-1){
    $thr[$_]=threads->new(\&_countKmersPurePerlWorker,$kmerlength,$seqQ);
  }

  # Pure perl to make this standalone... the only reason
  # we are counting kmers in Perl instead of C.
  my $fastqFh=$self->openFastq($seqfile);
  my $i=0;
  my @buffer=();
  while(<$fastqFh>){ # burn the read ID line
    $i++;
    my $seq=<$fastqFh>;
    push(@buffer, uc($seq));

    if($i % 1000000 == 0){
      $seqQ->enqueue(@buffer);
      @buffer=();
    }
    
    # Burn the quality score lines
    <$fastqFh>;
    <$fastqFh>;
  }
  close $fastqFh;

  $seqQ->enqueue(@buffer);
  
  # Send the termination signal
  $seqQ->enqueue(undef) for(@thr);

  while($seqQ->pending > @thr){
    for(1..60){
      last if($seqQ->pending <= @thr);
      sleep 1;
    }
  }

  # Join the threads and put everything into a large kmer hash
  my %kmer=();
  for(@thr){
    my $threadKmer=$_->join;
    for my $kmer(keys(%$threadKmer)){
      $kmer{$kmer}+=$$threadKmer{$kmer};
    }
  }

  # Write everything to file. The FH should still be open.
  #      Do not return the kmer.
  #      Make a new method that returns the kmer hash
  #      Do the same for jellyfish
  my $fh=$self->{kmerfileFh};
  while(my($kmer,$count)=each(%kmer)){
    # Filtering step
    if($count < $self->{gt}){
      #delete($kmer{$kmer});
      next;
    }
    
    print $fh "$kmer\t$count\n";
  }
  close $fh;

  return 1;
}

sub kmers{
  my($self)=@_;

  return $self->{_kmers} if(keys(%{ $self->{_kmers} }) > 0);

  # Dump the kmers to a tab delimited file if we are using
  # jellyfish and the user invokes this method.
  if($self->{kmercounter} eq "jellyfish"){
    $self->_dumpKmersJellyfish();
  }

  my %kmer;
  open(my $fh, $self->{kmerfile}) or die "ERROR: could not read the kmer file: $!";
  while(<$fh>){
    chomp;
    my($kmer,$count)=split /\t/;
    $kmer{$kmer}=$count;
  }
  close $fh;

  $self->{_kmers}=\%kmer;

  return \%kmer;
}

sub _countKmersPurePerlWorker{
  my($kmerlength,$seqQ)=@_; 

  my %kmer;
  while(defined(my $seq=$seqQ->dequeue)){

    my $numKmersInRead=length($seq)-$kmerlength;

    # Count kmers in a sliding window.
    # We must keep this loop optimized for speed.
    for(my $j=0;$j<$numKmersInRead;$j++){
      $kmer{substr($seq,$j,$kmerlength)}++;
    }

  }

  return \%kmer;
}


sub countKmersJellyfish{
  my($self,$seqfile,$kmerlength)=@_;
  my $basename=basename($seqfile);

  # Version checking
  my $jfVersion=`jellyfish --version`; chomp($jfVersion);
  # e.g., jellyfish 2.2.6
  if($jfVersion =~ /(jellyfish\s+)?(\d+)?/){
    my $majorVersion=$2;
    if($majorVersion < 2){
      die "ERROR: Jellyfish v2 or greater is required";
    }
  }
  
  my $outfile=$self->{jellyfishdb};

  # Counting
  my $jellyfishCountOptions="-s 10000000 -m $kmerlength -o $outfile -t $self->{numcpus}";
  my $uncompressedFastq="$self->{tempdir}/$basename.fastq";
  if($seqfile=~/\.gz$/i){
    system("zcat $seqfile > $uncompressedFastq"); die if $?;
    system("jellyfish count $jellyfishCountOptions $uncompressedFastq");
  } else {
    system("jellyfish count $jellyfishCountOptions $seqfile");
  }
  close $self->{jellyfishdbFh};
  die "Error: problem with jellyfish" if $?;
}

sub _dumpKmersJellyfish{
  my($self)=@_;
  my $kmerTsv=$self->{kmerfile};
  my $jfDb=$self->{jellyfishdb};

  return if(-s $kmerTsv > 0);

  # Dump the kmers to a tab-delimited file if it doesn't
  # already have contents
  if(-s $kmerTsv < 1){
    my $lowerCount=$self->{gt}-1;
    system("jellyfish dump --lower-count=$lowerCount --column --tab -o $kmerTsv $jfDb");
    die if $?;
  }
}

# http://www.perlmonks.org/?node_id=761662
sub which{
  my($self,$exe)=@_;
  
  my $tool_path="";
  for my $path ( split /:/, $ENV{PATH} ) {
      if ( -f "$path/$exe" && -x "$path/$exe" ) {
          $tool_path = "$path/$exe";
          last;
      }
  }
  
  return $tool_path;
}

# Opens a fastq file in a thread-safe way.
# Returns a file handle.
sub openFastq{
  my($self,$fastq)=@_;

  my $fh;

  my($name,$dir,$ext)=fileparse($fastq,@fastqExt);

  if(!grep(/$ext/,@fastqExt)){
    die "ERROR: could not read $fastq as a fastq file";
  }

  # Open the file in different ways, depending on if it
  # is gzipped or if the user has gzip installed.
  lock($fhStick);
  if($ext =~/\.gz$/){
    # use binary gzip if we can... why not take advantage
    # of the compiled binary's speedup?
    if(-e "/usr/bin/gzip"){
      open($fh,"gzip -cd $fastq | ") or die "ERROR: could not open $fastq for reading!: $!";
    }else{
      $fh=new IO::Uncompress::Gunzip($fastq) or die "ERROR: could not read $fastq: $!";
    }
  } else {
    open($fh,"<",$fastq) or die "ERROR: could not open $fastq for reading!: $!";
  }

  return $fh;
}
# In case I accidentally do $Kmer->closeFastq without thinking
# how ridiculous that is, let's just avoid that problem with
# this subroutine.
sub closeFastq{
  my($self,$fastq)=@_;
  close $fastq;
  return 1;
}

=pod

=head1 COPYRIGHT AND LICENSE

MIT license.  Go nuts.

=head1 AUTHOR

Author: Lee Katz <lkatz@cdc.gov>

For additional help, go to https://github.com/lskatz/Bio--Kmer

=cut

1;
