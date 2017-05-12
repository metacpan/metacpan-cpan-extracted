package Bio::DOOP::Util::Run::Mofext;

use strict;
use warnings;
use Carp qw(cluck carp verbose);

=head1 NAME

Bio::DOOP::Util::Run::Mofext - Mofext module

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

=head1 SYNOPSIS

   #!/usr/bin/perl -w

   use Bio::DOOP::DOOP;

   $db = Bio::DOOP::DBSQL->connect("user","pass","doop-plant-1_5","localhost");

   @list = ("81001020","81001110","81001200","81001225","81001230","81001290","81001470","81001580","81001610","81001620","81001680","81001680","81001690");

   $mofext = Bio::DOOP::Util::Run::Mofext->new($db,'500','M',\@list);

   $mofext->set_tmp_file_name("/data/DOOP/dummy.txt");

   print $mofext->get_tmp_file_name,"\n";

   $error = $mofext->write_to_tmp;

   if($error != 0){
      die "Write error!\n";
   }

   $error = $mofext->run('TTGGGC' , 6 , 0.6 , '/data/default_matrix' );

   if ($error == -1){
      die "No results or error!\n";
   }

   @res = @{$mofext->get_results};

   # Returns the motif objects, score and extended score.
   for $result (@res){
      print $$result[0]->get_id," ",$$result[1],"$$result[2]","\n";
   }

=head1 DESCRIPTION

Mofext is a fuzzy sequence pattern search tool developed by Tibor Nagy. This module 
is a wrapper object for mofext. It allows the user to search for similar motifs in the 
DOOP database.

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 new

Create new Mofext object.

Arguments:

1. Bio::DOOP::DBSQL object
2. promoter type (500, 1000, 3000)
3. subset type (depends on reference species)
4. arrayref of cluster ids

   $mofext = Bio::DOOP::Util::Run::Mofext->new($db,500,'B',\@list);

=cut

sub new {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $promo_type           = shift;
  my $subset_type          = shift;
  my $cluster_id_list      = shift;
  my @motif_collection;

  for my $cl_id (@{$cluster_id_list}){
     my $cl      = Bio::DOOP::Cluster->new($db,$cl_id,$promo_type);
     if ($cl == -1){ next }
     my $subset  = $cl->get_subset_by_type($subset_type);
     if ($subset == -1){ next }
     my $motifs  = $subset->get_all_motifs;
     if($motifs  == -1){ next }
     for my $motif (@$motifs){
        push @motif_collection, [$motif->get_id,$motif->seq];
     }
  }

  $self->{DB}              = $db;
  $self->{CLLIST}          = $cluster_id_list;
  # TODO use File::Temp module
  $self->{TMP_FILE}        = "/tmp/mofext_run.txt";
  $self->{MOTIF_COLL}      = \@motif_collection;

  bless $self;
  return($self);
}

=head2 new_by_file

Create a new Mofext object from query file, containing cluster ids, one per line.

Arguments:

1. Bio::DOOP::DBSQL object
2. promoter type (500, 1000, 3000)
3. subset type (depends on reference species)
4. name of file with cluster ids

   $mofext = Bio::DOOP::Util::Run::Mofext->new_by_file($db,500,'B','/tmp/clusters.txt');

=cut

sub new_by_file {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $promo_type           = shift;
  my $subset_type          = shift;
  my $filename             = shift;
  my @motif_collection;
  my @cluster_id_list;

  open CLUSTER_ID_FILE,$filename or cluck("No such file or directory!\n");
  while(<CLUSTER_ID_FILE>){
     chomp;
     my $cl_id = $_;
     push @cluster_id_list,$cl_id;
     my $cl = Bio::DOOP::Cluster->new($db,$cl_id,$promo_type);
     my $subset = $cl->get_subset_by_type($subset_type);
     if ($subset == -1) { next }
     my $motifs = $subset->get_all_motifs;
     if($motifs == -1){ next }
     for my $motif (@$motifs){
        push @motif_collection, [$motif->get_id,$motif->seq];
     }
  }
  close CLUSTER_ID_FILE;

  $self->{DB}              = $db;
  $self->{CLLIST}          = \@cluster_id_list;
  # TODO use File::Temp module
  $self->{TMP_FILE}        = "/tmp/mofext_run.txt";
  $self->{MOTIF_COLL}      = \@motif_collection;

  bless $self;
  return($self);
}

=head2 new_by_tmp

Create a new Mofext object from an existing temporary file containing conserved motifs. It is useful in some cases,
because the new constructor is very slow when you use large cluster lists. If you use this constructor, you don't 
need to use the set_tmp_file_name and write_to_tmp methods.

Arguments:

1. Bio::DOOP::DBSQL object
2. temporary file name

   $mofext = Bio::DOOP::Util::Run::Mofext->new_by_tmp($db,"/tmp/motifs.txt");

=cut

sub new_by_tmp {
  my $self                 = {};
  my $dummy                = shift;
     $self->{DB}           = shift;
     $self->{TMP_FILE}     = shift;

  bless $self;
  return($self);
}


=head2 get_tmp_file_name

Get the name of the temporary file containing the motifs.

   $tmp_name = $mofext->get_tmp_file_name;

=cut

sub get_tmp_file_name {
  my $self                 = shift;
  return($self->{TMP_FILE});
}

=head2 set_tmp_file_name

Set the temporary file name.

   $mofext->set_tmp_file_name('/tmp/motifs.txt');

