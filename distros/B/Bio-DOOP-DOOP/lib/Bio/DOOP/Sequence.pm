package Bio::DOOP::Sequence;

use strict;
use warnings;
use Carp qw(cluck carp verbose);

=head1 NAME

Bio::DOOP::Sequence - Sequence (promoter region) object

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

=head1 DESCRIPTION

This object represents a specific promoter sequence in the database.
You can access the annotation and the sequence through this object.

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 new

Creates a new sequence object from the sequence primary id.

Return type: Bio::DOOP::Sequence object

  $seq = Bio::DOOP::Sequence->new($db,"1234");

=cut

sub new {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $id                   = shift;
  my $i;
  my $ret = $db->query("SELECT * FROM sequence WHERE sequence_primary_id = \"$id\";");
  my @fields = @{$$ret[0]};

  $self->{DB}              = $db;
  $self->{PRIMARY}         = $fields[0];
  $self->{FAKE}            = $fields[1];
  $self->{DB_ID}           = $fields[2];
  $self->{LENGTH}          = $fields[3];
  $self->{DATE}            = $fields[4];
  $self->{VERSION}         = $fields[5];
  $self->{ANNOT}           = $fields[6];
  $self->{ORIG}            = $fields[7];
  $self->{DATA}            = $fields[8];
  $self->{TAXON}           = $fields[9];

  if (defined($self->{ANNOT})){

     $ret = $db->query("SELECT * FROM sequence_annotation WHERE sequence_annotation_primary_id = \"".$self->{ANNOT}."\";");
     @fields = @{$$ret[0]};

     $self->{MAINDBID}        = $fields[1];
     $self->{UTR}             = $fields[2];
     $self->{DESC}            = $fields[3];
     $self->{GENENAME}        = $fields[4];

  }

  if (defined($self->{DATA})) {
     $ret = $db->query("SELECT * FROM sequence_data WHERE sequence_data_primary_id = \"".$self->{DATA}."\";");
     @fields = @{$$ret[0]};

     $self->{FASTA}           = $fields[2];
     $self->{BLAST}           = $fields[3];
  }

  $ret = $db->query("SELECT * FROM taxon_annotation WHERE taxon_primary_id = \"".$self->{TAXON}."\";");
  @fields = @{$$ret[0]};

  $self->{TAXID}           = $fields[1];
  $self->{TAXNAME}         = $fields[2];
  $self->{TAXCLASS}        = $fields[3];

  my %xref;
  $ret = $db->query("SELECT xref_id,xref_type FROM sequence_xref WHERE sequence_primary_id = \"$id\";");
  for($i = 0; $i < $#$ret+1; $i++){
	  @fields = @{$$ret[$i]};
	  push @{ $xref{$fields[1]} }, $fields[0];
  }
  $self->{XREF}            = \%xref;

  bless $self;
  return($self);
}

=head2 new_from_dbid

Creates a new sequence object from the full sequence id which contains the following:

17622344 - 81001020 _ 3712 _ 118 - 617 _ 3 _ +
    |        |          |     |     |    |   |
GI/fakeGI    |          |     |     |    |   |
             |          |     |     |    |   |
clusterID____|          |     |     |    |   |
taxID___________________|     |     |    |   |
start_________________________|     |    |   |
end_________________________________|    |   |
type_____________________________________|   |
strand_______________________________________|

Return type: Bio::DOOP::Sequence object

  $seq = Bio::DOOP::Sequence->new_from_dbid($db,"17622344-81001020_3712_118-617_3_+");

=cut

