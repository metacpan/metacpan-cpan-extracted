#!perl

use strict;
use Bio::Polloc::Genome;
use Bio::Polloc::RuleIO;
use Bio::Polloc::LocusIO;
use Bio::Polloc::Polloc::IO;

use Pod::Usage;

my $cnf = shift @ARGV; # Input configuration file
my $gff = shift @ARGV; # Input GFF file containing loci to be grouped
my $out = shift @ARGV; # Output file with the list loci ID per groups
pod2usage(1) unless $cnf and $gff and $out;

my $genomes = Bio::Polloc::Genome->build_set(-files=>\@ARGV);

my $groupCriteria = Bio::Polloc::RuleIO->new(-file=>$cnf)->grouprules->[0];
my $locusIO = Bio::Polloc::LocusIO->new(-file=>$gff, -format=>'gff');
my $lociSet = $locusIO->read_loci(-genomes=>$genomes);
$groupCriteria->locigroup($lociSet);
my $groups = $groupCriteria->build_groups(-locigroup=>$lociSet);
my $table = Bio::Polloc::Polloc::IO->new(-file=>'>'.$out);
for my $group ( @$groups ){
   $table->_print(join("\t", map {$_->id} @{$group->loci})."\n");
}
$table->close;
exit;

__END__

=pod

=head1 AUTHOR

Luis M. Rodriguez-R < lmrodriguezr at gmail dot com >

=head1 DESCRIPTION

Groups loci listed in GFF version 3, and produces a CSV file with the
IDs of the grouped loci (one line per group).

=head1 LICENSE

This script is distributed under the terms of
I<The Artistic License>.  See LICENSE.txt for details.

=head1 SYNOPSIS

C<perl polloc_group.pl> B<arguments>

The arguments must be in the following order:

=over

=item Configuration

The configuration file (a .bme or .cfg file).

=item Input GFF

A path to the GFF file containing the loci to be grouped.

=item Output CSV

A path to the CSV file to be generated.

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

=item *

L<Bio::Polloc::GroupCriteria>

=back

=cut



