#!/usr/bin/env perl
package Bio::Sketch::Mash;
use strict;
use warnings;
use Class::Interface qw/implements/;
use Exporter qw(import);
use File::Basename qw/fileparse basename dirname/;
use Data::Dumper;

use JSON ();
use Encode qw/encode decode/;

&implements( 'Bio::Sketch' );

our $VERSION = 0.8;

our @EXPORT_OK = qw(raw_mash_distance);

local $0=basename $0;

# If this is used in a scalar context, $self->toString() is called
use overload '""' => 'toString';

# These functions are unimplemented but have to be
# listed because of the interface.
sub sketch{
  ...;
}
sub paste{
  ...;
}

=pod

=head1 NAME

Bio::Sketch::Mash

=head1 SYNOPSIS

A module to read `mash info` output and transform it

  use strict;
  use warnings;
  use Bio::Sketch::Mash;

  # Sketch all fastq files into one mash file.
  # Mash sketching is not implemented in this module.
  system("mash sketch *.fastq.gz > all.msh");
  die if $?;

  # Read the mash file.
  my $msh = Bio::Sketch::Mash->new("all.msh");
  # All-vs-all distances
  my $distHash = $msh->dist($msh);

  # Read a mash file, write it to a json-formatted file
  my $msh2 = Bio::Sketch::Mash->new("all.msh");
  $msh2->writeJson("all.json");
  # Read the json file
  my $mashJson = Bio::Sketch::Mash->new("all.json");
  my $dist = $msh2->dist($mashJson); # yields a zero distance

=head1 DESCRIPTION

This is a module to read mash files produced by the Mash executable. For more information on Mash, see L<mash.readthedocs.org>.  This module is capable of reading mash files.  Future versions will read/write mash files.

=head1 METHODS

=over

=item Bio::Sketch::Mash->new("filename.msh",\%options);

Create a new instance of Bio::Sketch::Mash.  One object per set of files.

  Arguments:  Sketch filename (valid types/extensions are .msh, .json, .json.gz)
              Hash of options (none so far)
  Returns:    Bio::Sketch::Mash object

=back

=cut

sub new{
  my($class,$filename,$settings)=@_;

  my $self={
    file      => $filename,
    kmer      => -1, # eg, 21
    preserveCase=>-1,# eg, false
    alphabet  => "", # eg, AGCT
    canonical => -1, # eg, true/false
    sketchSize=> -1, # eg, 1000
    hashType  => "", # eg, "MurmurHash3_x64_128"
    hashBits  => -1, # eg, 64
    hashSeed  => -1, # eg, 42
    sketches  => [], # Array of hashes. Each hash has keys
                     #  name    => original filename
                     #  length  => integer of estimated genome size
                     #  comment => string description
                     #  hashes  => list of integers
  };
  bless($self,$class);

  if(!defined($filename)){
    die "ERROR: no file was given to ".$class."->new";
    return {};
  }
  if(!-e $filename){
    die "ERROR: could not find file $filename";
  }

  $self->loadMsh($filename)
    or $self->loadJson($filename)
    or die "ERROR: could not load $filename as either msh or json";

  return $self;
}


=pod

=over

=item $msh->loadMsh("filename.msh")

Changes which file is used in the object and updates internal object information. This method is ordinarily used internally only.

  Arguments: One mash file
  Returns:   self

=back

=cut

sub loadMsh{
  my($self,$msh)=@_;
  
  my $json=JSON->new;
  $json->utf8;           # If we only expect characters 0..255. Makes it fast.
  $json->allow_nonref;   # can convert a non-reference into its corresponding string
  $json->allow_blessed;  # encode method will not barf when it encounters a blessed reference
  $json->pretty;         # enables indent, space_before and space_after

  my $jsonStr = `mash info -d $msh 2>/dev/null`;
  #die "ERROR running mash on $msh" if $?;
  if($?){
    return 0;
  }

  # Need to check for valid utf8 or not
  eval{ my $strCopy=$jsonStr; decode('utf8', $strCopy, Encode::FB_CROAK) }
    or die "ERROR: mash info -d yielded non-utf8 characters for this file: $msh";

  my $mashInfo = $json->decode($jsonStr);

  for my $key(qw(kmer preserveCase alphabet canonical sketchSize hashType hashBits hashSeed sketches)){
    $$self{$key} = $$mashInfo{$key};
  }
  
  return $self;
}

