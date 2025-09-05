#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions qw(catfile catdir);
use Test::More tests => 27;

my $codebook = catfile('share','clarid-codebook.yaml');
my $exe     = catfile('bin', 'clarid-tools');
my $inc    = join ' -I', '', @INC;    # prepend -I to each path in @INC
my $logfile  = catfile('t','tmp_logfile');


# 1. Biosample human encode (default codebook path)
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode "
      . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D --batch 1 --replicate 5";
    my $out = `$cmd`;
    chomp $out;
    is(
        $out,
        'TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0D-B01-R05',
        'biosample human encode (default codebook path)'
    );
}

# 2. Biosample human decode
{
    my $cmd =
"$^X $inc $exe code --entity biosample --format human --action decode --codebook $codebook "
      . "--clar_id TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0D-B01-R05";
    my $out = `$cmd`;

    chomp $out;
    my @lines = split /\n/, $out;
    is_deeply(
        \@lines,
        [
            'project: TCGA-AML',
            'species: Human',
            'subject_id: 1',
            'tissue: Liver',
            'sample_type: Tumor',
            'assay: RNA_seq',
            'condition: I25.110',
            'timepoint: Baseline',
            'duration: P0D',
            'batch: 1',
            'replicate: 5',
        ],
        'biosample human decode'
    );
}

# 3. Biosample stub encode
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format stub --action encode --codebook $codebook "
      . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Challenge --duration P1M --batch 1 --replicate 5";
    my $out = `$cmd`;

    chomp $out;
    is( $out, 'AML01001LTR2to01C1MB01R05', 'biosample stub encode' );
}

# 4. Biosample stub decode
{
    my $cmd =
"$^X $inc $exe code --entity biosample --format stub --action decode --codebook $codebook "
      . "--clar_id AML01001LTR2to01C1MB01R05 --subject_id_base62_width 3";
    my $out = `$cmd`;
    chomp $out;
    my @lines = split /\n/, $out;
    is_deeply(
        \@lines,
        [
            'project: TCGA-AML',
            'species: Human',
            'subject_id: 1',
            'tissue: Liver',
            'sample_type: Tumor',
            'assay: RNA_seq',
            'condition: I25.110',
            'timepoint: Challenge',
            'duration: P1M',
            'batch: 1',
            'replicate: 5',
        ],
        'biosample stub decode'
    );
}

# 5. Subject human encode
{
    my $cmd =
"$^X $inc $exe code --entity subject --format human --action encode --codebook $codebook "
      . "--study TestCohort --type Case --sex Male --age_group Age20to29 --subject_id 7 --condition I25.110";
    my $out = `$cmd`;
    chomp $out;
    is(
        $out,
        'TestCohort-00007-Case-I25.110-Male-A20_29',
        'subject human encode'
    );
}

# 6. Subject human decode
{
    my $cmd =
"$^X $inc $exe code --entity subject --format human --action decode --codebook $codebook "
      . "--clar_id TestCohort-00007-Case-I25.110-Male-A20_29";
    my $out = `$cmd`;
    chomp $out;
    my @lines = split /\n/, $out;
    is_deeply(
        \@lines,
        [
            'study: TestCohort',
            'subject_id: 7',
            'type: Case',
            'condition: I25.110',
            'sex: Male',
            'age_group: Age20to29',
        ],
        'subject human decode'
    );
}

# 7. Subject stub encode (subject_id 500K -subject_id_base62_width 4)
{
    my $cmd =
"$^X $inc $exe code --entity subject --format stub --action encode --codebook $codebook "
      . "--study TestCohort --type Case --sex Male --age_group Age20to29 --subject_id 500000 --condition I25.110 --subject_id_base62_width 4";
    my $out = `$cmd`;
    chomp $out;
    is( $out, 'TestCohort264WC2to01MA2', 'subject stub encode' );
}

# 8. Subject stub decode (subject_id 500K -subject_id_base62_width 4)
{
    my $cmd =
"$^X $inc $exe code --entity subject --format stub --action decode --codebook $codebook "
      . "--stub_id  TestCohort264WC2to01MA2 --subject_id_base62_width 4";
    my $out = `$cmd`;

    chomp $out;

    my @lines = split /\n/, $out;
    is_deeply(
        \@lines,
        [
            'study: TestCohort',
            'subject_id: 500000',
            'type: Case',
            'condition: I25.110',
            'sex: Male',
            'age_group: Age20to29',
        ],
        'subject stub decode'
    );
}

# 9. Biosample human encode with subject_id = 0 (zero‑padding)
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode --codebook $codebook "
      . "--species Human --subject_id 0 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D --batch 1 --replicate 1";
    my $out = `$cmd`;
    chomp $out;
    is(
        $out,
        'TCGA_AML-HomSap-00000-LIV-TUM-RNA-I25.110-BSL-P0D-B01-R01',
        'biosample human encode subject_id=0 pads to 00000'
    );
}

