package Bio::Das::ProServer::SourceAdaptor::myplugin;

use strict;
use base qw(Bio::Das::ProServer::SourceAdaptor);

sub init {
  my $self = shift;
  $self->{'capabilities'} = {'features' => '1.1'};
}

sub build_features {
  my ($self, $args) = @_;

  # e.g. /das/mysource/features?segment = X:1,100
  my $segment = $args->{'segment'}; # X
  my $start   = $args->{'start'};   # 1
  my $end     = $args->{'end'};     # 100
  my %features;


  my $sql = q(
select sr.name AS chromosome,
       gsi.stable_id AS g_id, g.seq_region_start AS g_start, g.seq_region_end AS g_end,
       tsi.stable_id AS t_id, t.seq_region_start AS t_start, t.seq_region_end AS t_end,
       esi.stable_id AS e_id, e.seq_region_start AS e_start, e.seq_region_end AS e_end
from   seq_region sr,
       gene_stable_id gsi, gene g,
       transcript t, transcript_stable_id tsi,
       exon_transcript et, exon e, exon_stable_id esi
where  gsi.gene_id = g.gene_id
and    g.gene_id = t.gene_id
and    t.transcript_id = tsi.transcript_id
and    t.transcript_id = et.transcript_id
and    et.exon_id = e.exon_id
and    e.exon_id = esi.exon_id
and    g.seq_region_id = sr.seq_region_id
and    sr.coord_system_id = ?
limit  1000
  );
  my $rows = $self->transport()->query( $sql, 2 );
  
  for my $row ( @{ $rows } ) {
  
    my $chromosome = $row->{'chromosome'};
    my $g_id       = $row->{'g_id'};
    my $g_start    = $row->{'g_start'};
    my $g_end      = $row->{'g_end'};
    my $t_id       = $row->{'t_id'};
    my $t_start    = $row->{'t_start'};
    my $t_end      = $row->{'t_end'};
    my $e_id       = $row->{'e_id'};
    my $e_start    = $row->{'e_start'};
    my $e_end      = $row->{'e_end'};

    $chromosome eq $segment || next;

    # Check if the gene overlaps the query segment
    if ($g_start <= $end && $g_end >= $start) {
      if (!$features{$g_id}) {
        $features{$g_id} = {
          'id'     => $g_id,
          'start'  => $g_start,
          'end'    => $g_end,
          'type'   => 'gene',
          'method' => 'Ensembl',
          'part'   => [],
        };
      }
    }

    # Check if the transcript overlaps the query segment
    if ($t_start <= $end && $t_end >= $start) {
      if (!$features{$t_id}) {
        $features{$t_id} = {
          'id'     => $t_id,
          'start'  => $t_start,
          'end'    => $t_end,
          'type'   => 'transcript',
          'method' => 'Ensembl',
          'part'   => [],
          'parent' => [],
        };

        # Create the parent/part links between the annotations
        push @{ $features{$g_id}{'part'} }, $t_id;
        push @{ $features{$t_id}{'parent'} }, $g_id;
      }
    }

    # Check if the exon overlaps the query segment
    if ($e_start <= $end && $e_end >= $start) {
      if (!$features{$e_id}) {
        $features{$e_id} = {
          'id'     => $e_id,
          'start'  => $e_start,
          'end'    => $e_end,
          'type'   => 'exon',
          'method' => 'Ensembl',
          'parent' => [],
        };

        # Create the parent/part links between the annotations
        push @{ $features{$t_id}{'part'}   }, $e_id;
        push @{ $features{$e_id}{'parent'} }, $t_id;
      }
    }
  }

  return values %features;
}

1;
