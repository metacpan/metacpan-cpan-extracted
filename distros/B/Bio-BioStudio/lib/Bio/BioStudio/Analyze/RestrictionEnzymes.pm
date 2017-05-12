#
# BioStudio functions
#

=head1 NAME

Bio::BioStudio::Analyze::RestrictionEnzymes

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Analyze::RestrictionEnzymes;

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
  my ($chromosome, $start, $stop) = @_;

  my %REPORT;
  my %FLATS;

  my $rawseq = $chromosome->sequence;

  my $seq = substr($rawseq, $start-1, $stop - $start + 1);
  my $seqlen = length($seq);
  my $seqobj = Bio::Seq->new(-id => $chromosome->seq_id, -seq => $seq);

  $start = $start || 1;
  $stop  = $stop || length($rawseq);
  my $range = Bio::Range->new(-start => $start, -end => $stop);

  $chromosome->GD->set_restriction_enzymes(-enzyme_set => "standard_and_IIB");
  my $SITE_STATUS = $chromosome->GD->restriction_status(-sequence => $seqobj);

  #Absents
  {
    my $key = "absent restriction enzymes";
    my @absents = map {$_ . " (" .($SITE_STATUS->{$_}) . ")" }
                  grep {$SITE_STATUS->{$_} == 0}
                  keys %{$SITE_STATUS};
    my ($absverb, $anum) = scalar(@absents) != 1 ? ("are", "s") : ("is", q{});
    my $abs = "There $absverb " . scalar(@absents) . " absent site$anum:\n";
    $abs .= "\t$_\n" foreach @absents;
    $FLATS{$key} = $abs;
  }

  #Uniques
  {
    my $key = "unique restriction enzymes";
    my @uniques = map {$_ . " (" .($SITE_STATUS->{$_}) . ")" }
                  grep {$SITE_STATUS->{$_} == 1}
                  keys %{$SITE_STATUS};

    my ($univerb, $unum) = scalar(@uniques) != 1 ? ("are", "s") : ("is", q{});
    my $uni = "There $univerb " . scalar(@uniques) . " unique site$unum:\n";
    $uni .= "\t$_\n" foreach @uniques;
    $FLATS{$key} = $uni;
  }

  #Rares
  {
    my $key = "rare restriction enzymes";
    my $rate = $seqlen >  10000  ? $seqlen * .00001 : $seqlen * .001;
    $rate = sprintf "%.0f", $rate;
    my @rares = map {$_ . " (" .($SITE_STATUS->{$_}) . ")" }
                grep {$SITE_STATUS->{$_} > 1 && $SITE_STATUS->{$_} <= $rate}
                keys %{$SITE_STATUS};

    my ($rarverb, $rnum) = scalar(@rares) != 1 ? ("are", "s") : ("is", q{});
    my $rar = "There $rarverb " . scalar(@rares);
    $rar .= " rare site$rnum (<= $rate):\n";
    $rar .= "\t$_\n" foreach @rares;
    $FLATS{$key} = $rar;
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