=pod

=over

=item $msh->loadJson("filename.msh")

Changes which file is used in the object and updates internal object information. This method is ordinarily used internally only.

  Arguments: One JSON file describing a Mash sketch
  Returns:   self

=back

=cut

sub loadJson{
  my($self,$filename)=@_;
  
  my $json=JSON->new;
  $json->utf8;           # If we only expect characters 0..255. Makes it fast.
  $json->allow_nonref;   # can convert a non-reference into its corresponding string
  $json->allow_blessed;  # encode method will not barf when it encounters a blessed reference
  $json->pretty;         # enables indent, space_before and space_after

  my $jsonStr="";
  my $fh;
  if($filename=~/\.gz$/i){
    open($fh, "gzip -cd '$filename' |") or die "ERROR: could not gzip -cd $filename: $!";
  } else {
    open($fh, $filename) or die "ERROR: could not read $filename: $!";
  }
  while(<$fh>){
    $jsonStr.=$_;
  }
  close $fh;

  # Need to check for valid utf8 or not
  eval{ my $strCopy=$jsonStr; decode('utf8', $strCopy, Encode::FB_CROAK) }
    or die "ERROR: this file has non-utf8 characters: $filename";

  my $mashInfo = eval{
    $json->decode($jsonStr);
  };
  if($@){
    return 0;
  }

  for my $key(qw(kmer preserveCase alphabet canonical sketchSize hashType hashBits hashSeed sketches)){
    $$self{$key} = $$mashInfo{$key};
  }

  return $self;
}

=pod

=over

=item $msh->writeJson("filename.json")

Writes contents to a file in JSON format

  Arguments: One filename
  Returns:   self

=back

=cut

sub writeJson{
  my($self, $filename) = @_;

  my $json=JSON->new;
  $json->utf8;           # If we only expect characters 0..255. Makes it fast.
  $json->allow_nonref;   # can convert a non-reference into its corresponding string
  $json->allow_blessed;  # encode method will not barf when it encounters a blessed reference
  $json->pretty;         # enables indent, space_before and space_after
  
  my $hash={};
  for my $key(qw(kmer preserveCase alphabet canonical sketchSize hashType hashBits hashSeed sketches)){
    $$hash{$key} = $$self{$key};
  }

  my $fh;
  if($filename=~/\.gz$/){
    open($fh, " | gzip -c > $filename") or die "ERROR: could not write gzipped contents to $filename: $!";
  } else {
    open($fh, ">", $filename) or die "ERROR: could not write to $filename: $!";
  }
  print $fh $json->encode($hash);
  close $fh;

  return $self;
}

=pod

=over

=item $msh->dist($msh2)

Returns a hash describing distances between sketches represented by
this object and another object. If there are multiple sketches per
object, then all sketches in this object will be compared against
all sketches in the other object.

  Arguments: One Bio::Sketch::Mash object
  Returns:   reference to a hash of hashes. Each value is a number.

Aliases: distance(), mashDist()

=back

=cut

