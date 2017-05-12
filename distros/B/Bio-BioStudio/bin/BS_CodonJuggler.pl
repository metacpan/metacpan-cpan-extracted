#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::BioStudio::CodonJuggling qw(:BS);
use Getopt::Long;
use English qw(-no_match_vars);
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '3.00';
my $bsversion = "BS_CodonJuggler_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'CHROMOSOME=s'   => \$p{CHROMOSOME},
  'EDITOR=s'       => \$p{EDITOR},
  'MEMO=s'         => \$p{MEMO},
  'ITERATE=s'      => \$p{ITERATE},
  'STARTPOS=i'     => \$p{STARTPOS},
  'STOPPOS=i'      => \$p{STOPPOS},
  'FROM=s'         => \$p{FROM},
  'TO=s'           => \$p{TO},
  'DUBWHACK'       => \$p{DUBWHACK},
  'VERWHACK'       => \$p{VERWHACK},
  'ALLWHACK'       => \$p{ALLWHACK},
  'OUTPUT'         => \$p{OUTPUT},
	'help'           => \$p{HELP}
);
pod2usage(-verbose=>99) if ($p{HELP});

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $BS = Bio::BioStudio->new();
my $chr = $BS->set_chromosome(-chromosome => $p{CHROMOSOME});
my $oldchrseq = $chr->sequence();
my $chrlen = length $oldchrseq;

$p{OUTPUT} = $p{OUTPUT} || 'txt';

if ($BS->SGE())
{
  require EnvironmentModules;
  import EnvironmentModules;
  module('load openmpi');
  module('load taskfarmermq/2.4');
  module('load biostudio');
}

die "BSERROR: Both an editor's id and a memo must be supplied.\n\n"
  if (! $p{EDITOR} || ! $p{MEMO});

die 'BSERROR: Two codons must be supplied.' if (! $p{FROM} || ! $p{TO});
($p{FROM}, $p{TO}) = (uc $p{FROM}, uc $p{TO});
die 'BSERROR: Both codons must be three bases long.'
  if (length $p{FROM} != 3 || length $p{TO} != 3);

my $codon_t = $chr->GD->codontable;
if (! exists $codon_t->{$p{FROM}} || ! exists $codon_t->{$p{TO}})
{
  die 'BSERROR: At least one of the specified codons does not exist in ' .
    ' the codon table. Make sure the codons contain only the characters ' .
    "A, T, C, and G.\n";
}

if ($p{FROM} eq $p{TO})
{
  die 'BSERROR: The two codons you selected are the same; no editing will ' .
    "be done.\n";
}

$p{STARTPOS} = $p{STARTPOS} || 1;
$p{STOPPOS} = $p{STOPPOS} || $chrlen;
if ($p{STOPPOS} <= $p{STARTPOS})
{
  die "BSERROR: The start and stop coordinates do not parse\n";
}

$p{ITERATE} = $p{ITERATE} || 'chromosome';
if ($p{ITERATE} ne 'genome' && $p{ITERATE} ne 'chromosome')
{
  die "BSERROR: Argument to iterate must be 'genome' or 'chromosome'.\n";
}

################################################################################
################################# CONFIGURING ##################################
################################################################################
my $newchr = $chr->iterate(-version => $p{ITERATE});
my $GD = $newchr->GD;

$p{SWAPTYPE} = $GD->codon_change_type(-from => $p{FROM}, -to => $p{TO});
$p{MORF} = $GD->rcomplement($p{FROM});
$p{OT} = $GD->rcomplement($p{TO});
$p{NEWAA} = $GD->codontable->{$p{TO}};
$p{OLDAA} = $GD->codontable->{$p{FROM}};

my $chrseq = $newchr->sequence();
my $state = $BS->SGE
  ? farm_juggling($newchr, \%p)
  : serial_juggling($newchr, \%p);

#Do error checking
$chrseq = $newchr->sequence();
my @genes = $newchr->db->features(
  -seq_id     => $newchr->seq_id,
  -types      => 'gene',
);
foreach my $gene (@genes)
{
  my $gname = $gene->display_name;
  my $gstart = $gene->start();
  my $gend = $gene->end();
  my $glen = $gend - $gstart + 1;

  my $newseq = substr $chrseq, $gstart - 1, $glen;
  my $oldseq = substr $oldchrseq, $gstart - 1, $glen;
  if ($newseq eq $oldseq && ($state->{$gname}->[0] || $state->{$gname}->[1]))
  {
    $state->{$gname}->[2] .= ' No change in sequence;';
  }
  my $cdna = $chr->make_cDNA($gene);
  my $oldpep = $GD->translate(-sequence => $cdna);
	my $newcdna = $newchr->make_cDNA($gene);
  my $newpep = $GD->translate(-sequence => $newcdna);
  if ($newpep ne $oldpep)
  {
    $state->{$gname}->[2] .= ' Change in amino acid sequence;';
  }
}

#Do reporting
print "\nReport:\n";
foreach my $gname (sort keys %{$state})
{
  my $gid = $state->{$gname}->[3];
  my @results = @{$state->{$gname}};
  next unless($results[0] || $results[1] || $results[2]);
  print $gname, q{ : };
  if ($results[0])
  {
    my $plural = $results[0] > 1  ? 's' : q{};
    print "$results[0] $p{FROM} codon$plural changed; ";
  }
  if ($results[1])
  {
    my $plural = $results[1] > 1  ? 's' : q{};
    print "$results[1] codon$plural changed; ";
  }
  print "$results[2]" if ($results[2]);
  print "\n";
}

#Tell chromosome to write itself
$newchr->add_reason($p{EDITOR}, $p{MEMO});
$newchr->write_chromosome();

exit;

__END__

=head1 NAME

  BS_CodonJuggler.pl

=head1 VERSION

    Version 2.10

=head1 DESCRIPTION

  This utility switches any one codon to any other. By default, it will not make
    any change to a gene that will cause a translation change in an overlapping
    gene; this behavior can be overridden with the -D and -V flags, which will
    allow the utility to make nonsynonymous changes to ORFs marked dubious and
    verified, respectively.

	If a stop codon is changed to a different stop codon, the change will be
    marked "stop_retained_variant". Otherwise synonymous changes are marked
    "synonymous_codon". If a stop is changed to a non stop, it is a "stop_lost".
    If a non stop is changed to a stop it is "stop_gained"; any other change is
    a "non_synonymous_codon".

=head1 USAGE

Required arguments:

  -C,  --CHROMOSOME : The chromosome to be modified
  -E,  --EDITOR : The person responsible for the edits
  -M,  --MEMO   : Justification for the edits
  -F,  --FROM   : The codon to be replaced
  -T,  --TO     : The codon to be introduced

Optional arguments:

  --ITERATE : [genome, chromosome (def)] Which version number to increment?
  -STA, --STARTPOS : The first base for editing;
  -STO, --STOPPOS  : The last base for editing;
  -D,   --DUBWHACK : Allow nonsynonymous changes to dubious ORFs on behalf of
                     non dubious ORFs
  -V,   --VERWHACK : Allow nonsynonymous changes to verified ORFs on behalf of
                     non dubious ORFs
  -A,   --ALLWHACK : Allow even nonsynonymous changes to all ORFs
  -O,   --OUTPUT   : [html, txt (def)] Format of reporting and output.
  -h,   --help : Display this message

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the BioStudio developers may
not be used to endorse or promote products derived from this software without
specific prior written permission.

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