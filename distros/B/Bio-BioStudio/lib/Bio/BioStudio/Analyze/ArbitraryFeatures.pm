#
# BioStudio functions
#

=head1 NAME

Bio::BioStudio::Analyze::ArbitraryFeatures

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Analyze::ArbitraryFeatures;

require Exporter;

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  _analyze
);
our %EXPORT_TAGS = (BS=> \@EXPORT_OK);
 
=head1 Functions

=head2 _analyze()

=cut

sub _analyze
{
  my ($chromosome, $start, $stop, $typelist) = @_;

  my %REPORT;
  my %FLATS;

  my $rawseq = $chromosome->sequence;

  my $seq = substr($rawseq, $start-1, $stop - $start + 1);
  my $seqlen = length($seq);
  my $seqobj = Bio::Seq->new(-id => $chromosome->seq_id, -seq => $seq);

  $start = $start || 1;
  $stop  = $stop || length($rawseq);

  foreach my $type (@{$typelist})
  {
    my $key = "$type features";
    $REPORT{$key} = [];
    my @feats = $chromosome->db->features(
          -primary_tag  => $type,
          -start        => $start,
          -end          => $stop,
          -range_type   => 'contains',
          -seq_id       => $chromosome->seq_id
    );
    my $typedisplay = scalar(@feats) != 1  ? $type . "s" : $type;
    foreach my $feat (sort {$a->start <=> $b->start} @feats)
    {
      push @{$REPORT{$key}}, [$feat, undef];
    }
  }

  return (\%REPORT, \%FLATS);
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

