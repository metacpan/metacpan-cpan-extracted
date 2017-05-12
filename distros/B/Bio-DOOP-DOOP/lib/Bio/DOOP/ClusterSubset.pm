package Bio::DOOP::ClusterSubset;

use strict;
use warnings;

=head1 NAME

Bio::DOOP::ClusterSubset - One subset of a cluster

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

  @cluster_subsets = @{$cluster->get_all_subsets};


=head1 DESCRIPTION

This object represents one subset of a cluster. A subset is a set of homologous sequences,
hopefully monophyletic, grouped by evolutionary distance from the reference species (Arabidopsis
or human).

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 new

Creates a new subset object from the subset primary id. You usually won't need this, as you will create
the subsets from a Bio::DOOP::Cluster object, based on the subset type.
  
Return type: Bio::DOOP::ClusterSubset object

  $cluster_subset = Bio::DOOP::ClusterSubset->new($db,"123");

=cut

sub new {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $id                   = shift;

  my $ret    = $db->query("SELECT * FROM cluster_subset WHERE subset_primary_id = \"$id\";");

  if ($#$ret == -1){
     return(-1);
  }

  my @fields = @{$$ret[0]};

  $self->{DB}              = $db;
  $self->{PRIMARY}         = $id;
  $self->{TYPE}            = $fields[1];
  $self->{SEQNO}           = $fields[2];
  $self->{MOTIFNO}         = $fields[3];
  $self->{FEATNO}          = $fields[4];
  $self->{ORIG}            = $fields[5];
  $self->{CLUSTER}         = Bio::DOOP::Cluster->new_by_id($db,$fields[6]);

  $ret = $db->query("SELECT alignment_dialign,alignment_fasta FROM cluster_subset_data WHERE subset_primary_id = \"$id\";");

  if ($#$ret == -1){
     return(-1);
  }

  @fields = @{$$ret[0]};

  $self->{DIALIGN}          = $fields[0];
  $self->{FASTA}            = $fields[1];

  bless $self;
  return($self);
}

=head2 get_id

Prints out the subset primary id. This is the internal ID from the MySQL database.
  
Return type: string

  print $cluster_subset->get_id;

=cut

sub get_id {
  my $self                 = shift;
  return($self->{PRIMARY});
}

=head2 get_type

Prints out the subset type.

Return type: string

  print $cluster_subset->get_type;

=cut

sub get_type {
  my $self                 = shift;
  return($self->{TYPE});
}

=head2 get_seqno

Returns the number of sequences in the subset.

Return type: string

  for(i = 0; i < $cluster_subset->get_seqno; i++){
      print $seq[$i];
  }

=cut

sub get_seqno {
  my $self                 = shift;
  return($self->{SEQNO});
}

=head2 get_featno

Returns the total number of features (motifs, TSSs and other) in the subset.

Return type: string

  if ($cluster_subset->get_featno > 4){
      print "We have lots of features!!!\n";
  }

=cut

sub get_featno {
  my $self                 = shift;
  return($self->{FEATNO});
}

=head2 get_motifno

Returns the number of motifs in the subset.

Return type: string

  $motifs = $cluster_subset->get_motifno;

=cut

sub get_motifno {
  my $self                 = shift;
  return($self->{MOTIFNO});
}

=head2 get_orig

Returns 'y' if the subset is the same as the original cluster, 'n' if not.

Return type: string ('y' or 'n')

  if ($cluster_subset->get_orig eq "y") {
      print "This is the original cluster!\n";
  }
  elsif ($cluster_subset->get_orig eq "n"){
      print "This is some smaller subset!\n";
  }

=cut

sub get_orig {
  my $self                 = shift;
  return($self->{ORIG});
}

=head2 get_cluster

Returns the ID of the cluster, from which the subset originates.

Return type: string

  $cluster_id = $cluster_subset->get_cluster;

=cut

sub get_cluster {
  my $self                 = shift;
  return($self->{CLUSTER});
}

=head2 get_dialign

Prints out the dialign format alignment of the subset.

Return type: string

  print $cluster_subset->get_dialign;

=cut

sub get_dialign {
  my $self                 = shift;
  return($self->{DIALIGN});
}

=head2 get_fasta_align

Prints out the fasta format alignment of the subset.

Return type: string

  print $cluster_subset->get_fasta_align;

=cut

sub get_fasta_align {
  my $self                 = shift;
  return($self->{FASTA});
}

=head2 get_all_motifs

Returns the arrayref of all motifs associated with the subset.

Return type: arrayref, the array containig Bio::DOOP::Motif objects

  @motifs = @{$cluster_subset->get_all_motifs};

=cut

sub get_all_motifs {
  my $self                 = shift;

  my $id                   = $self->{PRIMARY};
  my $i;
  my @motifs;

  my $ret = $self->{DB}->query("SELECT motif_feature_primary_id FROM motif_feature WHERE subset_primary_id = \"$id\";");

  if ($#$ret == -1){
     return(-1);
  }

  for($i = 0; $i < $#$ret + 1; $i++){
	  push @motifs,Bio::DOOP::Motif->new($self->{DB},$$ret[$i]->[0]);
  }

  return(\@motifs);
}

=head2 get_all_seqs

Returns a sorted arrayref of all sequences associated with the subset.

Sorting the sequences by the following criteria:
The first sequence is always the reference species (Arabidopsis/Human).
All other sequences are sorted first by the taxon_class (B E M V in the plants and 
P R E H M N T F V C in the chordates ) and then by the alphabetical order.

Return type: arrayref, the array containig Bio::DOOP::Sequence objects

  @seq = @{$cluster_subset->get_all_seqs};

=cut

sub get_all_seqs {
  my $self                 = shift;

  my $id                   = $self->{PRIMARY};
  my @seqs;
  my $ret = $self->{DB}->query("SELECT sequence_primary_id FROM subset_xref WHERE subset_primary_id = \"$id\";");

  if ($#$ret == -1){
     return(-1);
  }

  for(@$ret){
	  push @seqs,Bio::DOOP::Sequence->new($self->{DB},$_->[0]);
  }
  
  my $seq;
  my $i;
  my %groups;
  my @sortseqs;

  for($i = 0; $i < $#seqs+1; $i++){
     if( ($seqs[$i]->get_taxid eq "3702") || 
         ($seqs[$i]->get_taxid eq "9606") ) {
         $sortseqs[0] = $seqs[$i];
         next;
     }
     push @{$groups{$seqs[$i]->get_taxon_class}}, $seqs[$i];
  }

  for my $key ("Brassicaceae","eudicotyledons","Magnoliophyta","Viridiplantae"){
     if ($groups{$key}){
        push @sortseqs, sort {$a->get_taxon_name cmp $b->get_taxon_name} @{$groups{$key}};
     }
  }
  for my $key ("Primates","Glires","Euarchontoglires","Cetartiodactyla","Carnivora","Laurasiatheria","Xenarthra","Afrotheria","Metatheria","Prototheria","Aves","Sauropsida","Amphibia","Teleostomi","Chondrichthyes","Vertebrata","Chordata"){
	  if ($groups{$key}) {
		push @sortseqs, sort {$a->get_taxon_name cmp $b->get_taxon_name} @{$groups{$key}};
	  }
  }
  return(\@sortseqs);
}

1;
