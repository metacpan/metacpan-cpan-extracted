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

  open (FH, '<', 'exons.txt') || die "Unable to open exons.txt for reading";
  while (defined(my $line = <FH>)) {
    chomp $line;
    my @fields = split /\|/, $line;
    my ($chromosome, $g_id, $g_start, $g_end, $t_id, $t_start, $t_end, $e_id, $e_start, $e_end) = @fields[1..10];

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
  close FH;

  return values %features;
}

1;
