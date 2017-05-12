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
    my ($skip,$msg) = BioGrepSkip::skip_all( 'guugle');
    plan skip_all => $msg if $skip;
}
use BioGrepTest;
register_backend_tests({ GUUGle => 49});

plan tests => (1 + number_backend_tests);

my %test_seq = (
    id   => 'At2g42200',
    desc => '68409.m05466 squamosa-promoter binding protein -related',
    seq  =>
        'accactctcgtctctttcttttttccttctgttctgtttctctctctaaacccaaaacagtcaaaatcagggaagccgaaattttctttgctttcttctcctttggtcctttctttaaacccgagacagttaggtttgtgtgagagagagaatgatgagtaaaaccctttctgtctgagtaagaggaaaccaacATGGAGATGGGTTCCAACTCGGGTCCGGGTCATGGTCCGGGTCAGGCAGAGTCGGGTGGTTCCTCCACTGAGTCATCCTCTTTCAGTGGAGGGCTCATGTTTGGCCAGAAGATCTACTTCGAGGACGGTGGTGGTGGATCCGGGTCTTCTTCCTCAGGTGGTCGTTCAAACAGACGTGTCCGTGGAGGCGGGTCGGGTCAGTCGGGTCAGATACCAAGGTGCCAAGTGGAAGGTTGTGGGATGGATCTAACCAATGCAAAAGGTTATTACTCGAGACACCGAGTTTGTGGAGTGCACTCTAAAACACCTAAAGTCACTGTGGCTGGTATCGAACAGAGGTTTTGTCAACAGTGCAGCAGGTTTCATCAGCTTCCGGAATTTGACCTAGAGAAAAGGAGTTGCCGCAGGAGACTCGCTGGTCATAATGAGCGACGAAGGAAGCCACAGCCTGCGTCTCTCTCTGTGTTAGCTTCTCGTTACGGGAGGATCGCACCTTCGCTTTACGAAAATGGTGATGCTGGAATGAATGGAAGCTTTCTTGGGAACCAAGAGATAGGATGGCCAAGTTCAAGAACATTGGATACAAGAGTGATGAGGCGGCCAGTGTCGTCACCGTCATGGCAGATCAATCCAATGAATGTATTTAGTCAAGGTTCAGTTGGTGGAGGAGGGACAAGCTTCTCATCTCCAGAGATTATGGACACTAAACTAGAGAGCTACAAGGGAATTGGCGACTCAAACTGTGCTCTCTCTCTTCTGTCAAATC'
);

my %hits_sequences = (
 'At1g01010.1' => 'ugaaaauggaggaucaaguuggguuug',
 'At1g01010.2' => 'aaaauggaggaucaaguuggguuug',
 'At1g01010.3' => 'ugaaaauggaggaucaaguuggguu',
);
my %hits_sequences2 = (
 'At1g01010.1' => 'aaauggaggaucaaguuggguuug',
 'At1g01010.2' => 'aaauggaggaucaaguuggguuug',
 'At1g01010.3' => 'aaauggaggaucaaguuggguu',
);
my %hits_sequences3 = (
 'At1g01010.1' => 'ugaaaauggaggaucaaguugggu',
 'At1g01010.2' => 'aaaauggaggaucaaguugggu',
 'At1g01010.3' => 'ugaaaauggaggaucaaguugggu',
);
my %hits_sequences4 = (
 'At1g01010.1' => 'aaauggaggaucaaguuggguuug',
 'At1g01010.2' => 'aaauggaggaucaaguuggguuug',
 'At1g01010.3' => 'aaauggaggaucaaguuggguu',
);
my %hits_sequences5 = (
 'At1g01010.1' => 'auggaggaucaaguuggguuug',
 'At1g01010.2' => 'auggaggaucaaguuggguuug',
 'At1g01010.3' => 'auggaggaucaaguuggguu',
);

my $sbe = next_be;

$sbe->settings->reverse_complement(0);
$sbe->generate_database( { file => 't/Test_DB_Big.fasta',
 description => 'Description for Test_DB_Big.fasta'} );
$sbe->generate_database( { file => 't/Test_DB_Extend.fasta',
 description => 'Description for Test_DB_Big.fasta' });
