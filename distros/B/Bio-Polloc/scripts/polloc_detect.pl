#!perl

use strict;
use Bio::Polloc::Genome;
use Bio::Polloc::RuleIO;
use Bio::Polloc::LocusIO;

use Pod::Usage;

my $cnf = shift @ARGV; # Input configuration file
my $gff = shift @ARGV; # Output GFF file
pod2usage(1) unless $cnf and $gff;
my $genomes = Bio::Polloc::Genome->build_set(-files=>\@ARGV);
my $ruleIO = Bio::Polloc::RuleIO->new(-file=>$cnf, -genomes=>$genomes);
my $lociSet = $ruleIO->execute();

my $locusIO = Bio::Polloc::LocusIO->new(-file=>'>'.$gff, -format=>'GFF');
$locusIO->write_locus($_) for @{$lociSet->loci};
exit;

__END__

=pod

=head1 AUTHOR

Luis M. Rodriguez-R < lmrodriguezr at gmail dot com >

=head1 DESCRIPTION

Detects (or predicts) loci at the given genomes.  Loci identified must be defined by a
C<.bme> file (see C<examples> for files in the proper format).  If used with C<vntrs.bme>
is similar to the first part of C<polloc_vntrs.pl>.

=head1 LICENSE

This script is distributed under the terms of
I<The Artistic License>.  See LICENSE.txt for details.

=head1 SYNOPSIS

C<perl polloc_detect.pl> B<arguments>

The arguments must be in the following order:

=over

=item Configuration

The configuration file (a .bme or .cfg file).

=item Output GFF

A path to the output GFF to be generated.

=item Inseqs

All the following arguments will be treated as input files.  Each
file is assumed to contain a genome (that can contain one or more
sequence) in [multi-]fasta format.

=back

Run C<perl polloc_vntrs.pl> without arguments to see the help
message.

=head1 SEE ALSO

=over

=item *

L<Bio::Polloc::RuleIO>

=item *

L<Bio::Polloc::LocusIO>

=back

=cut



