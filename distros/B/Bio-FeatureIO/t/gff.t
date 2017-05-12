# -*-Perl-*- Test Harness script for Bioperl
# $Id: FeatureIO.t 15112 2008-12-08 18:12:38Z sendu $

use strict;
use warnings;
use Bio::Root::Test;
use Bio::FeatureIO;

# this is mainly GFF3-specific, GFF2/GTF to be added

my ($io, $f, $s, $fcount, $scount);

################################################################################
#
# use FeatureIO::gff to read a FASTA file.
#

$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new( -file => test_input_file('dna1.fa') ) );

#read features
while($f = $io->next_feature()){
    $fcount++;
}
is($fcount, 0);

#then try to read sequences again.  should get seqs now
while($s = $io->next_seq()){
    $scount++;
    if ($scount == 1) {
        is($s->id, 'Test1');
    }
}
is($scount,  1);

################################################################################
#
# use FeatureIO::gff to read a GFF3 file.

$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new( -file => test_input_file('knownGene.gff3') ) );

#try to read sequences first.  should be undef
while($s = $io->next_seq()){
    $scount++;
}
is($scount,0);

#then read features
while($f = $io->next_feature()) {
    $fcount++;
    if ($fcount == 1) {
	isa_ok($f, 'Bio::SeqFeatureI');
	isa_ok($f, 'Bio::SeqFeature::Annotated');
        is($f->primary_tag, 'mRNA');
        is($f->primary_id, 'A00469');
        is($f->seq_id, 'chr17');
        is($f->source_tag, 'UCSC');
        is($f->score, '.');        
        is($f->start, 62467934);
        is($f->end, 62469545);
        is($f->strand, -1);
    } elsif ($fcount == 10) {
        is($f->primary_tag, 'three_prime_UTR');
        is($f->primary_id, undef);  # no ID attribute
        is($f->seq_id, 'chr9');
        is($f->source_tag, 'UCSC');
        is($f->score, '.');        
        is($f->start, 90517946);
        is($f->end, 90518841);
        is($f->strand, -1);
    } elsif ($fcount == 15) {
        is($f->primary_tag, 'match');
        is($f->primary_id, 'blastresult.1');
        is($f->seq_id, 'chr9');
        is($f->source_tag, 'BLASTN');
        is($f->score, '0.0');        
        is($f->start, 90518850);
        is($f->end, 90521248);
        is($f->strand, 1);
    }
}
is($fcount, 15);

#then try to read sequences again.  should still be undef
while($s = $io->next_seq()){
    $scount++;
}
is($scount,1);

################################################################################
#
# use FeatureIO::gff to read a GFF3 file w/ directivized FASTA tail
#
$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new( -file => test_input_file('hybrid1.gff3') ) );

#try to read sequences first.  should be undef
while($s = $io->next_seq()){
  $scount++;
}
is($scount , 0);

#then read features
while($f = $io->next_feature()){
    $fcount++;
    if ($fcount == 1) {
        is($f->primary_tag, 'mRNA');
        is($f->primary_id, 'A00469');
        is($f->seq_id, 'chr17');
        is($f->source_tag, 'UCSC');
        is($f->score, '.');        
        is($f->start, 62467934);
        is($f->end, 62469545);
        is($f->strand, -1);
    } elsif ($fcount == 5) {
        is($f->primary_tag, 'CDS');
        is($f->primary_id, undef);
        is($f->seq_id, 'chr17');
        is($f->source_tag, 'UCSC');
        is($f->score, '.');        
        is($f->start, 62469076);
        is($f->end, 62469236);
        is($f->strand, -1);
    }
}
is($fcount , 6);

#then try to read sequences again.
while($s = $io->next_seq()){
    $scount++;
    if ($scount == 1) {
        is($s->id, 'A00469');
    }
}
is($scount , 1);

################################################################################
#
# use FeatureIO::gff to read a GFF3 file w/ non-directivized FASTA tail
#

$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new( -file => test_input_file('hybrid2.gff3') ) );

#try to read sequences.  should be undef
while($s = $io->next_seq()){
    $scount++;
}
is($scount , 0);

$scount = 0;

#then read features
while($f = $io->next_feature()){
    $fcount++;
    if ($fcount == 1) {
        is($f->primary_tag, 'mRNA');
        is($f->primary_id, 'A00469');
        is($f->seq_id, 'chr17');
        is($f->source_tag, 'UCSC');
        is($f->score, '.');        
        is($f->start, 62467934);
        is($f->end, 62469545);
        is($f->strand, -1);
    } elsif ($fcount == 5) {
        is($f->primary_tag, 'CDS');
        is($f->primary_id, undef);
        is($f->seq_id, 'chr17');
        is($f->source_tag, 'UCSC');
        is($f->score, '.');        
        is($f->start, 62469076);
        is($f->end, 62469236);
        is($f->strand, -1);
    }
}

