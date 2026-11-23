#!/usr/bin/env perl
# The expected values of t/concordance.t: what
# ~/Scripts/old/x.low_ram_local_concordance.pl (as it stood on 2026-10-19)
# made of concordance.truth.vcf and concordance.test.vcf, written by
# make_concordance_vcf.pl. Run from the distribution root as
#
#   perl t/data/concordance_reference.pl
#
# The tests never run it. That script cannot be run on these files as it is:
# it reads directories of one-sample VCFs, finds the truth's sample by
# matching the word "truth", and dies without ~/Scripts/BioFX_pipeline-master/
# acmg59.bed. @concordance_types, assay_concordance() and metrics() below are
# copied from it unchanged, but for perl 5.10 syntax in place of signatures
# and four corrections to metrics(), each marked where it is made, which
# concordance makes too; what reads the files is new, and does what its concordance() did: each test
# record's CHROM to ALT looked up among the truth's (with "chr" dropped from
# the truth's CHROM, and the test's ID included), a missing one taken as ".",
# and each sample of the test compared with the truth's of the same name.
use strict;
use warnings;
use FindBin;
use List::Util 'sum';

my @concordance_types = ('concordant_diploid_ref_to_haploid_ref', 'concordant_haploid_alt',
'concordant_haploid_alt_to_hom_alt', 'concordant_haploid_ref',
'concordant_haploid_ref_to_diploid_ref', 'concordant_het_alt',
'concordant_het_ref', 'concordant_hom_alt','concordant_hom_alt_to_diploid_alt','concordant_hom_ref',
'concordant_no_call', 'discordant_haploid_alt_to_haploid_alt', 'discordant_haploid_alt_to_haploid_ref', 'discordant_haploid_alt_to_het_alt','discordant_haploid_alt_to_het_ref',
'discordant_haploid_alt_to_hom_alt', 'discordant_haploid_alt_to_hom_ref',
'discordant_haploid_ref_to_haploid_alt', 'discordant_haploid_ref_to_het_alt',
'discordant_haploid_ref_to_het_ref', 'discordant_haploid_ref_to_hom_alt',
'discordant_het_alt_to_haploid_alt', 'discordant_het_alt_to_haploid_ref',
'discordant_het_alt_to_het_alt','discordant_het_alt_to_het_ref',
'discordant_het_alt_to_hom_alt', 'discordant_het_alt_to_hom_ref',
'discordant_het_ref_to_haploid_alt', 'discordant_het_ref_to_haploid_ref',
'discordant_het_ref_to_het_alt', 'discordant_het_ref_to_het_ref',
'discordant_het_ref_to_hom_alt','discordant_het_ref_to_hom_ref',
'discordant_hom_alt_to_haploid_alt','discordant_hom_alt_to_haploid_ref',
'discordant_hom_alt_to_het_alt', 'discordant_hom_alt_to_het_ref',
'discordant_hom_alt_to_hom_alt', 'discordant_hom_alt_to_hom_ref',
'discordant_hom_ref_to_haploid_alt', 'discordant_hom_ref_to_het_alt',
'discordant_hom_ref_to_het_ref','discordant_hom_ref_to_hom_alt','gained_site','lost_site');

