#!/usr/bin/env perl

use Bio::GeneDesign;
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '5.54';
my $GDV = "GD_Graph_Dotplot_$VERSION";

local $| = 1;

##Get Arguments
my %p = ();
GetOptions (
      'input=s'       => \$p{INPUT},
      'window=i'      => \$p{WINDOW},
      'output=s'      => \$p{OUTPUT},
      'stringency=i'  => \$p{STRINGENCY},
      'help'          => \$p{HELP}
);

################################################################################
################################ SANITY  CHECK #################################
################################################################################
pod2usage(-verbose=>99, -sections=>"NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE")
  if ($p{HELP});

my $GD = Bio::GeneDesign->new();

#The input file must exist and be a format we care to read.
die "\n GDERROR: You must supply an input file.\n"
  if (! $p{INPUT});
my ($iterator, $filename, $suffix) = $GD->import_seqs($p{INPUT});

#The output path must exist, and we'll need it to end with a slash
$p{OUTPUT} = $p{OUTPUT} || ".";
$p{OUTPUT} .= "/" if (substr($p{OUTPUT}, -1, 1) !~ /[\/]/);
die "\n GDERROR: $p{OUTPUT} does not exist.\n"
  if ($p{OUTPUT} && ! -e $p{OUTPUT});

$p{WINDOW} = $p{WINDOW} || 10;
$p{STRINGENCY} = $p{STRINGENCY} || 10;

################################################################################
################################# CONFIGURING ##################################
################################################################################
my @fileswritten;

################################################################################
################################## GRAPHING  ###################################
################################################################################
my @allseqs;
while ( my $obj = $iterator->next_seq() )
{
  my $name = $obj->id;
  push @allseqs, $obj;
}

if ((scalar @allseqs) == 1)
{
  push @allseqs, $allseqs[0];
}

foreach my $x (0 .. (scalar @allseqs) - 2)
{
  my $seqa = $allseqs[$x];
  foreach my $y ($x + 1 .. (scalar @allseqs) - 1)
  {
    my $seqb = $allseqs[$y];
    my $graph = $GD->make_dotplot(
      -first      => $seqa,
      -second     => $seqb,
      -window     => $p{WINDOW},
      -stringency => $p{STRINGENCY}
    );
    my $filename = $seqa->id . '_VS_' . $seqb->id . '_dotplot.png';
    my $path = $p{OUTPUT} . $filename;
    open   (my $IMG, '>', $path) or croak $!;
    binmode $IMG;
    print   $IMG $graph;
    close   $IMG;

    push @fileswritten, $path;
  }
}

print "\n";
print "Wrote $_\n" foreach @fileswritten;
print "\n";
print $GD->attitude() . " brought to you by $GDV\n\n";

exit;

__END__

=head1 NAME

  GD_Graph_Dotplot.pl

=head1 VERSION

  Version 5.54

=head1 DESCRIPTION

  Makes dotplots. If you give a file with one sequence in, it will make a self
  dotplot. If you give a file with multiple sequences, it will give each
  pairwise combination.

=head1 ARGUMENTS

Required arguments:

  -i,   --input : a file containing nucleotide sequences.

Optional arguments:

  -out, --output : path to an output directory
  -w,   --window : the width of the window
  -s,   --stringency :
  -h,   --help : display this message

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, GeneDesign developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the GeneDesign developers may
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