# 10. Biosample human encode with subject_id = 123 (00123)
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode --codebook $codebook "
      . "--species Human --subject_id 123 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D --batch 1 --replicate 2";
    my $out = `$cmd`;
    chomp $out;
    is(
        $out,
        'TCGA_AML-HomSap-00123-LIV-TUM-RNA-I25.110-BSL-P0D-B01-R02',
        'biosample human encode subject_id=123 pads to 00123'
    );
}

# 11. Biosample stub encode with subject_id = 61 → base62 “00z”
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format stub --action encode --codebook $codebook "
      . "--species Human --subject_id 61 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D --batch 1 --replicate 3";
    my $out = `$cmd`;
    chomp $out;
    $out =~ /^.{5}(.{3})/;
    is( $1, '00z', 'stub field is "00z" for subject_id=61' );
}

# 12. Biosample stub encode with subject_id = 62 → base62 “010”
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format stub --action encode --codebook $codebook "
      . "--species Human --subject_id 62 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D  --batch 1 --replicate 4";
    my $out = `$cmd`;
    chomp $out;
    $out =~ /^.{5}(.{3})/;
    is( $1, '010', 'stub field is "010" for subject_id=62' );
}

# 13. Biosample human encode without batch and replicate default codebook
{   
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode "
      . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D";
    my $out = `$cmd`;
    chomp $out;
    is(
        $out,
        'TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0D',
        'biosample human encode (no batch no replicate default codebook path)'
    ); 
}

# 14. Biosample human encode without batch and replicate default codebook

{
    my $cmd =
"$^X $inc $exe code --entity biosample --format human --action decode "
      . "--clar_id TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0D";
    my $out = `$cmd`;

    chomp $out;
    my @lines = split /\n/, $out;
    is_deeply(
        \@lines,
        [
            'project: TCGA-AML',
            'species: Human',
            'subject_id: 1',
            'tissue: Liver',
            'sample_type: Tumor',
            'assay: RNA_seq',
            'condition: I25.110',
            'timepoint: Baseline',
            'duration: P0D',
            'batch: ',
            'replicate: ',
        ],
        'biosample human decode (no batch no replicate default codebook path)'
    );
}

# 15. Biosample human encode without batch and replicate default codebook multiple ICD

{
    my $cmd =
"$^X $inc $exe code --entity biosample --format human --action decode "
      . "--clar_id TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110+C22.0-BSL-P0D";
    my $out = `$cmd`;
    
    chomp $out;
    my @lines = split /\n/, $out;
    is_deeply(
        \@lines,
        [
            'project: TCGA-AML',
            'species: Human',
            'subject_id: 1',
            'tissue: Liver',
            'sample_type: Tumor',
            'assay: RNA_seq',
            'condition: I25.110;C22.0',
            'timepoint: Baseline',
            'duration: P0D',
            'batch: ',
            'replicate: ',
        ],
        'biosample human decode (no batch no replicate default codebook path)'
    );
}   


# 16. Biosample human encode w/ multiple ICD (default codebook path)
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode "
      . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110,C22.0 --timepoint Baseline --duration P0D --batch 1 --replicate 5";
    my $out = `$cmd`;
    chomp $out;
    is(     
        $out,
        'TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110+C22.0-BSL-P0D-B01-R05',
        'biosample human encode w/ multiple ICD (default codebook path)'
    );
}

# 17. Subject human encode w/ multiple ICD
{
    my $cmd =
"$^X $inc $exe code --entity subject --format human --action encode --codebook $codebook "
      . "--study TestCohort --type Case --sex Male --age_group Age20to29 --subject_id 7 --condition I25.110,C22.0";
    my $out = `$cmd`;
    chomp $out;
    is(
        $out,
        'TestCohort-00007-Case-I25.110+C22.0-Male-A20_29',
        'subject human encode w/ multiple ICD'
    );
}

# 18. Subject human decode w/ multiple ICD
{
    my $cmd =
"$^X $inc $exe code --entity subject --format human --action decode --codebook $codebook "
      . "--clar_id TestCohort-00007-Case-I25.110+C22.0-Male-A20_29 --with-condition-name";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
study: TestCohort
subject_id: 7
type: Case
condition: I25.110+C22.0
sex: Male
age_group: Age20to29
condition_name: Atherosclerotic heart disease of native coronary artery with unstable angina pectoris;Liver cell carcinoma
EOF
    chomp( my @want = split /\n/, $want );

    is_deeply \@got, \@want, 'subject human decode w/ multiple ICD with-condition-name';
}   

