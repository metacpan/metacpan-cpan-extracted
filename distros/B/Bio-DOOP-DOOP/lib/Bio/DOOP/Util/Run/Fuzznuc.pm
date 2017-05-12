package Bio::DOOP::Util::Run::Fuzznuc;

use strict;
use warnings;
use Carp qw(cluck carp verbose);

=head1 NAME

Bio::DOOP::Util::Run::Fuzznuc - Fuzznuc module

=head1 VERSION

Version 0.7

=cut

our $VERSION = '0.7';

=head1 SYNOPSIS

   #!/usr/bin/perl -w

   use Bio::DOOP::DOOP;

   $db = Bio::DOOP::DBSQL->connect("user","pass","doop-plant-1_5","localhost");

   @list = ("81001020","81001110","81001200","81001225","81001230","81001290","81001470","81001580","81001610","81001620","81001680");

   $fuzznuc = Bio::DOOP::Util::Run::Fuzznuc->new($db,'500','M',\@list,"/data/DOOP/dummy.txt");

   print $fuzznuc->get_tmp_file_name,"\n";

   $error = $fuzznuc->run('TTGGGC' , 1 , 0);

   if ($error == -1){
      die "No results or error!\n";
   }

   @res = @{$fuzznuc->get_results};

   for $result (@res){
      print $$result[0]->get_id,"| ",$$result[1]," ",$$result[2]," ",$$result[3]," ",$$result[4],"\n";
   }

=head1 DESCRIPTION

