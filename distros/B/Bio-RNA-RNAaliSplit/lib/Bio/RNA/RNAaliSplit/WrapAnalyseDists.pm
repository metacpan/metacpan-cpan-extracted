# -*-CPerl-*-
# Last changed Time-stamp: <2019-01-07 00:39:06 mtw>

# Bio::RNA::RNAaliSplit::WrapAnalyseDists.pm: Wrapper for computing
# split decompositions
#
# Requires AnalyseDists executable from the ViennaRNA package
# available to the Perl interpreter

package Bio::RNA::RNAaliSplit::WrapAnalyseDists;

use version; our $VERSION = qv('0.09');
use Carp;
use Data::Dumper;
use Moose;
use IPC::Cmd qw(can_run run);
use Array::Set qw(set_diff);
use Digest::MD5 qw(md5_base64);
use Path::Class;
use File::Path qw(make_path);
#use diagnostics;

my ($analysedists,$oodir);
my %sets = ();

has 'basename' => (
		   is => 'rw',
		   isa => 'Str',
		   predicate => 'has_basename',
		   );

has 'splits' => (
		 is => 'rw',
		 isa => 'ArrayRef',
		 default => sub { [] },
		 predicate => 'has_splits',
		 traits => ['Array'],
		 handles => {
			     allsplits => 'elements',
			     count     => 'count',
			     add       => 'push',
			     pop       => 'pop',
			    },
		);

has 'nr_splits' => (
		    is => 'rw',
		    isa => 'Num',
		    predicate => 'has_nr_splits',
		   );

has 'dim' => (
	      is => 'rw',
	      isa => 'Num',
	      predicate => 'has_dim',
	     );

with 'FileDirUtil';
with 'Bio::RNA::RNAaliSplit::Roles';

sub BUILD {
  my $self = shift;
  my $this_function = (caller(0))[3];
  confess "ERROR [$this_function] \$self->ifile not available"
    unless ($self->has_ifile);
   $analysedists = can_run('AnalyseDists') or
    croak "ERROR [$this_function] AnalyseDists not found";
  unless($self->has_odir){
    unless($self->has_dirnam){self->dirnam("as")}
    $self->odir( [$self->ifile->dir,$self->dirnam] );
  }
  $oodir = $self->odir->subdir("analysedists");
  my @created = make_path($oodir, {error => \my $err});
  confess "ERROR [$this_function] could not create output directory $self->oodir"
      if (@$err);
  $self->dim( $self->_get_dim() );

  # do computation
  $self->NeighborJoining();
  $self->SplitDecomposition();
  $self->nr_splits($self->count);
}

sub NeighborJoining {
  # TODO  warn if negative branch lengths occur
  my $self = shift;
  my $this_function = (caller(0))[3];
  my ($nj_outfilename,$nj_treefilename,$nj_out,$nj_tree);

  if ($self->has_basename){
    $nj_outfilename = $self->basename.".nj.out";
    $nj_treefilename = $self->basename.".nj.ps";
  }
  else{
    $nj_outfilename = "nj.out";
    $nj_treefilename = "nj.ps";
  }
  $nj_out = file($oodir,$nj_outfilename);
  $nj_tree = file($oodir,$nj_treefilename);
  open my $fh, ">", $nj_out;

  my $ad_cmd = $analysedists." -Xn < ".$self->ifile;
  my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
    run( command => $ad_cmd, verbose => 0 );
  if( !$success ) {
    print STDERR "ERROR [$this_function] Call to $analysedists unsuccessful\n";
    print STDERR "ERROR: this is what the command printed:\n";
    print join "", @$full_buf;
    croak $!;
  }
  my $stdout_buffer = join "",@$stdout_buf;
  my @out = split /\n/, $stdout_buffer;
  foreach my $line( @out){print $fh $line,"\n"}
  close($fh);
  rename "nj.ps", $nj_tree;
  $self->_parse_nj($stdout_buffer);
}

