package Bio::DOOP::Motif;

use strict;
use warnings;

=head1 NAME

Bio::DOOP::Motif - DOOP database motif object

=head1 VERSION

Version 0.7

=cut

our $VERSION = '0.7';

=head1 SYNOPSIS

  use Bio::DOOP::Motif;

  $db = Bio::DOOP::DBSQL->connect("user","pass","database","somewhere.where.org");
  my $motif = Bio::DOOP::Motif->new($db,"160945");
  print $motif->seq,":",$motif->start," ",$motif->end,"\n";

=head1 DESCRIPTION

This object represents an evolutionary conserved motif from a subset.

=head1 AUTHORS

Tibor Nagy, Godollo, Hungary and Endre Sebestyen, Martonvasar, Hungary

=head1 METHODS

=head2 new

Creates a new motif object from the motif primary id. You usually won't need this, as
you will get this object from other objects.

Return type: Bio::DOOP::Motif object.

  $motif = Bio::DOOP::Motif->new($db,"1234");

=cut

sub new {
	my $dummy          = shift;
	my $db             = shift;
	my $id             = shift;
	my $self           = {};

	my $ret = $db->query("SELECT * FROM motif_feature where motif_feature_primary_id=\"$id\";");

	if ($#$ret == -1) {
		return(-1);
	}

	my @motif = @{$$ret[0]};
	$self->{PRIMARY}   = $motif[0];
	$self->{SUBSET}    = $motif[1];
	$self->{CONSENSUS} = $motif[2];
	$self->{TYPE}      = $motif[3];
	$self->{START}     = $motif[4];
	$self->{END}       = $motif[5];
	$self->{SUBSET_ID} = $motif[6];
	$self->{DB}        = $db;
	bless $self;
	return($self);
}

=head2 type

Returns the type of the motif.

Return type : string
  
  $motif_type = $motif->type;

=cut

sub type {
  my $self                 = shift;
  return($self->{TYPE});
}

=head2 seq

Returns the consensus sequence of the motif.

Return type: string

  $motif_seq = $motif->seq;

=cut

sub seq {
  my $self                 = shift;
  return($self->{CONSENSUS});
}

=head2 start

Returns the start position of the motif.

Return type: string

  $start = $motif->start;

=cut

sub start {
  my $self                 = shift;
  return($self->{START});
}

=head2 end

Returns the end position of the motif.

Return type: string;
  
  $end = $motif->end;

=cut

sub end {
  my $self                 = shift;
  return($self->{END});
}

=head2 length

Returns the length of the motif.

Return type: string

  $length = $motif->length;

=cut

sub length {
  my $self                 = shift;
  return($self->{END} - $self->{START} + 1);
}

=head2 get_id

Returns the primary ID of the motif. This is the internal ID from the MySQL database.

Return type: string

  $primary_id = $motif->get_id;

=cut

sub get_id {
  my $self                 = shift;
  return($self->{PRIMARY});
}

=head2 get_subset_id

Returns the motif subset primary id.

Return type: string

  $subset_id = $motif->get_subset_id;

=cut

sub get_subset_id {
  my $self                 = shift;
  return($self->{SUBSET_ID});
}

=head2 get_seqfeats

Returns all the sequence features, associated with the motif. This basically means all the sequence
regions from which the motif was generated.

Return type: arrayref, the array containing Bio::DOOP::SequenceFeature objects.

  @feats = @{$motif->get_seqfeats}

=cut

sub get_seqfeats {
  my $self                 = shift;
  my $db  = $self->{DB};
  my $id  = $self->{PRIMARY};
  my $ret = $db->query("SELECT sequence_feature_primary_id FROM sequence_feature WHERE motif_feature_primary_id = \"$id\";");

  if ($#$ret == -1) {
  	return(-1);
  }
  my @seqfeats;

  for my $i (@$ret){
     push @seqfeats,Bio::DOOP::SequenceFeature->new($db,$$i[0]);
  }

  return(\@seqfeats);
}

1;