sub new_from_dbid {
  my $self                 = {};
  my $dummy                = shift;
  my $db                   = shift;
  my $id                   = shift;
  my $i;
  my $ret = $db->query("SELECT * FROM sequence WHERE sequence_id = \"$id\";");
  my @fields = @{$$ret[0]};

  $self->{DB}              = $db;
  $self->{PRIMARY}         = $fields[0];
  $self->{FAKE}            = $fields[1];
  $self->{DB_ID}           = $fields[2];
  $self->{LENGTH}          = $fields[3];
  $self->{DATE}            = $fields[4];
  $self->{VERSION}         = $fields[5];
  $self->{ANNOT}           = $fields[6];
  $self->{ORIG}            = $fields[7];
  $self->{DATA}            = $fields[8];
  $self->{TAXON}           = $fields[9];

  if (defined($self->{ANNOT})){

     $ret = $db->query("SELECT * FROM sequence_annotation WHERE sequence_annotation_primary_id = \"".$self->{ANNOT}."\";");
     @fields = @{$$ret[0]};

     $self->{MAINDBID}        = $fields[1];
     $self->{UTR}             = $fields[2];
     $self->{DESC}            = $fields[3];
     $self->{GENENAME}        = $fields[4];

  }

  if (defined($self->{DATA})) {
     $ret = $db->query("SELECT * FROM sequence_data WHERE sequence_data_primary_id = \"".$self->{DATA}."\";");
     @fields = @{$$ret[0]};

     $self->{FASTA}           = $fields[2];
     $self->{BLAST}           = $fields[3];
  }

  $ret = $db->query("SELECT * FROM taxon_annotation WHERE taxon_primary_id = \"".$self->{TAXON}."\";");
  @fields = @{$$ret[0]};

  $self->{TAXID}           = $fields[1];
  $self->{TAXNAME}         = $fields[2];
  $self->{TAXCLASS}        = $fields[3];

  my %xref;
  $ret = $db->query("SELECT xref_id,xref_type FROM sequence_xref WHERE sequence_primary_id = \"$id\";");
  for($i = 0; $i < $#$ret+1; $i++){
	  @fields = @{$$ret[$i]};
	  push @{ $xref{$fields[1]} }, $fields[0];
  }
  $self->{XREF}            = \%xref;

  bless $self;
  return($self);
}

=head2 get_id

Returns the sequence primary id. This is the internal ID from the MySQL database.

Return type: string

  my $id = $seq->get_id;

=cut

sub get_id {
  my $self                 = shift;
  return($self->{PRIMARY});
}

=head2 get_fake_id

Returns the sequence GI or a fake GI if no real GI is available.
  
Return type: string

  my $id = $seq->get_fake_id;

=cut

sub get_fake_id {
  my $self                 = shift;
  return($self->{FAKE});
}

=head2 get_db_id

Returns the full sequence ID, described at the new_from_dbid method.

Return type: string

  my $id = $seq->get_db_id;

=cut

sub get_db_id {
  my $self                 = shift;
  return($self->{DB_ID});
}

=head2 get_length

Returns the length of the sequence.

Return type: string

  my $length = $seq->get_length;

=cut

sub get_length {
  my $self                 = shift;
  return($self->{LENGTH});
}

=head2 get_date

Returns the last modification date of the MySQL record.

Return type: string

  my $date = $seq->get_date;

=cut

sub get_date {
  my $self                 = shift;
  return($self->{DATE});
}

=head2 get_ver

Returns the version of the sequence.

Return type: string

  my $version = $seq->get_ver;

=cut

sub get_ver {
  my $self                 = shift;
  return($self->{VERSION});
}

=head2 get_annot_id

Returns the sequence annotation primary id. This is the internal ID from the MySQL database.

Return type: string

  my $annotation_id = $seq->get_annot_id;

=cut

sub get_annot_id {
  my $self                 = shift;
  return($self->{ANNOT});
}

=head2 get_orig_id

This method is not yet implemented.

=cut

sub get_orig_id {
  my $self                 = shift;
  return($self->{ORIG});
}

=head2 get_data_id

Returns the sequence data primary id. This is the internal ID from the MySQL database.
  
Return type: string

  my $data_id = $seq->get_data_id;

=cut

sub get_data_id {
  my $self                 = shift;
  return($self->{DATA});
}

=head2 get_taxon_id

Returns the taxon annotation primary id. This is the internal ID from the MySQL database.
  
Return type: string

  my $taxon_id = $seq->get_taxon_id;

=cut

sub get_taxon_id {
  my $self                 = shift;
  return($self->{TAXON});
}

=head2 get_data_main_db_id

Returns the sequence annotation primary id. This is the internal ID from the MySQL database.

Return type: string

  my $annotation_id = $seq->get_data_main_db_id;

=cut

sub get_data_main_db_id {
  my $self                 = shift;
  return($self->{MAINDBID});
}

=head2 get_utr_length

Returns the length of the 5' UTR included in the sequence.
  
Return type: string

  $utr_length = $seq->get_utr_length;

=cut

sub get_utr_length {
  my $self                 = shift;
  return($self->{UTR});
}

=head2 get_desc

Returns the description of the sequence.

Return type: string

  print $seq->get_desc,"\n";

=cut

sub get_desc {
  my $self                 = shift;
  return($self->{DESC});
}

=head2 get_gene_name

Returns the gene name of the promoter. If the gene is unknow or not annotated, it is empty.

Return type: string

  $gene_name = $seq->get_gene_name;

=cut

sub get_gene_name {
  my $self                 = shift;
  return($self->{GENENAME});
}

=head2 get_fasta

Returns the promoter sequence in FASTA format.

Return type: string

  print $seq->get_fasta;