This module is a wrapper for the EMBOSS (http://emboss.sourceforge.net) program fuzznuc. You can search
for patterns in the promoter sequences.

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 new

Create new Fuzznuc object.

Arguments:

1. Bio::DOOP::DBSQL object
2. promoter type (500, 1000, 3000)
3. subset type (depends on reference species)
4. arrayref of clusters
5. temporary file name (default: /tmp/fuzznuc_run.txt, will contain fasta sequences)

  $fuzznuc = Bio::DOOP::Util::Run::Fuzznuc->new($db,500,'M',\@list,'/tmp/tmpfile');

=cut

sub new {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $promo_type           = shift;
  my $subset_type          = shift;
  my $cluster_id_list      = shift;
  my $tmp_filename         = shift;

  # TODO use File::Temp module
  if (!$tmp_filename) { $tmp_filename = "/tmp/fuzznuc_run.txt" }
  open TMP,">$tmp_filename";
  for my $cl_id (@{$cluster_id_list}){
     my $cl = Bio::DOOP::Cluster->new($db,,$cl_id,$promo_type);
     if ($cl == -1){ next }
     my $subset = $cl->get_subset_by_type($subset_type);
     if ($subset == -1){ next }
     my @seqs = @{$subset->get_all_seqs};
     for my $seq (@seqs){
        print TMP ">",$seq->get_id,"\n";
	print TMP $seq->get_raw_seq,"\n\n";
     }
  }
  close TMP;
  $self->{DB}              = $db;
  $self->{CLLIST}          = $cluster_id_list;
  $self->{TMP_FILE}        = $tmp_filename;

  bless $self;
  return($self);
}

=head2 new_by_file

Create new fuzznuc object from query file, containing cluster ids.

Arguments:
  
1. Bio::DOOP::DBSQL object
2. promoter type (500, 1000, 3000)
3. subset type (depends on reference species)
4. file containing cluster ids
5. temporary file name (default: /tmp/fuzznuc_run.txt, will contain fasta sequences)

  $fuzznuc = Bio::DOOP::Util::Run::Fuzznuc->new($db,500,'M','/tmp/clusters.txt','/tmp/tmpfile');

=cut

sub new_by_file {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $promo_type           = shift;
  my $subset_type          = shift;
  my $filename             = shift;
  my $tmp_filename         = shift;
  my @cluster_id_list;

  # TODO use File::Temp module
  if (!$tmp_filename) { $tmp_filename = "/tmp/fuzznuc_run.txt" }

  open CLUSTER_ID_FILE,$filename or cluck("No such file or directory!\n");
  open TMP,">$tmp_filename" or cluck("Can't write to the temporary file!\n");
  while(<CLUSTER_ID_FILE>){
     chomp;
     my $cl_id = $_;
     push @cluster_id_list,$cl_id;
     my $cl = Bio::DOOP::Cluster->new($db,,$cl_id,$promo_type);
     my $subset = $cl->get_subset_by_type($subset_type);
     if ($subset == -1) { next }
     my @seqs = @{$subset->get_all_seqs};
     for my $seq (@seqs){
        print TMP ">",$seq->get_id,"\n";
	print TMP $seq->get_raw_seq,"\n\n";
     }
  }
  close CLUSTER_ID_FILE;
  close TMP;

  $self->{DB}              = $db;
  $self->{CLLIST}          = \@cluster_id_list;
  $self->{TMP_FILE}        = $tmp_filename;

  bless $self;
  return($self);
}

=head2 new_by_tmp

Create new fuzznuc object from existing temporary file,
containing query sequences in fasta format.

Arguments:

1. Bio::DOOP::DBSQL object
2. file containing fasta sequences

  $fuzznuc = Bio::DOOP::Util::Run::Fuzznuc->new($db,'/tmp/sequences.fasta');

=cut

sub new_by_tmp {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $tmp_filename         = shift;

  $self->{DB}              = $db;
  $self->{TMP_FILE}        = $tmp_filename;
      
  bless $self;
  return($self);
}

=head2 get_tmp_file_name

Get the temporary file name.

   $tempname = $fuzznuc->get_tmp_file_name;

=cut

sub get_tmp_file_name {
  my $self                 = shift;
  return($self->{TMP_FILE});
}

=head2 get_emboss_version

Get the installed emboss version.

   $version = $fuzznuc->get_emboss_version;

=cut

sub get_emboss_version {
  my $self                 = shift;
  return($self->{EMBOSSVER});
}

=head2 run

Runs fuzznuc, returns 0 on success, otherwise -1.

Arguments :

1. query pattern
2. mismatch number
3. complement (0 or 1)

   $fuzznuc_error = $fuzznuc->run('AACCAGGTT','1','1');

=cut

sub run {
  my $self                 = shift;
  my $pattern              = shift;
  my $mismatch             = shift;
  my $complement           = shift;

  my $file = $self->{TMP_FILE};

  my @result = `fuzznuc $file -pattern='$pattern' -sformat=fasta -pmismatch=$mismatch -complement=$complement -stdout -auto`;
  
  my $seq_id;
  my $start;
  my $end;
  my $mism;
  my $hitseq;
  my @parsed;
  my $strand;

  if ($#result == -1) { return(-1) } #No results or an error happened.
  for my $line (@result){
     if ($line =~ / Sequence: (\S+)/){
        $seq_id = $1;
     }
     if ($line =~ /\s+(\d+)\s+(\d+)\s+(\w+)\s+([0123456789.]+)\s+(\w+)/){
        $start  = $1;
	$end    = $2;
	$mism   = $4;
	$hitseq = $5;
	$mism =~ s/\./0/;
	$strand = $start < $end ? 1 : -1;
	push @parsed, "$seq_id $start $end $mism $hitseq $strand";
     }
  }

  $self->{RESULT} = \@parsed;
  return(0);
}

=head2 run_background

Runs fuzznuc in background, returns the process id.

Arguments :

1. query pattern
2. mismatch number
3. complement (0 or 1)
4. output filename

   $fuzznuc_pid = $fuzznuc->run_background('AACCAGGTT','1','1','/tmp/fuzznuc_result.txt');

=cut

sub run_background {
  my $self                 = shift;
  my $pattern              = shift;
  my $mismatch             = shift;
  my $complement           = shift;
  my $outfile              = shift;
  my $file = $self->{TMP_FILE};
  my $pid;

  unless($pid = fork){
     `fuzznuc $file -pattern='$pattern' -pmismatch=$mismatch -sformat=fasta -complement=$complement -outfile=$outfile`;
  }

  return($pid);
}

=head2 get_raw_results

Returns an arrayref of arrays with the raw fuzznuc results, without Bio::DOOP objects.
This is much faster as it does not use the database.

The results contain the following:

1. sequence ID
2. hit start
3. hit end
4. mismatch number
5. hit sequence
6. hit strand

   @result = @{$fuzznuc->get_raw_results};

=cut

sub get_raw_results {
  my $self                = shift;

  my @fuzznuc_res;
  my $res = $self->{RESULT};
  my $seq_id;
  my $start;
  my $end;
  my $mism;
  my $hitseq;
  my $strand;

  for my $line (@{$res}){
     ($seq_id,$start,$end,$mism,$hitseq,$strand) = split(/\s+/,$line);

     push @fuzznuc_res,[$seq_id,$start,$end,$mism,$hitseq,$strand];
  }

  return(\@fuzznuc_res);
}

=head2 get_results

Returns an arrayref of arrays with sequence objects and other information of the results.

The results contain the following:

1. Bio::DOOP::Sequence object
2. hit start
3. hit end
4. mismatch number
5. hit sequence
6. hit strand

   @result = @{$fuzznuc->get_raw_results};

=cut

sub get_results {
  my $self                = shift;

  my @fuzznuc_res;
  my $res = $self->{RESULT};
  my $seq_id;
  my $start;
  my $end;
  my $mism;
  my $hitseq;
  my $strand;

  for my $line (@{$res}){
     ($seq_id,$start,$end,$mism,$hitseq,$strand) = split(/\s+/,$line);
    
     my $seq = Bio::DOOP::Sequence->new_from_dbid($self->{DB},$seq_id);
     push @fuzznuc_res,[$seq,$start,$end,$mism,$hitseq,$strand];
  }

  return(\@fuzznuc_res);
}

=head2 get_results_from_file

Returns an arrayref of arrays with sequence objects and other information of the results
from a results file. With this method you can fetch the results of different fuzznuc objects.

The results contain the following:

1. Bio::DOOP::Sequence object
2. hit start
3. hit end
4. mismatch number
5. hit sequence
6. hit strand

   @result = @{$fuzznuc->get_results_from_file};

=cut

sub get_results_from_file {
  my $self                 = shift;
  my $filename             = shift;

  my $seq_id;
  my $start;
  my $end;
  my $mism;
  my $hitseq;
  my @parsed;
  my $strand;

  open FILE, $filename or return(-1);
  while(<FILE>){
     chomp;
     my $line = $_;
     if ($line =~ / Sequence: (\S+)/){
        $seq_id = $1;
     }
     if ($line =~ /\s+(\d+)\s+(\d+)\s+(\w+)\s+([0123456789.]+)\s+(\w+)/){
        $start  = $1;
	$end    = $2;
	$mism   = $4;
	$hitseq = $5;
	$mism =~ s/\./0/;
	$strand = $start < $end ? 1 : -1;
        my $seq = Bio::DOOP::Sequence->new($self->{DB},$seq_id);
	push @parsed, [$seq,$start,$end,$mism,$hitseq,$strand];
     }
  }
  close FILE;

  $self->{RESULT} = \@parsed;
  return(\@parsed);
}

1;
