package Bio::DOOP::Util::Search;

use strict;
use warnings;

=head1 NAME

Bio::DOOP::Util::Search - Useful methods for easy search

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

  use Bio::DOOP::DOOP;

  $db = Bio::DOOP::DBSQL->connect("user","passwd","database","localhost");
  @motifs = @{Bio::DOOP::Util::Search::get_all_motifs_by_type($db,"V")};

=head1 DESCRIPTION

Collection of utilities handling large queries. Most of
the methods return arrayrefs of motifs, sequences or clusters.

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 get_all_motifs_by_type

Returns the arrayref of motifs with the type specified in the arguments.

=cut

sub get_all_motifs_by_type {
  my $db                   = shift;
  my $type                 = shift;

  my @motifs;
  my $ret = $db->query("SELECT motif_feature_primary_id FROM motif_feature WHERE motif_type = \"$type\";");
  for my $motif_id (@$ret){
	  push @motifs,Bio::DOOP::Motif->new($db,$$motif_id[0]);
  }
  return(\@motifs);
}

=head2 get_all_original_subset

Returns the arrayref of all original subsets.

=cut

sub get_all_original_subset {
  my $db                   = shift;
  my @subsets;
  my $ret = $db->query("SELECT subset_primary_id FROM cluster_subset WHERE original = \"y\";");
  for my $subset (@$ret){
	  push @subsets,Bio::DOOP::ClusterSubset->new($db,$$subset[0]);
  }
  return(\@subsets);
}

=head2 get_all_cluster_by_gene_id

Returns the arrayref of all Bio::DOOP::Cluster objects, defined by a gene id.

=cut

sub get_all_cluster_by_gene_id  {
  my $db                   = shift;
  my $gene_id              = shift;
  my $promoter_size        = shift;

  my @clusters;
  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster,sequence,subset_xref,sequence_annotation WHERE sequence.sequence_annotation_primary_id = sequence_annotation.sequence_annotation_primary_id AND subset_xref.sequence_primary_id = sequence.sequence_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence_annotation.sequence_gene_name LIKE '$gene_id%';");

  for my $cluster (@$ret){
          push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }
  return(\@clusters);
}

=head2 get_all_cluster_by_keyword

Returns the arrayref of all Bio::DOOP::Cluster objects, containing the keyword in their description or tss annotation.

=cut

sub get_all_cluster_by_keyword {
  my $db                   = shift;
  my $keyword              = shift;
  my $promoter_size        = shift;

  my @clusters;
  my @cluster_db_id;
  my %seen;

  # Query from sequence_annot.
  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, sequence_annotation, sequence, subset_xref WHERE subset_xref.sequence_primary_id = sequence.sequence_primary_id AND sequence.sequence_annotation_primary_id = sequence_annotation.sequence_annotation_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence_annotation.sequence_desc LIKE '%$keyword%';");
    for my $cluster (@$ret){
          push @cluster_db_id,$$cluster[0];
  }

  # Query from tss_annot.
  # NO
  #$ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, tss_annotation, sequence_feature, subset_xref WHERE subset_xref.sequence_primary_id = sequence_feature.sequence_primary_id AND sequence_feature.tss_primary_id = tss_annotation.tss_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND tss_annotation.tss_desc LIKE '%$keyword%';");
  #for my $cluster (@$ret){
  #        push @cluster_db_id,$$cluster[0];
  #}

  #Remove the redundant cluster_db_ids.
  my @cluster_id_uniq = grep { ! $seen{ $_ }++ } @cluster_db_id;

  for my $cluster (@cluster_id_uniq){
          push @clusters,Bio::DOOP::Cluster->new($db,$cluster,$promoter_size);
  }
  
  return(\@clusters);
}

=head2 get_all_cluster_by_xref

Returns the arrayref of Bio::DOOP::Clsuter objects, containing a given xref.

=cut

sub get_all_cluster_by_xref {
  my $db                   = shift;
  my $type                 = shift;
  my $value                = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, sequence_xref, subset_xref WHERE sequence_xref.sequence_primary_id = subset_xref.sequence_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence_xref.xref_type = '$type' AND sequence_xref.xref_id = '$value';");

  for my $cluster (@$ret){
	  push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }

  return(\@clusters);
}

=head2 get_all_cluster_by_taxon_name

Returns the arrayref of Bio::DOOP::Cluster objects containing a taxon name.
Don't use this, use get_all_cluster_by_taxon_id with NCBI IDs!

=cut

sub get_all_cluster_by_taxon_name {
  my $db                   = shift;
  my $taxon                = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, taxon_annotation, sequence, subset_xref WHERE subset_xref.sequence_primary_id = sequence.sequence_primary_id AND sequence.taxon_primary_id = taxon_annotation.taxon_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND taxon_annotation.taxon_name = '$taxon';");

  for my $cluster (@$ret){
	  push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }
  return(\@clusters);
}

=head2 get_all_cluster_id_by_taxon_name

Returns the arrayref of cluster ids containing the taxon name.
Don't use this, use get_all_cluster_by_taxon_id with NCBI IDs!

=cut