=cut

sub get_fasta {
  my $self                 = shift;
  my $seq = ">".$self->{DB_ID}."\n".$self->{FASTA}."\n";
  return($seq);
}

=head2 get_raw_seq

Returns the raw sequence without any other identifier.

Return type: string

  my $rawseq = $seq->get_raw_seq;

=cut

sub get_raw_seq {
  my $self                 = shift;
  my $seq = $self->{FASTA};
  return($seq);
}

=head2 get_blast

This method is not yet implemented.

=cut

sub get_blast {
  my $self                 = shift;
  return($self->{BLAST});
}

=head2 get_taxid

Returns the NCBI taxon ID of the sequence.

Return type: string

  $taxid = $seq->get_taxid;

=cut

sub get_taxid {
  my $self                 = shift;
  return($self->{TAXID});
}

=head2 get_taxon_name

Returns the scientific name of the sequence's taxon ID.

Return type: string

  print $seq->get_taxon_name;

=cut

sub get_taxon_name {
  my $self                 = shift;
  return($self->{TAXNAME});
}

=head2 get_taxon_class

Returns the taxonomic class of the sequence's taxon ID. Used internally,
to create monophyletic sets of sequences in an orthologous cluster.

Return type: string

  print $seq->get_taxon_class;

=cut

sub get_taxon_class {
  my $self                 = shift;
  return($self->{TAXCLASS});
}

=head2 print_all_xref

Prints all the xrefs to other databases.

Type of xref IDs : 

go_id            : Gene Ontology ID
ncbi_gene_id     : NCBI gene ID
ncbi_cds_gi      : NCBI CDS GI
ncbi_rna_gi      : NCBI RNA GI
ncbi_cds_prot_id : NCBI CDS protein ID
ncbi_rna_tr_id   : NCBI RNA transcript ID
at_no            : At Number

TODO : sometimes it gives back duplicated data

  $seq->print_all_xref;

=cut

sub print_all_xref {
  my $self                 = shift;
  for my $keys ( keys %{ $self->{XREF} }){
	  print"$keys: ";
	  for (@{ ${ $self->{XREF} }{$keys} }){print "$_ "}
	  print"\n";
  }
}

=head2 get_all_xref_keys

Returns the arrayref of xref names.

Return type: arrayref, the array containing strings (xref names)

  @keys = @{$seq->get_all_xref_keys};

=cut

sub get_all_xref_keys {
  my $self                 = shift;

  my @xrefkeys = keys %{ $self->{XREF} };
  return(\@xrefkeys);
}

=head2 get_xref_value

Returns the arrayref of a given xref's values'.

Return type: arrayref, the array containg strings (xref values)

  @values = @{$seq->get_xref_value("go_id")};

=cut

sub get_xref_value {
  my $self                 = shift;
  my $key                  = shift;

  if (${ $self->{XREF} }{$key}){
     return(${ $self->{XREF} }{$key});
  }
  else {
     return(-1);
  }
}

=head2 get_all_seq_features

Returns the arrayref of all sequence features or -1 in the case of an error.

Return type: arrayref, the array containing Bio::DOOP::SequenceFeature objects

  @seqfeat = @{$seq->get_all_seq_features};

=cut

sub get_all_seq_features {
  my $self                 = shift;
  
  my @seqfeatures;

  # The order of the sequence features is important to correctly draw the picture of the cluster.
  my $query = "SELECT sequence_feature_primary_id FROM sequence_feature WHERE sequence_primary_id = \"".$self->{PRIMARY}."\" ORDER BY feature_start;";
  my $ref = $self->{DB}->query($query);

  if ($#$ref == -1){
     return(-1);
  }

  for my $sfpid (@$ref){
	  my $sf = Bio::DOOP::SequenceFeature->new($self->{DB},$$sfpid[0]);
	  push @seqfeatures, $sf;
  }

  return(\@seqfeatures);
}

=head2 get_all_subsets

Returns all subsets which contain the sequence.

Return type: arrayref, the array containing Bio::DOOP::ClusterSubset objects

  @subsets = @{$seq->get_all_subsets};

=cut

sub get_all_subsets {
  my $self                 = shift;

  my @subsets;

  my $id    = $self->{PRIMARY};
  my $query = "SELECT subset_primary_id FROM subset_xref WHERE sequence_primary_id = \"$id\"";
  my $ref   = $self->{DB}->query($query);

  if ($#$ref == -1){
     return(-1);
  }

  for my $subset (@$ref){
     push @subsets, Bio::DOOP::ClusterSubset->new($self->{DB},$$subset[0]);
  }

  return(\@subsets);
}

1;
