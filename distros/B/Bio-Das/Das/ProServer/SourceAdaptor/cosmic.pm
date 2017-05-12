#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-05-20
# Last Modified: 2003-05-27
# Builds DAS features from COSMIC Cancer database
#
package Bio::Das::ProServer::SourceAdaptor::cosmic;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

=head1 MAINTAINER

Jody Clements <jc3@sanger.ac.uk>.

=cut

use strict;

use base qw(Bio::Das::ProServer::SourceAdaptor);


sub init {
  my $self                = shift;
  $self->{'capabilities'} = {
			     'features' => '1.0',
			    };
}

sub length {
  my ($self, $seg) = @_;
  my $gid = $seg;
  $gid =~ s/^(.*?)_.*/$1/;
  if(!$self->{'_length'}->{$seg}) {
    my $ref = $self->transport->query(qq(select length(t.transcript_aa_seq)AS LEN
                                         from gene_som gs,
                                         transcript t
                                         where gs.gene_name = '$gid'
                                         and gs.id_gene = t.id_gene));
    if(scalar @$ref) {
      $self->{'_length'}->{$seg} = @{$ref}[0]->{'LEN'};
    }
  }
  return $self->{'_length'}->{$seg};
}

sub build_features {
  my ($self, $opts) = @_;
  my $spid    = $opts->{'segment'};
  my $gid = $spid;
  $gid =~ s/^(.*?)_.*/$1/;
  my $start   = $opts->{'start'};
  my $end     = $opts->{'end'};
  my $qbounds = "";
  $qbounds    = qq(AND sm.mut_start_position <= '$end' AND sm.mut_start_position+length(sm.mut_allele_seq) >= '$start') if($start && $end);

  my $query   = qq(SELECT	SUBSTR(tr.transcript_aa_seq, sm.mut_start_position, 1) AS NORMAL,
	sm.mut_start_position AS START_POINT,
	sm.mut_allele_seq AS MUTANT,
        t.paper_reference AS ID,
	length(sm.mut_allele_seq) AS LEN
FROM 	gene_som gsom,
	gene_study gs,
	analysed_gene_sample ags,
	gene_sample_mutation gsm,
        sample s,
        tumour t,
	mutation m,
	sequence_mut sm,
	transcript tr
WHERE	gsom.gene_name = '$gid'
AND	gsom.id_gene = gs.id_gene
AND	gs.id_gene_study = ags.id_gene_study
AND 	ags.id_ags = gsm.id_ags
AND     ags.id_sample = s.id_sample
AND     s.id_tumour = t.id_tumour
AND 	gsm.id_mutation = m.id_mutation
AND 	m.id_mutation = sm.id_mutation
AND 	sm.aa_mapped_to_ref_cdna = 'y'
AND	gs.id_gene = tr.id_gene
$qbounds
ORDER BY START_POINT);

  my $ref = $self->transport->query($query);
  my @features = ();

  for my $row (@{$ref}) {
    my $start  = $row->{'START_POINT'};
    my $end    = $row->{'START_POINT'} + $row->{'LEN'} -1;
    my $normal = $row->{'NORMAL'};
    my $mutant = $row->{'MUTANT'};
    my $id     = $row->{'ID'};
    $id =~ s/(\w*?)::.*/$1/;
    ($start, $end) = ($end, $start) if($start > $end);
    #########
    # safety catch. throw stuff which looks like it's out of bounds
    #
    my $full_length = $self->length($spid);
    next if($start > $full_length);
    
    push @features, {
		     'id'     => $id,
		     'type'   => "cosmic",
		     'method' => "cosmic",
		     'start'  => $start,
		     'end'    => $end,
		     'note'   => qq(Normal: $normal / Mutant: $mutant),
		    };
  }

  return @features;
}

1;
