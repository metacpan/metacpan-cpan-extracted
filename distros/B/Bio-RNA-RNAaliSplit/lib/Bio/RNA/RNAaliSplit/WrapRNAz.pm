# -*-CPerl-*-
# Last changed Time-stamp: <2017-03-09 16:16:26 michl>

# Bio::RNA::RNAaliSplit::WrapRNAz.pm: A versatile object-oriented
# wrapper for RNAz
#
# Requires RNAz executable available to the Perl interpreter.
# This package contains code fragments from the original RNAz Perl module

package Bio::RNA::RNAaliSplit::WrapRNAz;

use version; our $VERSION = qv('0.04');
use Carp;
use Data::Dumper;
use Moose;
use Moose::Util::TypeConstraints;
use Path::Class::File;
use Path::Class::Dir;
use Path::Class;
use File::Basename;
use IPC::Cmd qw(can_run run);

my ($rnaz,$oodir);

has 'alnfilebasename' => (
			  is => 'rw',
			  isa => 'Str',
			  predicate => 'has_alnfilebasename',
			  init_arg => undef, # make this unsettable via constructor
			 );

has 'bn' => (
	     is => 'rw',
	     isa => 'Str',
	     predicate => 'has_basename',
	     documentation => q(Set this to override output basename),
	    );

has 'P' => (
	    is => 'rw',
	    isa => 'Num',
	    init_arg => undef,
	    documentation => q(SVM RNA-class probability),
	   );

has 'z' => (
	    is => 'rw',
	    isa => 'Num',
	    init_arg => undef,
	    documentation => q(Mean z-score),
	   );

has 'sci' => (
	      is => 'rw',
	      isa => 'Num',
	      init_arg => undef,
	      documentation => q(Structure conservation index),
	     );

with 'Bio::RNA::RNAaliSplit::FileDir';

sub BUILD {
  my $self = shift;
  my $this_function = (caller(0))[3];
  confess "ERROR [$this_function] \$self->ifile not available"
    unless ($self->has_ifile);
   $rnaz = can_run('RNAz') or
     croak "ERROR [$this_function] RNAz not found";
  unless($self->has_odir){
    unless($self->has_odirn){self->odirname("as")}
    $self->odir( [$self->ifile->dir,$self->odirn] );
    mkdir($self->odir);
  }
  $oodir = $self->odir->subdir("rnaz");
  mkdir($oodir);
  $self->alnfilebasename(fileparse($self->ifile->basename, qr/\.[^.]*/));

  $self->run_rnaz();
}

sub run_rnaz {
  my $self = shift;
  my $this_function = (caller(0))[3];
  my ($rnaz_outfilename,$rnaz_out);
  if ($self->has_alnfilebasename){$rnaz_outfilename = $self->alnfilebasename.".rnaz.out"}
  elsif ($self->has_basename){$rnaz_outfilename = $self->bn.".rnaz.out"}
  else{$rnaz_outfilename = "rnaz.out"}
  $rnaz_out = file($oodir,$rnaz_outfilename);
  open my $fh, ">", $rnaz_out;
  my $rnaz_cmd = $rnaz." -l -d < ".$self->ifile;
  my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
    run( command => $rnaz_cmd, verbose => 0 );
  if( !$success ) {
    print STDERR "ERROR [$this_function] Call to $rnaz unsuccessful\n";
    print STDERR "ERROR: this is what the command printed:\n";
    print join "", @$full_buf;
    croak $!;
  }
  my $stdout_buffer = join "", @$stdout_buf;
  my @out = split /\n/, $stdout_buffer;
  foreach my $line( @out){print $fh $line,"\n"}
  close($fh);

  $self->_parse_rnaz($stdout_buffer);
}

# parse RNAz output
sub _parse_rnaz {
  my ($self,$rnaz) = @_;
  my $this_function = (caller(0))[3];
  my @rnaz=split(/^/, $rnaz);
  my ($N,$identity,$columns,$decValue,$P,$z,$sci,$energy,$strand,
      $covariance,$combPerPair,$meanMFE,$consensusMFE,$consensusSeq,
      $consensusFold, $GCcontent, $ShannonEntropy);
  my @aln=();

  foreach my $i (0..$#rnaz){
    my $line=$rnaz[$i];
    $identity=$1 if ($line=~/Mean pairwise identity:\s*(-?\d+.\d+)/);
    $N=$1 if ($line=~/Sequences:\s*(\d+)/);
    if ($line=~/Reading direction:\s*(forward|reverse)/){
      $strand=($1 eq 'forward')?'+':'-';
    }
    $columns=$1 if ($line=~/Columns:\s*(\d+)/);
    $decValue=$1 if ($line=~/SVM decision value:\s*(-?\d+.\d+)/);
    $P=$1 if ($line=~/SVM RNA-class probability:\s*(-?\d+.\d+)/);
    $z=$1 if ($line=~/Mean z-score:\s*(-?\d+.\d+)/);
    $sci=$1 if ($line=~/Structure conservation index:\s*(-?\d+.\d+)/);
    $energy=$1 if ($line=~/Energy contribution:\s*(-?\d+.\d+)/);
    $covariance=$1 if ($line=~/Covariance contribution:\s*(-?\d+.\d+)/);
    $combPerPair=$1 if ($line=~/Combinations\/Pair:\s*(-?\d+.\d+)/);
    $consensusMFE=$1 if ($line=~/Consensus MFE:\s*(-?\d+.\d+)/);
    $meanMFE=$1 if ($line=~/Mean single sequence MFE:\s*(-?\d+.\d+)/);
    $GCcontent=$1 if ($line=~/G\+C content:\s(\d+.\d+)/);
    $ShannonEntropy=$1 if ($line=~/Shannon entropy:\s*(\d+.\d+)/);

    if ($line=~/^>/){
      chomp($rnaz[$i+1]);
      chomp($rnaz[$i+2]);
      if ($line=~/^>consensus/){
	$consensusSeq=$rnaz[$i+1];
	$consensusFold=substr($rnaz[$i+2],0,length($rnaz[$i+1]));
	last;
      } else {
	if ($line=~/>(.*?) (\d+) (\d+) (\+|\-) (\d+)/){
	  push @aln, {name=>$1,
		      start=>$2,
		      end=>$2+$3,
		      strand=>$4,
		      fullLength=>$5,
		      seq=>$rnaz[$i+1],
		      fold=>substr($rnaz[$i+2],0,length($rnaz[$i+1]))};
	  $i+=2;
	} elsif ($line=~/^(.*)\/(\d+)-(\d+)$/){
	  push @aln, {name=>$1,
		      start=>$2,
		      end=>$3,
		      strand=>$strand,
		      fullLength=>'',
		      seq=>$rnaz[$i+1],
		      fold=>substr($rnaz[$i+2],0,length($rnaz[$i+1]))};
	  $i+=2;
	}
      }
    }
  }

  $self->P($P);
  $self->z($z);
  $self->sci($sci);
}

1;