sub metrics {
	my ($hash, $no_call) = @_;
	my %r; # return hash
	# Corrected: the script's /^conc\w+(?:alt|hom)/ took concordant_hom_ref, by
	# the "hom" in it, and left out concordant_het_ref. A true positive is a
	# variant call matched: any concordant kind whose call carries an ALT.
	my @t = grep {/^concordant_(?:het|hom_alt|haploid_alt)/} @concordance_types;
	$r{tp_site} = sum(@{ $hash }{ @t } ); # hash slice
	if ($no_call eq 'true') {
		$r{tp_site} += $hash->{concordant_no_call}
	}
	$r{fp_site} = $hash->{gained_site};
	$r{fn_site} = $hash->{lost_site};
	# Corrected: the script's /^concordant_(?:hom|haploid)\w+ref$/ took
	# concordant_haploid_ref_to_diploid_ref and left out its mirror,
	# concordant_diploid_ref_to_haploid_ref. A true negative is a reference
	# call matched, whatever the ploidy of either.
	my @tn = grep {/^concordant_(?:hom_ref|haploid_ref|diploid_ref)/} @concordance_types;
	$r{tn_site} = sum(@{ $hash }{ @tn } );

	$r{tp_genotype} = $r{tp_site};

	# Corrected: the script counted a discordance in fp_genotype only when the
	# truth was a reference call, and in fn_genotype only when the test was, so
	# that one where both carry an ALT (0/1 against 1/1) was neither. It is now
	# both: the test's call is wrong, and the truth's is missed. Specificity
	# still takes only $fp_ref, since only a reference truth is a negative.
	my $alt = qr/(?:haploid_alt|het_alt|het_ref|hom_alt)/;
	my $mismatch = sum(@{ $hash }{ grep {/^discordant_${alt}_to_$alt$/} @concordance_types} );
	my $fp_ref = sum(@{ $hash }{ grep {/^discordant_(haploid|hom)_ref_\w+/} @concordance_types} );
	$r{fp_genotype} = $fp_ref + $mismatch;

	$r{fn_genotype} = sum(@{ $hash }{grep {/^discordant_\w+_(?:hom|haploid)_ref$/} @concordance_types} ) + $mismatch;

	my $numerator = sum(@{ $hash }{ grep {/^concordant_\w+(?:alt|ref)$/} @concordance_types } ); # all but no-call
	my $denominator = sum(@{ $hash }{ grep {/(?:alt|ref)$/} @concordance_types } );
	if ($no_call =~ m/^true$/i) {
		$numerator   += $hash->{concordant_no_call};
		$denominator += $hash->{concordant_no_call} + $hash->{gained_site} + $hash->{lost_site};
	 }
	$r{genotype_concordance} = $numerator / $denominator;
	if (($r{tp_site} + $r{fp_site}) == 0) {
		$r{precision_site} = 'undefined'
	} else {
		$r{precision_site} = $r{tp_site} / ($r{tp_site} + $r{fp_site})
	}
	if (($r{tp_genotype} + $r{fp_genotype}) == 0) {
		$r{precision_genotype} = 'undefined';
	} else {
		$r{precision_genotype} = $r{tp_genotype} / ($r{tp_genotype} + $r{fp_genotype});
	}
	if (($r{tp_genotype} + $r{fn_genotype}) == 0) {
		$r{recall_genotype} = 'undefined';
	} else {
		$r{recall_genotype} = $r{tp_genotype} / ($r{tp_genotype} + $r{fn_genotype});
	}
	# Corrected: the script took concordant_hom_ref alone, though its false
	# positives count a haploid-REF truth called otherwise, so that specificity
	# gave no credit for a haploid-REF truth called right (a male's X).
	$r{tn_genotype} = $r{tn_site};
	if (($r{tn_genotype} + $fp_ref) == 0) {
		$r{specificity_genotype} = 'undefined'
	} else {
		$r{specificity_genotype} = $r{tn_genotype} / ($r{tn_genotype} + $fp_ref);
	}
	if (($r{tp_site} + $r{fn_site}) == 0) {
		$r{recall_site} = 'undefined'
	} else {
		$r{recall_site} = $r{tp_site} / ($r{tp_site} + $r{fn_site})
	}
	\%r
}

