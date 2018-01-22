#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::MUST::Apps::TwoScalp;


# skip all two-scalp.pl tests unless blastp is available in the $PATH
unless ( qx{which blastp} ) {
    plan skip_all => <<"EOT";
skipped all two-scalp.pl tests!
If you want to use this program you need to install NCBI BLAST+ executables:
ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/
EOT
}

{
    my $class = 'Bio::MUST::Apps::TwoScalp::Seq2Seq';

    $class->new(
        ali => file('test', 'PTHR22663.ali'),
        out_suffix   => '-my-ts-s2s',
        coverage_mul => 1.01,
        single_hsp   => 0,
    );

    compare_ok(
        file('test', 'PTHR22663-my-ts-s2s.ali'),
        file('test', 'PTHR22663-ts-s2s.ali'),
            'wrote expected Ali for: PTHR22663'
    );
}

done_testing;
