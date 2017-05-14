#!/usr/bin/perl

use strict;
use Bio::Polloc::LocusIO 1.0501;
use Bio::Polloc::Genome;
use Bio::Polloc::LociGroup;
use Bio::Polloc::TypingI;

use Pod::Usage;

# ------------------------------------------------- INPUT
my $gff_in =  shift @ARGV;
my $groups =  shift @ARGV;
my $out    =  shift @ARGV;
my $draw   =  shift @ARGV;
my $cons   = (shift @ARGV || 100)+0;
my $len    = (shift @ARGV || 20)+0;
my $error  = (shift @ARGV || 0)+0;
my @names  = split /:/, shift @ARGV;
my @inseqs = @ARGV;

pod2usage(1) unless $gff_in and $groups and $out and $#inseqs > -1;
Bio::Polloc::Polloc::Root->DEBUGLOG(-file=>">$out.log");
$Bio::Polloc::Polloc::Root::VERBOSITY = 4;

# ------------------------------------------------- READ INPUT
my $genomes = [];
for my $G (0 .. $#inseqs){
   push @$genomes, Bio::Polloc::Genome->new(-file=>$inseqs[$G], -name=>$names[$G], -id=>$G) }
my $LocusIO = Bio::Polloc::LocusIO->new(-file=>$gff_in);
my $inloci = $LocusIO->read_loci(-genomes=>$genomes);

# ------------------------------------------------- REFORM GROUPS
my @gr = ();
open GLIST, "<", $groups or die "I can not read '$groups': $!\n";
while(my $ln=<GLIST>){
   chomp $ln;
   my $lgroup = Bio::Polloc::LociGroup->new(-genomes=>$genomes);
   for my $lid (split /\s+/, $ln){
      $lgroup->add_locus($inloci->locus($lid)) if $lid !~ /^\s*$/;
   }
   push @gr, $lgroup;
}
close GLIST;

# ------------------------------------------------- TYPING
my $typing = Bio::Polloc::TypingI->new(
	-type=>'bandingPattern::amplification',
	-primerSize=>$len,
	-primerConservation=>($cons/100),
	-maxSize=>2000,
	-annealingErrors=>$error);
# Alternatively, this can be set with (but remember to "use Bio::Polloc::TypingIO;"): 
# my $typing = Bio::Polloc::TypingIO->new(-file=>'t/vntrs.bme')->typing;

GROUP: for my $lgroupId (0 .. $#gr){
   my $lgroup = $gr[$lgroupId];
   $typing->locigroup($lgroup);
   my $ampl_loci = $typing->scan;
   my $loci_out = Bio::Polloc::LocusIO->new(-file=>">$out.amplif.$lgroupId.gff");
   $loci_out->write_locus($_) for @{$ampl_loci->loci};
   if($#{$ampl_loci->loci}>-1 and $draw){
      open IMG, ">", "$out.amplif.$lgroupId.png" or die "I can not open '$out.amplif.$lgroupId.png': $!\n";
      binmode IMG;
      print IMG $typing->graph->png;
      close IMG;
   }
}

__END__

=pod

=head1 AUTHOR

Luis M. Rodriguez-R < lmrodriguezr at gmail dot com >

=head1 DESCRIPTION

polloc_primers.pl - Designs primers to amplify the groups of loci in the
given genomes and attempts to run an in silico PCR.

=head1 LICENSE

This script is distributed under the terms of
I<The Artistic License>.  See LICENSE.txt for details.

=head1 SYNOPSIS

C<perl polloc_vntrs.pl> B<arguments>

The arguments must be in the following order:

=over

=item Input gff

GFF3 file containing the loci to amplify.

Example: C<"/tmp/polloc-vntrs.out.gff">.

=item Groups

File containing the IDs of the grouped loci. One line
per group, and the IDs separated by spaces.

Example: C<"/tmp/polloc-vntrs.out.groups">.

=item Output

Path to the base of the output files.

Example: C<"/tmp/polloc-primers.out">.

=item Draw

Should I produce graphical output?  Any non-empty string to
generate PNG images, or empty string (C<''>) to ignore graphical
output.

=item Consensus (I<float>)

Consensus percentage for primers design.

Default: C<100>.

=item Length (I<int>)

Length of the primers.

Default: C<20>.

=item Errors (I<int>)

Percentage of allowed mismatches during *in silico*
amplification.

Default: C<0>.

=item Names

The names of the genomes separated by colons (C<:>). Alternatively,
it can be an empty string (C<''>) to assign genome names from files.

Example: C<"Xci3:Xeu8:XamC">

=item Inseqs

Sequences to scan (input).  Each argument will be
considered a single genome, and the values of 'names' will be
applied.  The order of the inseqs must be the same of the names.

Example 1: C<"/data/Xci3.fa" "/data/Xeu8.fa" "/data/XamC.fa">

Example 2: C</data/X*.fa> (unquoted)

=back

Run C<perl polloc_primers.pl> without arguments to see the help
message.

=head1 SEE ALSO

=over

=item *

L<Bio::Polloc::LocusIO>

=item *

L<Bio::Polloc::Genome>

=item *

L<Bio::Polloc::TypingI>

=back

=cut