sub assay_concordance {
   my ($truth, $test) = @_;
   my @geno;
   foreach my $arg ($truth, $test) {
      if ($arg eq '0/0') {
      	push @geno, 'hom_ref';
      } elsif ($arg =~ m/^0\/(\d+)$/) { # hom ref already screened out
      	push @geno, 'het_ref';
      } elsif (($arg =~ m/^(\d+)\/(\d+)$/) && ($1 > 0) && ($1 == $2)) {
      	push @geno, 'hom_alt';
      } elsif ($arg =~ m/^(?:\.|\.\/\.)$/) {
      	push @geno, 'no_call';
      } elsif ($arg eq '0') {
      	push @geno, 'haploid_ref';
      } elsif (($arg =~ m/^(\d+)$/) && ($1 > 0)) {
      	push @geno, 'haploid_alt';
      } elsif (($arg =~ m/^(\d+)\/(\d+)$/) && ($1 > 0) && ($2 > 0) && ($1 != $2)) {
      	push @geno, 'het_alt';
      } else {
      	die "$arg failed pigeonholing.";
      }
   }
   if ($truth eq $test) {
		return "concordant_$geno[0]"
	} elsif (
   	($geno[0] ne 'no_call') &&
   	($geno[1] eq 'no_call')
   ) {
   	return 'lost_site'
   } elsif (
   	($geno[0] eq 'no_call') &&
   	($geno[1] ne 'no_call')
   ) {
   	return 'gained_site'
   } elsif (
   	($geno[0] eq 'hom_ref') &&
   	($geno[1] eq 'haploid_ref')
   	) {
   	return 'concordant_diploid_ref_to_haploid_ref';
   } elsif (
		($geno[1] eq 'hom_ref') &&
   	($geno[0] eq 'haploid_ref')
   ) {
   	return 'concordant_haploid_ref_to_diploid_ref';
   } elsif (
   	($truth =~ m/^([0-9]+)\/([0-9]+)$/) &&
   	($1 == $2) &&
   	($test eq $1)
   	) {
   	return 'concordant_hom_alt_to_diploid_alt';
   } elsif (
   	($test =~ m/^([0-9]+)\/([0-9]+)$/) &&
   	($1 == $2) &&
   	($truth eq $1)
   ) {
   	return 'concordant_haploid_alt_to_hom_alt'
	} else {
		return "discordant_$geno[0]_to_$geno[1]"
	}
}

# Each record of $file as [CHROM to ALT joined by tabs, sample => GT].
sub records {
	my ($file, $strip) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my @names;
	my @out;
	while (<$fh>) {
		chomp;
		next if /^##/;
		my @f = split /\t/;
		if (/^#CHROM/) {
			@names = @f[9 .. $#f];
			next;
		}
		$f[0] =~ s/^chr// if $strip;
		my %gt = map { $names[$_] => (split /:/, $f[9 + $_])[0] } 0 .. $#names;
		push @out, [join("\t", @f[0 .. 4]), \%gt, [@f[0 .. 4]]];
	}
	(\@out, \@names);
}

my ($truth) = records("$FindBin::Bin/concordance.truth.vcf", 1);
my ($test, $names) = records("$FindBin::Bin/concordance.test.vcf", 0);
my %truth = map { $_->[0] => $_->[1] } @{ $truth };
foreach my $sample (@{ $names }) {
	next unless exists $truth->[0][1]{$sample};
	my %count = map { $_ => 0 } @concordance_types;
	my @discordant;
	foreach my $rec (@{ $test }) {
		my $t = exists $truth{ $rec->[0] } ? $truth{ $rec->[0] }{$sample} : '.';
		my $kind = assay_concordance($t, $rec->[1]{$sample});
		$count{$kind}++;
		push @discordant, "[$rec->[2][0], $rec->[2][1], '$rec->[2][2]', '$kind', '$rec->[1]{$sample}', '$t']" if $kind =~ /^(?:discordant|gained|lost)/;
	}
	my $m = metrics(\%count, 'no');
	print "$sample:\n  counts: ", join(', ', map { "$_ => $count{$_}" } grep { $count{$_} } @concordance_types), "\n";
	print "  metrics: ", join(', ', map { sprintf '%s => %.17g', $_, $m->{$_} } sort keys %{ $m }), "\n";
	print "  discordant: ", scalar(@discordant), "\n    ", join(",\n    ", @discordant), "\n";
}
