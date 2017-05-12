#!perl -T 
################################################################################
# some backend tests, extra because GUUGle does not support mismatches
#
# Test fasta are sequences from ATH1.cdna, with MODIFIED sequences
################################################################################

BEGIN{
    use lib 't';
    use Test::More; 
    use Test::NoWarnings;
    use BioGrepSkip; 
    my ($skip,$msg) = BioGrepSkip::skip_all( );
    plan skip_all => $msg if $skip;
}

use BioGrepTest;

register_backend_tests({ RE => 29 });

plan tests => (1+number_backend_tests);

my %test_seq = (
    id   => 'At2g42200',
    desc => '68409.m05466 squamosa-promoter binding protein -related',
    seq  =>
        'accactctcgtctctttcttttttccttctgttctgtttctctctctaaacccaaaacagtcaaaatcagggaagccgaaattttctttgctttcttctcctttggtcctttctttaaacccgagacagttaggtttgtgtgagagagagaatgatgagtaaaaccctttctgtctgagtaagaggaaaccaacATGGAGATGGGTTCCAACTCGGGTCCGGGTCATGGTCCGGGTCAGGCAGAGTCGGGTGGTTCCTCCACTGAGTCATCCTCTTTCAGTGGAGGGCTCATGTTTGGCCAGAAGATCTACTTCGAGGACGGTGGTGGTGGATCCGGGTCTTCTTCCTCAGGTGGTCGTTCAAACAGACGTGTCCGTGGAGGCGGGTCGGGTCAGTCGGGTCAGATACCAAGGTGCCAAGTGGAAGGTTGTGGGATGGATCTAACCAATGCAAAAGGTTATTACTCGAGACACCGAGTTTGTGGAGTGCACTCTAAAACACCTAAAGTCACTGTGGCTGGTATCGAACAGAGGTTTTGTCAACAGTGCAGCAGGTTTCATCAGCTTCCGGAATTTGACCTAGAGAAAAGGAGTTGCCGCAGGAGACTCGCTGGTCATAATGAGCGACGAAGGAAGCCACAGCCTGCGTCTCTCTCTGTGTTAGCTTCTCGTTACGGGAGGATCGCACCTTCGCTTTACGAAAATGGTGATGCTGGAATGAATGGAAGCTTTCTTGGGAACCAAGAGATAGGATGGCCAAGTTCAAGAACATTGGATACAAGAGTGATGAGGCGGCCAGTGTCGTCACCGTCATGGCAGATCAATCCAATGAATGTATTTAGTCAAGGTTCAGTTGGTGGAGGAGGGACAAGCTTCTCATCTCCAGAGATTATGGACACTAAACTAGAGAGCTACAAGGGAATTGGCGACTCAAACTGTGCTCTCTCTCTTCTGTCAAATC'
);

my %hits_sequences3 = (
 'At1g01010.1' => 'tgaaaatggaggatcaagttgggt',
 'At1g01010.2' => 'aaaatggaggatcaagttgggt',
 'At1g01010.3' => 'tgaaaatggaggatcaagttgggt',
);
my %hits_sequences4 = (
 'At1g01010.1' => 'aaatggaggatcaagttgggtttg',
 'At1g01010.2' => 'aaatggaggatcaagttgggtttg',
 'At1g01010.3' => 'aaatggaggatcaagttgggtt',
);
my %hits_sequences5 = (
 'At1g01010.1' => 'atggaggatcaagttgggtttg',
 'At1g01010.2' => 'atggaggatcaagttgggtttg',
 'At1g01010.3' => 'atggaggatcaagttgggtt',
);

my $sbe = next_be;

$sbe->settings->reverse_complement(0);
$sbe->generate_database( { file => 't/Test_DB_Big.fasta',
description => 'Description for Test_DB_Big.fasta'} );
$sbe->generate_database( { file => 't/Test_DB_Extend.fasta',
 description => 'Description for Test_DB_Big.fasta',
 copy => 0 } );
$sbe->settings->query('ATGGAGGATCAAGTTGG');
$sbe->settings->database('Test_DB_Extend.fasta');
$sbe->search();
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
}
# upstream downstream tests
$sbe->settings->upstream(5);
$sbe->settings->downstream(5);
# test reverse complement
$sbe->settings->reverse_complement(1);
my $query = 'ATGGAGGATCAAGTTGG';
$sbe->settings->query(revcom_as_string($query));
$sbe->search();
while (my $res = $sbe->next_res() ) {
    is(lc($res->subject->seq), lc($query), 'subject is query'); 
}

# different up/downstream
$sbe->search({
        query => 'ATGGAGGATCAAGTTGG',
        upstream => 5,
        downstream => 2,
    });
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is(lc($res->sequence->seq), lc($hits_sequences3{$res->sequence->id}), 'sequence correct'); 
}
$sbe->search({
        query => 'ATGGAGGATCAAGTTGG',
        upstream => 2,
        downstream => 5,
    });
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is(lc($res->sequence->seq), lc($hits_sequences4{$res->sequence->id}), 'sequence correct'); 
}
$sbe->search({
        query => 'ATGGAGGATCAAGTTGG',
        downstream => 5,
    });
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is(lc($res->sequence->seq), lc($hits_sequences5{$res->sequence->id}), 'sequence correct'); 
}

# test database
$sbe->search({
    reverse_complement => 0,
    database           => 'Test_DB_Big.fasta',
    query              => 'CAGAGTCGGGTGGTTCCTCCACTGAGTCATCCTCTTTCAGTGGAGGGCTCAT',
});

my $test_seq_internal_id;
while (my $res = $sbe->next_res() ) {
     $test_seq_internal_id = $res->sequence_id
}
isnt( $test_seq_internal_id, '', 'Found internal id' ) ;
my $seqio        = $sbe->get_sequences( [$test_seq_internal_id] );
my $test_seq_obj = $seqio->next_seq();

SKIP: {
    skip "Could not get sequence object", 3
        if !defined $test_seq_obj;

    is( $test_seq_obj->id,   $test_seq{id} );
    is( $test_seq_obj->desc, $test_seq{desc} );
    is( $test_seq_obj->seq,  $test_seq{seq} );
}

# test for RE specific exceptions

eval { $sbe->search( { query => 'GAA[AT]G', reverse_complement => 1 } ) };

cmp_ok($EVAL_ERROR, '=~', qr{While doing a reverse-complement}, 
    'Exception occured with revcom and regex') || diag $EVAL_ERROR;


1;

# vim: ft=perl sw=4 ts=4 expandtab