sub get_all_cluster_id_by_taxon_name {
  my $db                   = shift;
  my $taxon                = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, taxon_annotation, sequence, subset_xref WHERE subset_xref.sequence_primary_id = sequence.sequence_primary_id AND sequence.taxon_primary_id = taxon_annotation.taxon_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND taxon_annotation.taxon_name = '$taxon';");

  for my $cluster (@$ret){
	  push @clusters,$$cluster[0];
  }
  return(\@clusters);
}

=head2 get_all_cluster_by_taxon_id

Returns the arrayref of Bio::DOOP::Cluster objects, containing an NCBI taxon id.

=cut

sub get_all_cluster_by_taxon_id {
  my $db                   = shift;
  my $taxon                = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, taxon_annotation, sequence, subset_xref WHERE subset_xref.sequence_primary_id = sequence.sequence_primary_id AND sequence.taxon_primary_id = taxon_annotation.taxon_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND taxon_annotation.taxon_taxid = '$taxon';");

  for my $cluster (@$ret){
	  push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }
  return(\@clusters);
}

=head2 get_all_cluster_id_by_taxon_id

Returns the arrayref of cluster ids containing an NCBI taxon id.

=cut

sub get_all_cluster_id_by_taxon_id {
  my $db                   = shift;
  my $taxon                = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, taxon_annotation, sequence, subset_xref WHERE subset_xref.sequence_primary_id = sequence.sequence_primary_id AND sequence.taxon_primary_id = taxon_annotation.taxon_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND taxon_annotation.taxon_taxid = '$taxon';");

  for my $cluster (@$ret){
	  push @clusters,$$cluster[0];
  }
  return(\@clusters);
}

=head2 get_all_cluster_by_sequence_id
  
Returns the arrayref of Bio::DOOP::Cluster objects, containing a given sequence id (fake GI).

=cut

sub get_all_cluster_by_sequence_id {
  my $db                   = shift;
  my $sequence_id          = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, sequence, subset_xref WHERE subset_xref.sequence_primary_id = sequence.sequence_primary_id AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence.sequence_fake_gi LIKE '$sequence_id%';");

  for my $cluster (@$ret){
	push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }
  return(\@clusters);
}

=head2 get_all_cluster_by_atno

Returns the arrayref of Bio::DOOP::Cluster objects, containing a given At Number.

=cut

sub get_all_cluster_by_atno {
  my $db                   = shift;
  my $atno                 = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, sequence_xref, subset_xref WHERE subset_xref.sequence_primary_id = sequence_xref.sequence_primary_id AND sequence_xref.xref_type = 'at_no' AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence_xref.xref_id LIKE '$atno%';");

  for my $cluster (@$ret) {
	push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }
  return(\@clusters);
}

=head2 get_all_seq_by_motifid

Returns the arrayref of Bio::DOOP::Sequence objects, containing a given motif id.

=cut

sub get_all_seq_by_motifid {
  my $db                   = shift;
  my $motifid              = shift;
  my @seqs;

  my $ret = $db->query("SELECT sequence_primary_id FROM sequence_feature WHERE motif_feature_primary_id = $motifid;");

  for my $seq (@$ret){
      push @seqs,Bio::DOOP::Sequence->new($db,$$seq[0]);
  }

  return(\@seqs);
}

=head2 get_all_cluster_by_go_id

Returns the arrayref of Bio::DOOP::Cluster objects, containing a given GO ID.

=cut
sub get_all_cluster_by_go_id {
	my $db            = shift;
	my $goid          = shift;
	my $promoter_size = shift;

	my @clusters;

	my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, sequence_xref, subset_xref WHERE subset_xref.sequence_primary_id = sequence_xref.sequence_primary_id AND sequence_xref.xref_type = 'go_id' AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence_xref.xref_id LIKE '$goid';");

	for my $cluster (@$ret) {
		push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
	}
	return(\@clusters);
}

=head2 get_all_cluster_by_ensno

Returns the arrayref of Bio::DOOP::Cluster objects, containing a given ENSEMBL gene ID.

=cut

sub get_all_cluster_by_ensno {
  my $db                   = shift;
  my $ensno                = shift;
  my $promoter_size        = shift;

  my @clusters;

  my $ret = $db->query("SELECT DISTINCT(cluster.cluster_id) FROM cluster, sequence_xref, subset_xref WHERE subset_xref.sequence_primary_id = sequence_xref.sequence_primary_id AND sequence_xref.xref_type = 'ensembl_id' AND cluster.cluster_primary_id = subset_xref.cluster_primary_id AND sequence_xref.xref_id LIKE '$ensno%';");

  for my $cluster (@$ret) {
	push @clusters,Bio::DOOP::Cluster->new($db,$$cluster[0],$promoter_size);
  }
  return(\@clusters);
}

=head2 get_all_cluster_id

Returns an arrayref of all the cluster IDs of a given promoter/subset category.
For example returns all clusters with 1000 bp E type subsets.

=cut

sub get_all_cluster_id {

	my $db            = shift;
	my $promoter_size = shift;
	my $subset_type   = shift;

	my @clusters;

	my $ret = $db->query("SELECT cluster.cluster_id FROM cluster, cluster_subset WHERE cluster.cluster_promoter_type = '$promoter_size' AND cluster.cluster_primary_id = cluster_subset.cluster_primary_id AND cluster_subset.subset_type = '$subset_type';");

	for my $cluster (@$ret) {
		push @clusters, $$cluster[0];
	}
	return(\@clusters);
}
1;