$sbe->settings->query('auggaggaucaaguugg');
$sbe->settings->database('Test_DB_Extend.fasta');
$sbe->settings->gumismatches(0);
$sbe->search();
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
}
# upstream downstream tests
$sbe->settings->upstream(5);
$sbe->settings->downstream(5);
$sbe->settings->query_length(14);
$sbe->search();
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is($res->sequence->seq, $hits_sequences{$res->sequence->id}, 'sequence correct'); 
}
$sbe->settings->query_length(14);
$sbe->settings->query('cccgaggaucaaguugg');
$sbe->search();
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, 'gaggaucaaguugg', 'subject is query'); 
    is($res->sequence->seq, $hits_sequences2{$res->sequence->id}, 'sequence correct'); 
}
$sbe->settings->query('cccgaggaucaaguuuu');
$sbe->search();
while (my $res = $sbe->next_res() ) {
                           #ccaacuugauccuc  # rev_com
                           #cuccuaguucaacc  # complement
    is($res->subject->seq, 'gaggaucaaguugg', 'subject is query'); 
    is($res->sequence->seq, $hits_sequences2{$res->sequence->id}, 'sequence correct'); 
}
# test reverse complement
$sbe->settings->reverse_complement(1);
my $query = 'auggaggaucaaguugg';
$query =~ s/u/t/g;
$sbe->settings->query(revcom_as_string($query));
$sbe->search();
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, 'auggaggaucaaguugg', 'subject is query'); 
}

# different up/downstream
$sbe->search({
        gumismatches => 0,
        query => 'auggaggaucaaguugg',
        upstream => 5,
        downstream => 2,
    });
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is($res->sequence->seq, $hits_sequences3{$res->sequence->id}, 'sequence correct'); 
}
$sbe->search({
        gumismatches => 0,
        query => 'auggaggaucaaguugg',
        upstream => 2,
        downstream => 5,
    });
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is($res->sequence->seq, $hits_sequences4{$res->sequence->id}, 'sequence correct'); 
}
$sbe->search({
        gumismatches => 0,
        query => 'auggaggaucaaguugg',
        downstream => 5,
    });
while (my $res = $sbe->next_res() ) {
    is($res->subject->seq, $sbe->settings->query, 'subject is query'); 
    is($res->sequence->seq, $hits_sequences5{$res->sequence->id}, 'sequence correct'); 
}

# test database
$sbe->search({
    reverse_complement => 0,
    database           => 'Test_DB_Big.fasta',
    gumismatches => 0,
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

$sbe->search({
    reverse_complement => 1,
    database           => 'Test_DB_Big.fasta',
    gumismatches       => 0,
    query_file         => 't/Test_query_revcom.fasta',
    query_length       => 20,
    upstream           => 5,
    downstream         => 5,
});
my $cnt = 0;
while (my $res = $sbe->next_res() ) {
    $cnt++;
}
is($cnt,3,'3 hits found');

# test for GUUGle specific exceptions
$sbe->settings->upstream(10);
$sbe->settings->downstream(5);
$sbe->settings->gumismatches(0);

eval { $sbe->search(); };

ok(!$EVAL_ERROR, 'Exception occured with different values for up- and ' .
     'downstream.') || diag $EVAL_ERROR;

### 

$sbe->settings->downstream(10);

eval { $sbe->search(); };

ok(!$EVAL_ERROR, 'No exception occured with equal values for up- and ' .
     'downstream.') || diag $EVAL_ERROR;
###

$sbe->settings->upstream_reset;

eval { $sbe->search(); };

ok(!$EVAL_ERROR, 'No exception occured with undef up- and ' .
     'def. downstream.') || diag $EVAL_ERROR;
###

$sbe->settings->upstream_reset;


###
 
eval { $sbe->search( { query_file => 't/Test_DB_Big.fasta',  
                 query_length => 20,
                 gumismatches => 0,
             } ); 
     }; 

ok($EVAL_ERROR, 'Exception occured when revcom not set');

###

eval { $sbe->search( { query_file => 't/Test_DB_Big.fasta', 
                 query_length => 20, 
                 gumismatches => 0,
                 reverse_complement => 1  } 
             ); 
     }; 

ok(!$EVAL_ERROR, 'No exception occured when revcom set') || diag $EVAL_ERROR;

###

$sbe->verbose(2);
eval { $sbe->search( { query_file => 't/Test_DB_Big.fasta', 
                 query_length => 20, 
                 gumismatches => 1,
                 reverse_complement => 1  } 
             ); 
     }; 
$sbe->verbose(0);

cmp_ok($EVAL_ERROR, '=~',
    qr{GUUGle counts GU always as no mismatch},
    'Warning occurs.');

eval { $sbe->search( { query_file => 't/Test_DB_Big.fasta', 
                 query_length => 20, 
                 gumismatches => 0,
                 reverse_complement => 1  } 
             ); 
     }; 

ok(!$EVAL_ERROR, 'No exception occured when revcom set') || diag $EVAL_ERROR;

###

eval { $sbe->search( { query_file => 't/Test_DB_Big.fasta', 
                       gumismatches => 0,
                       reverse_complement => 1  } 
             ); 
     }; 

ok($EVAL_ERROR, 'Exception occured when query_length is missing');
             
1;

# vim: ft=perl sw=4 ts=4 expandtab
