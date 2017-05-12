#! /usr/bin/perl
#
use Test::More tests => 14;
use CracTools::GFF::Annotation;
use File::Temp 0.23;
use Inline::Files 0.68;

# Create a temp file with the SAM lines described above
my $gtf_file = new File::Temp( SUFFIX => '.gtf', UNLINK => 1);
my $first_line;
my $i=0;
while(<GTF>) {print $gtf_file $_; $first_line=$_ unless $i>0;$i++;}
close $gtf_file;

my $gtfAnnotation = CracTools::GFF::Annotation->new($first_line,'gtf');
#print STDERR $gtfAnnotation->chr."\n";
ok($gtfAnnotation->chr eq 'AB000123','chr()');
ok($gtfAnnotation->source eq 'Twinscan','source()');
ok($gtfAnnotation->feature eq 'CDS','feature()');
ok($gtfAnnotation->start eq 215990,'start()'); # Convert to 0-based coordinate system
ok($gtfAnnotation->end eq 216027,'end()'); # Convert to 0-based coordinate system
ok($gtfAnnotation->score eq '.','score()');
ok($gtfAnnotation->strand == -1,'strand()');
ok($gtfAnnotation->phase eq 0,'phase()');
ok($gtfAnnotation->gffStrand eq '-', 'gffStrand()');
ok($gtfAnnotation->attribute("gene_id") eq "AB000123.1",'attribute() (1)');
ok($gtfAnnotation->attribute("transcript_id") eq "AB00123.1.2",'attribute() (2)');
$gtfAnnotation->attribute("transcript_id","test");
ok($gtfAnnotation->attribute("transcript_id") eq "test",'attribute() (3)');

# Testing GFF3
$i=0;
my $gff_file = new File::Temp( SUFFIX => '.gff', UNLINK => 1);
while(<GFF>) {print $gff_file $_; $first_line=$_ unless $i>0;$i++;}
close $gff_file;

my $gff3Annotation = CracTools::GFF::Annotation->new($first_line,'gff3');
ok($gff3Annotation->attribute("ID") eq 'ENSE00002706393', 'GFF3 attributes parsing (1)');
ok($gff3Annotation->parents->[0] eq 'ENST00000578939', 'GFF3 attributes parsing (2)');


__GTF__
AB000123	Twinscan	CDS	215991	216028	.	-	0	gene_id "AB000123.1"; transcript_id "AB00123.1.2"
__GFF__
HSCHR6_MHC_MANN	Ensembl_CORE	exon	30051790	30051922	.	-	.	ID=ENSE00002706393;Parent=ENST00000578939