is($fcount , 6);

#try to read sequences.  should be undef
while($s = $io->next_seq()){
    $scount++;
    if ($scount == 1) {
        is($s->id, 'A00469');
    }
}
is($scount , 1);

################################################################################
#
# use FeatureIO::gff to read a GFF3 file of directives
#
$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new(-file => test_input_file('directives.gff3'),
							  -verbose => -1));

#read features
while($f = $io->next_feature()){
    $fcount++;
    if ($fcount == 1) {
        is($f->primary_tag, 'region');
        is($f->primary_id, undef);
        is($f->seq_id, 'foo');
        is($f->source_tag, '.');
        is($f->score, '.');
        is($f->start, 1);
        is($f->end, 100);
        is($f->strand, 1);
    }
}

is($fcount , 1); #sequence-region

################################################################################
#
# use FeatureIO::gff to read a GFF3 file as aggregated feature groups
#

$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new( -file => test_input_file('knownGene.gff3') ) );

#try to read sequences first.  should be undef
while($s = $io->next_seq()){
  $scount++;
}
is($scount , 0);

#read feature groups
my @f = $io->next_feature_group();
is(@f, 3);
if (@f) {
    is($f[0]->primary_tag,'mRNA');
    my %types;
    my $ct = 0;
    for my $subf ($f[0]->get_SeqFeatures) {
        $types{$subf->primary_tag}++;
        $ct++
    }
    is($ct, 7);
    is($types{'three_prime_UTR'}, 1);
    is($types{'CDS'}, 5);
    is($types{'five_prime_UTR'}, 1);
    
    %types = ();
    $ct = 0;
    is($f[1]->primary_tag,'mRNA');
    for my $subf ($f[1]->get_SeqFeatures) {
        $types{$subf->primary_tag}++;
        $ct++        
    }    
    is($ct, 5);
    is($types{'three_prime_UTR'}, 1);
    is($types{'CDS'}, 2);
    is($types{'five_prime_UTR'}, 2);
    
    %types = ();
    $ct = 0;
    is($f[2]->primary_tag,'match');
    for my $subf ($f[2]->get_SeqFeatures) {
        $types{$subf->primary_tag}++;
        $ct++        
    }
    is($ct, 0);
}

@f = $io->next_feature_group();
is(@f, 0);

#then try to read sequences again.
while($s = $io->next_seq()){
    $scount++;
}
is($scount, 1);

################################################################################
#
# use FeatureIO::gff to read GFF3 where aggregated feature groups are denoted 
# using '###'.
#
# The advantage of using this is the method can be used iteratively w/o worrying
# about possibly diffuse parent-child relationships spread throughout the file.

$fcount = 0;
$scount = 0;

ok( $io = Bio::FeatureIO->new( -file => test_input_file('knownGene2.gff3') ) );

#try to read sequences first.  should be undef
while($s = $io->next_seq()){
  $scount++;
}
is($scount , 0);

#read feature groups
@f = $io->next_feature_group();
is(@f, 1);

is($f[0]->primary_tag,'mRNA');
my %types;
my $ct = 0;
for my $subf ($f[0]->get_SeqFeatures) {
    $types{$subf->primary_tag}++;
    $ct++
}
is($ct, 7);
is($types{'three_prime_UTR'}, 1);
is($types{'CDS'}, 5);
is($types{'five_prime_UTR'}, 1);
    
@f = $io->next_feature_group();
is(@f, 1);

%types = ();
$ct = 0;
is($f[0]->primary_tag,'mRNA');
for my $subf ($f[0]->get_SeqFeatures) {
    $types{$subf->primary_tag}++;
    $ct++        
}    
is($ct, 5);
is($types{'three_prime_UTR'}, 1);
is($types{'CDS'}, 2);
is($types{'five_prime_UTR'}, 2);

@f = $io->next_feature_group();
is(@f, 1);

%types = ();
$ct = 0;
is($f[0]->primary_tag,'match');
for my $subf ($f[0]->get_SeqFeatures) {
    $types{$subf->primary_tag}++;
    $ct++        
}
is($ct, 0);

#try to read sequences first.  should be undef
while($s = $io->next_seq()){
  $scount++;
}
is($scount , 1);

################################################################################
#
# use FeatureIO::gff to read GFF3 where aggregated feature groups are iterated
# through using fast()
#
# The advantage of using this is the method can be used iteratively; unlike
# using '###', this relies on the user trusting the data for features in the
# record is grouped together.

TODO: {
    local $TODO = 'Add clustering groups based on grouping within the file';
    ok(0);
}

done_testing();

exit;