sub dist{
  my($self, $other)=@_;
  my %dist = ();

  my $k = $$self{kmer};

  # TODO check class of $other

  my $numFromSketches = scalar(@{ $self->{sketches} });
  my $numToSketches   = scalar(@{ $other->{sketches} });

  for(my $i=0; $i<$numFromSketches; $i++){
    my $fromHashes = $$self{sketches}[$i]{hashes};
    my $fromName   = $$self{sketches}[$i]{name};
    for(my $j=0; $j<$numToSketches; $j++){
      my $toHashes = $$other{sketches}[$j]{hashes};
      my $toName   = $$other{sketches}[$j]{name};

      my ($common, $total) = raw_mash_distance($fromHashes, $toHashes);
      if($total == 0){
        die "Internal error: total kmers compared between $fromName and $toName were zero!";
      }
      my $jaccard = $common/$total;
      my $mashDist = 0; # by default
      if($jaccard > 0){
        $mashDist= -1/$k * log(2*$jaccard / (1+$jaccard));
      }
      $mashDist = sprintf("%0.7f", $mashDist); # rounding to maintain compatibility with exec
      $dist{$fromName}{$toName} = $mashDist;
      $dist{$toName}{$fromName} = $mashDist;
    }
  }
  return \%dist;
}
# Some aliases for dist()
sub distance{
  goto &dist;
}
sub mashDist{
  goto &dist;
}

=pod

=over

=item Bio::Sketch::Mash::raw_mash_distance($array1, $array2)

Returns the number of sketches in common and the total number of sketches between two lists.
The return type is an array of two elements.
This function is used internally with $msh->dist and assumes that the 
hashes are already sorted.

  Arguments: A list of integers
             A list of integers
  Returns:   (countOfInCommon, totalNumber)

  Example:
    
    my $R1 = [1,2,3];
    my $R2 = [1,2,4];
    my($common, $total) = Bio::Sketch::Mash::raw_mash_distance($R1,$R2);
    # $common => 2
    # $total  => 3

=back

=cut

# https://github.com/onecodex/finch-rs/blob/master/src/distance.rs#L34
sub raw_mash_distance{
  my($hashes1, $hashes2) = @_;

  my $i      = 0;
  my $j      = 0;
  my $common = 0;
  my $total  = 0;

  my $sketch_size = @$hashes1;
  my $sketch_size2= @$hashes2;
  while($total < $sketch_size && $i < $sketch_size && $j < $sketch_size2){

    if($$hashes1[$i] < $$hashes2[$j]){
      $i+=1;
    } elsif($$hashes1[$i] > $$hashes2[$j]){
      $j+=1;
    } elsif($$hashes1[$i] == $$hashes2[$j]){
      $i+=1;
      $j+=1;
      $common+=1;
    } 

    $total += 1;
  }

  #if($total < $sketch_size){
  if($total < $sketch_size || $total < $sketch_size2){
    if($i < $sketch_size){
      $total += $sketch_size - 1;
    }

    if($j < $sketch_size2){
      $total += $sketch_size2 - 1;
    }

    if($total > $sketch_size){
      $total = $sketch_size;
    }
  }

  return ($common, $total);
}

=pod

=over

=item $msh->fix()

Fixes a mash sketch if it is broken at all. For now this
just sorts hashes but this subroutine could contain more
fixes in the future.

  Arguments: None
  Returns:   $self

=back

=cut

sub fix{
  my($self) = @_;

  for my $sketches(@{ $self->{sketches} }){
    my @sortedHashes = sort {$a <=> $b} @{ $$sketches{hashes} };
    $$sketches{hashes} = \@sortedHashes;
  }

  return $self;
}

##### Utility methods

sub toString{
  my($self)=@_;
  my $return="Bio::Sketch::Mash object with " .scalar(@{ $self->{sketches} })." file(s):\n";
  for my $sketch(@{ $self->{sketches} }){
    $return.=$$sketch{name}."\n";
  }
  
  return $return;
}

=pod

=head1 COPYRIGHT AND LICENSE

MIT license.

=head1 AUTHOR

Author:  Lee Katz <lkatz@cdc.gov>

For additional help, go to https://github.com/lskatz/perl-mash

CPAN module at http://search.cpan.org/~lskatz/perl-mash

=cut

1; # gotta love how we we return 1 in modules. TRUTH!!!

