#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile catdir);
use Test::More tests => 9;

my $exe     = catfile('bin', 'clarid-tools');
my $inc    = join ' -I', '', @INC;    # prepend -I to each path in @INC
my $codebook = catfile('share', 'clarid-codebook.yaml');

#-------------------------------------------------------------------------------
# 1) bulk biosample STUB-encode with subject_id column
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity biosample',
      '--format stub',
      '--action encode',
      "--codebook $codebook",
      '--infile ex/biosample.csv',
      "--sep ','";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,subject_id,project,species,tissue,sample_type,assay,condition,timepoint,duration,batch,replicate,stub_id
samp001,1,CNAG-Test,Human,Liver,Normal,RNA_seq,C22.0,Baseline,P0D,1,5,CT01001LNR0N401B0DB01R05
samp002,2,CNAG-Test,Mouse,Brain,Tumor,ChIP_seq,C71.0,Treatment,P7W,2,2,CT02002NTC0X301T7WB02R02
samp003,3,CNAG-Test,Zebrafish,Blood,Normal,WES,I46,Surgery,P1M,3,1,CT04003BNE2x101S1MB03R01
samp004,4,CNAG-Test,Rat,Kidney,Normal,LC_MS,C66,Challenge,P3Y,1,10,CT03004KNS0W301C3YB01R10
EOF
    chomp( my @want = split /\n/, $want );

    is_deeply \@got, \@want, 'bulk biosample stub-encode';
}

#-------------------------------------------------------------------------------
# 2) bulk biosample HUMAN-decode clar_ids (needs subject_id in header)
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity biosample',
      '--format human',
      '--action decode',
      "--codebook $codebook",
      '--infile ex/biosample_to_decode.csv',
      "--sep ','";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,clar_id,project,species,subject_id,tissue,sample_type,assay,condition,timepoint,duration,batch,replicate
samp001,CNAG_Test-HomSap-00001-LIV-NOR-RNA-C22.0-BSL-P0D-B01-R05,CNAG-Test,Human,1,Liver,Normal,RNA_seq,C22.0,Baseline,P0D,1,5
samp002,CNAG_Test-MusMus-00002-BRN-TUM-CHI-C71.0-TRT-P7W-B02-R02,CNAG-Test,Mouse,2,Brain,Tumor,ChIP_seq,C71.0,Treatment,P7W,2,2
samp003,CNAG_Test-DanRer-00003-BLO-NOR-WES-I46-SUR-P1M-B03-R01,CNAG-Test,Zebrafish,3,Blood,Normal,WES,I46,Surgery,P1M,3,1
samp004,CNAG_Test-RatNor-00004-KID-NOR-LCMS-C66-CHL-P3Y-B01-R10,CNAG-Test,Rat,4,Kidney,Normal,LC_MS,C66,Challenge,P3Y,1,10
EOF
    chomp( my @want = split /\n/, $want );

    is_deeply \@got, \@want, 'bulk biosample human-decode';
}

#-------------------------------------------------------------------------------
# 3) bulk biosample HUMAN-decode with condition_name
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity biosample',
      '--format human',
      '--action decode',
      "--codebook $codebook",
      '--infile ex/biosample_to_decode.csv',
      "--sep ','",
      '--with_condition_name';
    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,clar_id,project,species,subject_id,tissue,sample_type,assay,condition,timepoint,duration,batch,replicate,condition_name
samp001,CNAG_Test-HomSap-00001-LIV-NOR-RNA-C22.0-BSL-P0D-B01-R05,CNAG-Test,Human,1,Liver,Normal,RNA_seq,C22.0,Baseline,P0D,1,5,Liver cell carcinoma
samp002,CNAG_Test-MusMus-00002-BRN-TUM-CHI-C71.0-TRT-P7W-B02-R02,CNAG-Test,Mouse,2,Brain,Tumor,ChIP_seq,C71.0,Treatment,P7W,2,2,Malignant neoplasm of cerebrum, except lobes and ventricles
samp003,CNAG_Test-DanRer-00003-BLO-NOR-WES-I46-SUR-P1M-B03-R01,CNAG-Test,Zebrafish,3,Blood,Normal,WES,I46,Surgery,P1M,3,1,Cardiac arrest
samp004,CNAG_Test-RatNor-00004-KID-NOR-LCMS-C66-CHL-P3Y-B01-R10,CNAG-Test,Rat,4,Kidney,Normal,LC_MS,C66,Challenge,P3Y,1,10,Malignant neoplasm of ureter
EOF
    chomp( my @want = split /\n/, $want );

    is_deeply \@got, \@want,
      'bulk biosample human-decode --with_condition_name';

}

#-------------------------------------------------------------------------------
# 4) bulk subject STUB-encode
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity subject',
      '--format stub',
      '--action encode',
      "--codebook $codebook",
      '--infile ex/subject.csv',
      "--sep ','";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,study,subject_id,type,condition,sex,age_group,stub_id
patient_001,COPDStudy,1001,Case,J44.9,Male,Age40to49,COPDStudy0G9C3Of01MA4
patient_002,AsthmaCohort,1002,Control,J98.51,Female,Age50to59,AsthmaCohort0GAN3SM01FA5
patient_003,COPDStudy,1003,Control,J44.9,Female,Age50to59,COPDStudy0GBN3Of01FA5
patient_004,AsthmaCohort,1004,Case,J98.51,Male,Age40to49,AsthmaCohort0GCC3SM01MA4
EOF

    chomp( my @want = split /\n/, $want );

    is_deeply \@got, \@want, 'bulk subject stub-encode';
}