# 19. Subject human encode w/ multiple ICD
{
    my $cmd =
"$^X $inc $exe code --entity subject --format stub --action encode --codebook $codebook "
      . "--study TestCohort --type Case --sex Male --age_group Age20to29 --subject_id 7 --condition I25.110,C22.0";
    my $out = `$cmd`;
    chomp $out;

    is(
        $out,
        'TestCohort007C2to0N402MA2',
        'subject stub encode w/ multiple ICD'
    );
}

# 20. Subject human decode w/ multiple ICD
{
    my $cmd =
"$^X $inc $exe code --entity subject --format stub --action decode --codebook $codebook "
      . "--stub_id TestCohort007C2to0N402MA2 --with-condition-name";

    my @got = map { chomp; $_ } `$cmd`;

    my $want = <<'EOF';
study: TestCohort
subject_id: 7
type: Case
condition: I25.110;C22.0
sex: Male
age_group: Age20to29
condition_name: Atherosclerotic heart disease of native coronary artery with unstable angina pectoris;Liver cell carcinoma
EOF
    chomp( my @want = split /\n/, $want );

    is_deeply \@got, \@want, 'subject stub decode w/ multiple ICD with-condition-name';
}

# 21. Biosample human encode with duration=P0N
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode --codebook $codebook "
  . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
  . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0N --batch 1 --replicate 5";
    my $out = `$cmd`; chomp $out;
    is(
        $out,
        'TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0N-B01-R05',
        'biosample human encode duration=P0N'
    );
}

# 22. Biosample human decode with P0N
{
    my $cmd =
"$^X $inc $exe code --entity biosample --format human --action decode --codebook $codebook "
  . "--clar_id TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0N-B01-R05";
    my $out = `$cmd`; chomp $out;
    my @lines = split /\n/, $out;
    is_deeply \@lines, [
        'project: TCGA-AML',
        'species: Human',
        'subject_id: 1',
        'tissue: Liver',
        'sample_type: Tumor',
        'assay: RNA_seq',
        'condition: I25.110',
        'timepoint: Baseline',
        'duration: P0N',
        'batch: 1',
        'replicate: 5',
    ], 'biosample human decode duration=P0N';
}

# 23. Biosample stub encode with duration=P0N -> stub ends in 0N
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format stub --action encode --codebook $codebook "
  . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
  . "--assay RNA_seq --condition I25.110 --timepoint Challenge --duration P0N --batch 1 --replicate 5";
    my $out = `$cmd`; chomp $out;
    is( $out, 'AML01001LTR2to01C0NB01R05', 'biosample stub encode duration=P0N -> 0N' );
}

# 24. Biosample stub decode with 0N -> P0N
{
    my $cmd =
"$^X $inc $exe code --entity biosample --format stub --action decode --codebook $codebook "
  . "--clar_id AML01001LTR2to01C0NB01R05 --subject_id_base62_width 3";
    my $out = `$cmd`; chomp $out;
    my @lines = split /\n/, $out;
    is_deeply \@lines, [
        'project: TCGA-AML',
        'species: Human',
        'subject_id: 1',
        'tissue: Liver',
        'sample_type: Tumor',
        'assay: RNA_seq',
        'condition: I25.110',
        'timepoint: Challenge',
        'duration: P0N',
        'batch: 1',
        'replicate: 5',
    ], 'biosample stub decode duration 0N -> P0N';
}

# 25. Human encode rejects invalid P7N
{
    my $cmd =
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode --codebook $codebook "
  . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
  . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P7N";
    system($cmd . " 2>/dev/null");
    ok( $? != 0, 'human encode rejects P7N (invalid duration)' );
}

# 26. Stub decode rejects non-zero N (e.g., 7N)
{
    my $cmd =
"$^X $inc $exe code --entity biosample --format stub --action decode --codebook $codebook "
  . "--clar_id AML01001LTR2to01C7NB01R05 --subject_id_base62_width 3";
    system($cmd . " 2>/dev/null");
    ok( $? != 0, 'stub decode rejects duration with non-zero N' );
}

# 27. Create log file
{   
    my $cmd = 
"$^X $inc $exe code --project TCGA-AML --entity biosample --format human --action encode "
      . "--species Human --subject_id 1 --tissue Liver --sample_type Tumor "
      . "--assay RNA_seq --condition I25.110 --timepoint Baseline --duration P0D --batch 1 --replicate 5 --log $logfile";
    my $out = `$cmd`;
    chomp $out;
    is( 
        $out,
        'TCGA_AML-HomSap-00001-LIV-TUM-RNA-I25.110-BSL-P0D-B01-R05',
        'biosample human encode (default codebook path)'
    );  
unlink $logfile;
}

done_testing();