# parse the output of AnalyseDists -Xn
# populate array of hashes, each holding two sets of nodes corresponding to splits
sub _parse_nj {
  my ($self,$nj) = @_;
  my $this_function = (caller(0))[3];
  my %data = ();
  my $num;
  my $count = 1;
  my @lines =  split /\n/,$nj;
  foreach my $line (@lines){
    my @s1 = ();
    my @set1 = ();
    my @set2 = ();
    next if ($line =~ m/^>\s+\D/);
    if ($line =~ m/^>\s+(\d+)/){$num = $1;next}
    last if ($count++ >= $num);
    my @all = (1..$num);
    #print " #### $line\n";
    croak "ERROR [$this_function] Cannot parse neighbor joining graph line\n$line\n"
      unless ($line =~ m/^\s*(\d+)\s+(\d+)\s+(\-?\d+\.\d+)\s+(\-?\d+\.\d+)/g);
    my $i = $1;
    my $j = $2;

    push @{$data{$i}}, $j;
    if (exists $data{$j}){push @{$data{$i}}, @{$data{$j}} };
    #    print Dumper(\%data);
    push @s1, $i;  # populate set1
    push @s1, @{$data{$i}};
    @set1 =  sort {$a <=> $b} @s1;
    my @diff =  set_diff(\@all, \@set1);
    @set2 =  sort {$a <=> $b} @{$diff[0]};
    my $set1_key = md5_base64(join "_", @set1);
    my $set2_key = md5_base64(join "_", @set2);
    if (!exists($sets{$set1_key}) && !exists($sets{$set2_key})){
      my $type;
      $sets{$set1_key} = \@set1; # lookup table for previously seen sets
      $sets{$set2_key} = \@set2;
      next if (scalar(@set1) == "0"); # skip empty sets (ie input alignment)
      next if (scalar(@set2) == "0");
      if(scalar(@set1)==1||scalar(@set2)==1){$type="NJT"} # trivial
      else{$type="NJN"} # non-trivial
      $self->add( {S1=>\@set1,S2=>\@set2,ori=>"NJ",type=>$type} );
    }
    else{
      #print STDERR "INFO [$this_function] previously identified sets \n@set1\n@set2\n";
    }
#    print Dumper(\@set1);
#    print Dumper(\@set2);
#    print "+++++++++++++++++++++++++++++++++++\n";
  }
}

sub SplitDecomposition {
  my $self = shift;
  my $this_function = (caller(0))[3];
  my ($sd_outfilename,$sd_out);
  if ($self->has_basename){$sd_outfilename = $self->basename.".sd.out"}
  else{$sd_outfilename = "sd.out"}
  $sd_out = file($oodir,$sd_outfilename);
  open my $fh, ">", $sd_out;

  my $sd_cmd = $analysedists." -Xs < ".$self->ifile;
  my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
    run( command => $sd_cmd, verbose => 0 );
  if( !$success ) {
    print STDERR "ERROR [$this_function] Call to $analysedists unsuccessful\n";
    print STDERR "ERROR: this is what the command printed:\n";
    print join "", @$full_buf;
    croak $!;
  }
  my $stdout_buffer = join "", @$stdout_buf;
  my @out = split /\n/, $stdout_buffer;
  foreach my $line( @out){print $fh $line,"\n"}
  close($fh);
  $self->_parse_sd($stdout_buffer); # parse split graph data
}

# parse the output of AnalyseDists -Xs
# populate array of hashes, each holding two sets of nodes corresponding to splits
sub _parse_sd {
  my ($self,$sd) = @_;
  my $this_function = (caller(0))[3];
  my $num;
  my @lines =  split /\n/,$sd;
  foreach my $line (@lines){
    next if ($line =~ m/^>\s+\D/);
    if ($line =~ m/^>\s+(\d+)/){$num = $1;next}
    last if ($line =~ m/^\s*\d+\.\d+\s+\:\s+\{\s+\[Split prime fraction\]\s+\}/g );
 #   print "$line\n";
    croak "ERROR [$this_function] Cannot parse split graph line\n$line\n"
      unless ($line =~ m/^\s*\d+\s+\d+\.\d+\s+:\s+\{\s+([\d+\s+]+)\|/g);
    my @foo = split /\s+/, $1; # set 1
    my @moo = (1 .. $self->dim);
    my @bar = (); # set 2
    foreach my $i (@moo){
      push (@bar, $i) unless ( grep {$i == $_}@foo );
    }
    my @set1 = sort {$a <=> $b} @foo;
    my @set2 = sort {$a <=> $b} @bar;
    my $set1_key = md5_base64(join "_", @set1);
    my $set2_key = md5_base64(join "_", @set2);
    if (!exists($sets{$set1_key}) && !exists($sets{$set2_key})){
      my $type;
      $sets{$set1_key} = \@set1; # lookup table for previously seen sets
      $sets{$set2_key} = \@set2;
      if (scalar(@set1)==1 || scalar(@set2)==1){$type="SDT"} # trivial calse
      else {$type="SDN"}
      $self->add( {S1=>\@set1,S2=>\@set2,ori=>"SD",type=>$type} );
    }
    else{
    #  print STDERR "INFO [$this_function] previously identified sets \n@set1\n@set2\n";
    }
  }
}

sub _get_dim {
  my $self = shift;
  my $this_function = (caller(0))[3];
  my $dim = -1 ;
  open my $fh, "<", $self->ifile or die $!;
  while(<$fh>){
    if (m/^>\s+X\s+(\d+)/){$dim = $1;last;}
  }
  croak "ERROR [$this_function] could not parse dimension from input matrix"
    if ($dim == -1);
  close($fh);
  return $dim;
}

1;