#-------------------------------------------------------------------------------
# 5) bulk subject HUMAN-encode
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity subject',
      '--format human',
      '--action encode',
      "--codebook $codebook",
      '--infile ex/subject.csv',
      "--sep ','";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,study,subject_id,type,condition,sex,age_group,clar_id
patient_001,COPDStudy,1001,Case,J44.9,Male,Age40to49,COPDStudy-01001-Case-J44.9-Male-A40_49
patient_002,AsthmaCohort,1002,Control,J98.51,Female,Age50to59,AsthmaCohort-01002-Control-J98.51-Female-A50_59
patient_003,COPDStudy,1003,Control,J44.9,Female,Age50to59,COPDStudy-01003-Control-J44.9-Female-A50_59
patient_004,AsthmaCohort,1004,Case,J98.51,Male,Age40to49,AsthmaCohort-01004-Case-J98.51-Male-A40_49
EOF

    chomp( my @want = split /\n/, $want );
    is_deeply \@got, \@want, 'bulk subject human-encode';

}
#-------------------------------------------------------------------------------
# 6) bulk biosample HUMAN-encode multiple conds
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity biosample',
      '--format human',
      '--action encode',
      "--codebook $codebook",
      '--infile t/data/biosample_conds.csv',
      "--sep ','";
      
    my @got = map { chomp; $_ } `$cmd`;
    
    my $want = <<'EOF';
unique_id,subject_id,project,species,tissue,sample_type,assay,condition,timepoint,duration,batch,replicate,clar_id
samp001,1,CNAG-Test,Human,Liver,Normal,RNA_seq,C22.0;C22.2;C22.3;C24.4,Baseline,P0D,1,5,CNAG_Test-HomSap-00001-LIV-NOR-RNA-C22.0+C22.2+C22.3+C24.4-BSL-P0D-B01-R05
EOF
    chomp( my @want = split /\n/, $want );
    is_deeply \@got, \@want, 'bulk biosample human-encode multiple conds';

}

#-------------------------------------------------------------------------------
# 7) bulk biosample HUMAN-decode multiple conds with condition name
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity biosample',
      '--format human',
      '--action decode',
      "--codebook $codebook",
      '--infile t/data/biosample_conds_to_decode.csv', 
      "--sep ','",
      "--with-condition-name";
 
    my @got = map { chomp; $_ } `$cmd`;
    
    my $want = <<'EOF';
unique_id,subject_id,project,species,tissue,sample_type,assay,condition,timepoint,duration,batch,replicate,clar_id,project,species,subject_id,tissue,sample_type,assay,condition,timepoint,duration,batch,replicate,condition_name
samp001,1,CNAG-Test,Human,Liver,Normal,RNA_seq,C22.0;C22.2;C22.3;C24.4,Baseline,P0D,1,5,CNAG_Test-HomSap-00001-LIV-NOR-RNA-C22.0+C22.2+C22.3+C24.4-BSL-P0D-B01-R05,CNAG-Test,Human,1,Liver,Normal,RNA_seq,C22.0;C22.2;C22.3;C24.4,Baseline,P0D,1,5,Liver cell carcinoma;Hepatoblastoma;Angiosarcoma of liver;
EOF
    chomp( my @want = split /\n/, $want );
    is_deeply \@got, \@want, 'bulk biosample human-decode multiple conds with condition name';

}

#-------------------------------------------------------------------------------
# 8) bulk subject HUMAN-decode
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity subject',
      '--format human',
      '--action decode',
      "--codebook $codebook",
      '--infile ex/subject_to_decode_human.csv',
      "--sep ','";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,clar_id,study,subject_id,type,condition,sex,age_group
patient_001,COPDStudy-01001-Case-J44.9-Male-A40_49,COPDStudy,1001,Case,J44.9,Male,Age40to49
patient_002,AsthmaCohort-01002-Control-J98.51-Female-A50_59,AsthmaCohort,1002,Control,J98.51,Female,Age50to59
patient_003,COPDStudy-01003-Control-J44.9-Female-A50_59,COPDStudy,1003,Control,J44.9,Female,Age50to59
patient_004,AsthmaCohort-01004-Case-J98.51-Male-A40_49,AsthmaCohort,1004,Case,J98.51,Male,Age40to49
EOF
    chomp( my @want = split /\n/, $want );
    is_deeply \@got, \@want, 'bulk biosample human-decode';

}

#-------------------------------------------------------------------------------
# 9) bulk subject STUB-decode
#-------------------------------------------------------------------------------
{
    my $cmd = join ' ',
      $^X,"$inc $exe code",
      '--entity subject',
      '--format stub',
      '--action decode',
      "--codebook $codebook",
      '--infile ex/subject_to_decode_stub.csv',
      "--sep ','";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
unique_id,stub_id,study,subject_id,type,condition,sex,age_group
patient_001,COPDStudy0G9C3Of01MA4,COPDStudy,1001,Case,J44.9,Male,Age40to49
patient_002,AsthmaCohort0GAN3SM01FA5,AsthmaCohort,1002,Control,J98.51,Female,Age50to59
patient_003,COPDStudy0GBN3Of01FA5,COPDStudy,1003,Control,J44.9,Female,Age50to59
patient_004,AsthmaCohort0GCC3SM01MA4,AsthmaCohort,1004,Case,J98.51,Male,Age40to49
EOF
    chomp( my @want = split /\n/, $want );
    is_deeply \@got, \@want, 'bulk biosample stub-decode';

}


done_testing();

