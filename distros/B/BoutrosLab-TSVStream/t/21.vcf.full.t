### 20-vcf.full.t ##############################################################
# Basic tests for variant objects

### Includes ###################################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 10;
use Test::Exception;

### Tests ######################################################################

use BoutrosLab::TSVStream::Format::VCF::FullChr::Fixed;
use BoutrosLab::TSVStream::Format::VCF::FullNoChr::Fixed;

my $vcf_text = <<EOF;
## Header line 1
## Header line 2
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
chr1	1	i1	xyz	A[3:63742286]	q1	f1	i1=1;i2=b
1	2	i1	G	A	q2	f2	i1=1;i2=b
EOF

my $bad_vcf_text = <<EOF;
## Header line 1
## Header line 2
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
chrfoo1	1	i1	xyz	A[3:63742286]	q1	f1	i1=1;i2=b
foo1	2	i1	G	A	q2	f2	i1=1;i2=b
EOF

my $vcf_dyn_text = <<EOF;
## Header line 1
## Header line 2
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	DYN1	DYN2
chr1	1	i1	xyz	A[3:63742286]	q1	f1	i1=1;i2=b	d11	d21
1	2	i1	G	A	q2	f2	i1=1;i2=b	d12	d22
EOF

my $aic_text = <<EOF;
chr	start	end	ref	alt
chr1	1	1	xyz	A[3:63742286]
chr1	2	2	G	A
EOF

my $ainc_text = <<EOF;
chr	start	end	ref	alt
1	1	1	xyz	A[3:63742286]
1	2	2	G	A
EOF

my @testdata = ( [ 'Chr', '', $aic_text ], [ 'NoChr', 'NoChr', $ainc_text ], );

for my $testset (@testdata) {
	my ( $vcfvariant, $aivariant, $airesult ) = @$testset;
	my $outai;
	my $outvcf;
	{
		open my $fhin,     '<', \$vcf_text;
		open my $fhoutvcf, '>', \$outvcf;
		my $modulevcf = "BoutrosLab::TSVStream::Format::VCF::Full${vcfvariant}::Fixed";
		my $reader    = $modulevcf->reader( handle => $fhin );
		my $writervcf = $modulevcf->writer( handle => $fhoutvcf, pre_header => 1, pre_headers => $reader->pre_headers );
		while ( my $record = $reader->read ) {
			is($record->info->{i2}, "b", "The second key-value pair should have the value 'b'");
			$writervcf->write($record);
			}
		}
	is( $outvcf, $vcf_text, "vcf output should be the same as the vcf input" );
	}

for my $testset (@testdata) {
	my ( $vcfvariant, $aivariant, $airesult ) = @$testset;
	open my $fhin,     '<', \$vcf_dyn_text;
	my $modulevcf = "BoutrosLab::TSVStream::Format::VCF::Full${vcfvariant}::Fixed";
	dies_ok { $modulevcf->reader( handle => $fhin ) } "catch wrong number of args";
	}

for my $vcfvariant (qw( Chr NoChr )) {
	open my $fhin,     '<', \$bad_vcf_text;
	my $modulevcf = "BoutrosLab::TSVStream::Format::VCF::Full${vcfvariant}::Fixed";
	my $reader = $modulevcf->reader( handle => $fhin );
	my $record = $reader->read;
	dies_ok { $record->chr } "should detect bad chr format";
	}

done_testing();

1;