=cut

sub set_tmp_file_name {
  my $self                 = shift;
  my $file_name            = shift;
  $self->{TMP_FILE} = $file_name;
}

=head2 write_to_tmp

Write out the collected motifs to the temporary file.

   $write_error = $mofext->write_to_tmp;

=cut

sub write_to_tmp {
  my $self                 = shift;

  open OUT,">".$self->{TMP_FILE} or return(-1);
  for my $motif (@{$self->{MOTIF_COLL}}) {
     print OUT $$motif[0]," ",$$motif[1]," ",length($$motif[1]),"\n";
  }
  close OUT;

  return(0);
}

=head2 run

Runs mofext, returns 0 on success, otherwise -1.

Arguments:

1. query sequence
2. wordsize
3. cutoff
4. matrix file path/name

A typical matrix looks like this:

11  A   T   G   C   S   W   R   Y   K   M   N
A   5  -4  -4  -4  -4   1   1  -4  -4   1  -2
T  -4   5  -4  -4  -4   1  -4   1   1  -4  -2
G  -4  -4   5  -4   1  -4   1  -4   1  -4  -2
C  -4  -4  -4   5   1  -4  -4   1  -4   1  -2
S  -4  -4   1   1  -1  -4  -2  -2  -2  -2  -1
W   1   1  -4  -4  -4  -1  -2  -2  -2  -2  -1
R   1  -4   1  -4  -2  -2  -1  -4  -2  -2  -1
Y  -4   1  -4   1  -2  -2  -4  -1  -2  -2  -1
K  -4   1   1  -4  -2  -2  -2  -2  -1  -4  -1
M   1  -4  -4   1  -2  -2  -2  -2  -4  -1  -1
N  -2  -2  -2  -2  -1  -1  -1  -1  -1  -1  -1

   $mofext_error = $mofext->run('AAGTKSAAT','7','90','/data/run/matrix.txt')

=cut

sub run {
  my $self                 = shift;
  my $query                = shift;
  my $wordsize             = shift;
  my $cutoff               = shift;
  my $matrix_file          = shift;

  my %seen;

  my $params = "-q $query -m $matrix_file -w $wordsize -c $cutoff -d ".$self->get_tmp_file_name." -o iseqDfF";
  my @results = `mofext $params`;

  my @id_uniq = grep { ! $seen{ $_ }++ } @results;

  if ($#id_uniq == -1){return(-1)} # No result.

  $self->{RESULT} = \@id_uniq;  # Arrayref of motif ids.
  return(0);
}

=head2 run_background

Runs mofext in background, returns the process id.

Arguments:

1. query sequence
2. wordsize
3. cutoff
4. matrix file path/name
5. output file path/name

   $mofext_pid = $mofext->run_background('AAGTKSAAT','7','90','/data/run/matrix.txt','/data/run/mofext_results.txt');

=cut

sub run_background {
  my $self                 = shift;
  my $query                = shift;
  my $wordsize             = shift;
  my $cutoff               = shift;
  my $matrix_file          = shift;
  my $outfile              = shift;
  my $pid;

  unless($pid = fork){

  my $params = "-q $query -m $matrix_file -w $wordsize -c $cutoff -d ".$self->get_tmp_file_name." -o iseqDfF";
  my @results = `mofext $params | sort | uniq >$outfile`;
  }

  return($pid);
}

=head2 get_results

Returns an arrayref of arrays with motif objects and other information of the results.

The results contain the following:

1. Bio::DOOP::Motif object
2. motif score
3. motif extended score
4. full hit sequence
5. alignment start position in the query sequence
6. alignment start position in the hit sequence

   @result = @{$mofext->get_results};

=cut

sub get_results {
  my $self                 = shift;

  my $res = $self->{RESULT};
  my @mofext_res;
  my $id;
  my $score;
  my $extscore;
  my $fullhit;
  my $querystart;
  my $hitstart;
  my $querysub;

  for my $line (@{$res}) {
     chomp($line);
     ($id,$score,$extscore,$fullhit,$querystart,$hitstart) = split(/ /,$line);
     my $motif     = Bio::DOOP::Motif->new($self->{DB},$id);
     push @mofext_res, [$motif,$score,$extscore,$querysub,$fullhit,$querystart,$hitstart];
  }

  return(\@mofext_res);
}

=head2 get_results_from_file

Returns an arrayref of arrays with motif objects and other information of the results
from a results file. With this method you can fetch the results of different mofext objects.

The results contain the following:

1. Bio::DOOP::Motif object
2. motif score
3. motif extended score
4. full hit sequence
5. alignment start position in the query sequence
6. alignment start position in the hit sequence

   @result = @{$mofext->get_results_from_file};

=cut

sub get_results_from_file {
  my $self                 = shift;
  my $filename             = shift;

  my @mofext_res;
  my $id;
  my $score;
  my $extscore;
  my $fullhit;
  my $querystart;
  my $hitstart;
  my $querysub;

  open RES,$filename or return(-1);
  while(<RES>){
     my $line = $_;
     chomp($line);
     ($id,$score,$extscore,$fullhit,$querystart,$hitstart) = split(/ /,$line);
     my $motif     = Bio::DOOP::Motif->new($self->{DB},$id);
     push @mofext_res, [$motif,$score,$extscore,$querysub,$fullhit,$querystart,$hitstart];
  }
  close RES;
  return(\@mofext_res);
}

1;
