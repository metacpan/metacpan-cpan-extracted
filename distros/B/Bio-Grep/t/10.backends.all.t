#!perl -T 
################################################################################
# some backend tests
#
# Test fasta are sequences from ATH1.cdna, with MODIFIED sequences
################################################################################


BEGIN {
    use lib 't';
    use BioGrepSkip;
    use Test::More;
    my ( $skip, $msg ) = BioGrepSkip::skip_all();
    plan skip_all => $msg if $skip;
}

use BioGrepTest;
use Test::NoWarnings;
use TestFilter;

register_backend_tests( { Agrep => 74, Vmatch => 154, GUUGle => 58, RE => 56 } );
plan tests => (2+number_backend_tests);

# backends
################################################################################

# the number of files we assume in the data directory after
# database generation.
my %backend_filecnt = (
    Agrep  => 6,
    Vmatch => 16,
    GUUGle => 4,
    RE     => 6
);

# the hits in Test_DB_Big.fasta we assume with n mismatches
my %hits = (
    At1g53160 => 2,
    At2g42200 => 1,
    At1g27360 => 1,
    At3g47170 => 3,
    At1g22000 => 4,
    At1g09950 => 5
);

my %test_seq = (
    id   => 'At2g42200',
    desc => '68409.m05466 squamosa-promoter binding protein -related',
    seq =>
        'accactctcgtctctttcttttttccttctgttctgtttctctctctaaacccaaaacagtcaaaatcagggaagccgaaattttctttgctttcttctcctttggtcctttctttaaacccgagacagttaggtttgtgtgagagagagaatgatgagtaaaaccctttctgtctgagtaagaggaaaccaacATGGAGATGGGTTCCAACTCGGGTCCGGGTCATGGTCCGGGTCAGGCAGAGTCGGGTGGTTCCTCCACTGAGTCATCCTCTTTCAGTGGAGGGCTCATGTTTGGCCAGAAGATCTACTTCGAGGACGGTGGTGGTGGATCCGGGTCTTCTTCCTCAGGTGGTCGTTCAAACAGACGTGTCCGTGGAGGCGGGTCGGGTCAGTCGGGTCAGATACCAAGGTGCCAAGTGGAAGGTTGTGGGATGGATCTAACCAATGCAAAAGGTTATTACTCGAGACACCGAGTTTGTGGAGTGCACTCTAAAACACCTAAAGTCACTGTGGCTGGTATCGAACAGAGGTTTTGTCAACAGTGCAGCAGGTTTCATCAGCTTCCGGAATTTGACCTAGAGAAAAGGAGTTGCCGCAGGAGACTCGCTGGTCATAATGAGCGACGAAGGAAGCCACAGCCTGCGTCTCTCTCTGTGTTAGCTTCTCGTTACGGGAGGATCGCACCTTCGCTTTACGAAAATGGTGATGCTGGAATGAATGGAAGCTTTCTTGGGAACCAAGAGATAGGATGGCCAAGTTCAAGAACATTGGATACAAGAGTGATGAGGCGGCCAGTGTCGTCACCGTCATGGCAGATCAATCCAATGAATGTATTTAGTCAAGGTTCAGTTGGTGGAGGAGGGACAAGCTTCTCATCTCCAGAGATTATGGACACTAAACTAGAGAGCTACAAGGGAATTGGCGACTCAAACTGTGCTCTCTCTCTTCTGTCAAATC'
);

my %hits_sequences = (
    At1g27360 => 'tgaatctcaagatatccaccGTGCTCTCTCTCTTCTGTCAacctcttcgg',
    At2g42200 => 'gggaattggcgactcaaactGTGCTCTCTCTCTTCTGTCAaatc'
    ,    # test for too short downstream
    At1g53160 => 'agattagatagagaagctgtCTGCTCTCTCTCTTCTGTCAtctaaacttc',
    At3g47170 => 'ttgataaaggcaacggcctcGTGCACTCTCTCTTCTCTCAattacttgga',
    At1g22000 => 'taccccgatgaaaagtttctGAGATCTCTTTCTTCTGTCAaacatctctt',
    At1g09950 =>
        'gccggggacaacGTTTTCACTTTCTTCTGCCCaccgtggttt'    # too short upstream
);

my %sort_modes = (
    GUUGle => [ 'ga', 'gd' ],
    RE     => [ 'ga', 'gd' ],
    Agrep  => [],
    Vmatch => [ sort(qw(la ld ia id ja jd ea ed sa sd ida idd ga gd)) ],
);

BACKEND:
while ( my $sbe = next_be() ) {
SKIP: {
        my ( $skip, $msg ) = skip_backend_test();
        skip $msg, $skip if $skip;
        #diag("\n*** Testing $backendname ***");
        my $backendname = current_backend_name;
        my %asm = $sbe->available_sort_modes();
        is_deeply(
            [ sort keys %asm ],
            $sort_modes{$backendname},
            'sortmodes as expected'
        );

        mkdir("t/data2");

        eval {
            $sbe->generate_database(
                {   file        => 't/wrong\ named.fasta',
                    description => 'Description for wrong\ named.fasta'
                }
            );
        };
        ok( $EVAL_ERROR, "exception occured with invalid filename" );

        eval {
            $sbe->generate_database(
                {   file        => 't/wrong.fasta',
                    description => 'Description for wrong.fasta'
                }
            );
        };
        cmp_ok(
            $EVAL_ERROR, '=~',
            'No such file.',
            "exception occured with not existing file"
        );

        $sbe->settings->datapath('t/wrongdata');
        eval {
            $sbe->generate_database(
                {   file        => 't/Test_DB_Big.fasta',
                    description => 'Description for Test_DB_Big.fasta'
                }
            );
        };
        ok( $EVAL_ERROR, "exception occured with not existing datapath" );

        $sbe->settings->datapath('t/data');

        my $ret = 0;
        eval {
            $ret = $sbe->generate_database(
                {   file          => 't/Test_DB_Big.fasta',
                    description   => 'Description for Test_DB_Big.fasta',
                    verbose       => 1,
                    copy          => 1,
                    prefix_length => 3,
                }
            );
        };
        ok( !$EVAL_ERROR,
            "no exception occured with dna fasta ($backendname)" )
            || diag $EVAL_ERROR;
        ok( $ret, "returned 1 with non-existing db" );

        $ret = 0;
        eval {
            $sbe->verbose(2);
            $ret = $sbe->generate_database(
                {   file        => 't/Test_DB_Big.fasta',
                    description => 'Description for Test_DB_Big.fasta',
                }
            );
        };
        $sbe->verbose(0);
        ok( !$ret, "returned 0 with existing db" ) || diag $ret;
        cmp_ok(
            $EVAL_ERROR, '=~',
            qr{Database with that name already exists},
            "Warning occured."
        ) || diag $EVAL_ERROR;

        is( $sbe->get_alphabet_of_database('Test_DB_Big.fasta'), 'dna',
            "Test_DB_Big.fasta dna
        ($backendname)"
        );

        # test if all files are there after database generation
################################################################################
        opendir( DIR, "t/data" ) || die "can't opendir t/data: $!";
        my @files = grep { /Test/ && -f "t/data/$_" } readdir(DIR);
        closedir DIR;

        foreach my $file (@files) {
            if ( $file =~ /nfo$/ ) {
                open( FILE, "t/data/$file" );
                my $filecontent = '';
                while (<FILE>) {
                    $filecontent .= $_;
                }
                close(FILE);
                is( $filecontent,
                    'Description for Test_DB_Big.fasta',
                    'Description ok'
                );
            }
        }
        is( scalar(@files), $backend_filecnt{$backendname},
            "$backend_filecnt{$backendname} $backendname index files created"
        );

        eval {
            $sbe->generate_database(
                {   file        => 't/Test_DB_Protein.fasta',
                    description => 'Description for Test_DB_Protein.fasta'
                }
            );
        };

        if ( $backendname eq 'GUUGle' ) {
            ok( $EVAL_ERROR, "exception occured with peptide fasta
                ($backendname)"
            );
        }
        else {
            ok( !$EVAL_ERROR, "no exception occured with peptide fasta
                ($backendname)"
            );
        }

        opendir( DIR, "t/data" ) || die "can't opendir t/data: $!";
        my @files2 = grep { /Test_DB_Protein/ && -f "t/data/$_" } readdir(DIR);
        closedir DIR;

        if ( $backendname ne 'GUUGle' ) {
            foreach my $file (@files2) {
                if ( $file =~ /nfo$/ ) {
                    open( FILE, "t/data/$file" );
                    my $filecontent = '';
                    while (<FILE>) {
                        $filecontent .= $_;
                    }
                    close(FILE);
                    is( $filecontent,
                        'Description for Test_DB_Protein.fasta',
                        'Description ok'
                    );
                }
            }
            is( scalar(@files2), $backend_filecnt{$backendname},
                "$backend_filecnt{$backendname} $backendname index files created"
            );
        }
        push @files, @files2;

        if ( defined $sbe->features->{PROTEINS} ) {

            is( $sbe->get_alphabet_of_database('Test_DB_Protein.fasta'), 'protein',
                "Test_DB_Big.fasta
            protein
            ($backendname)"
            );

            is_deeply(
                { $sbe->get_databases },
                {   'Test_DB_Big.fasta'     => 'Description for Test_DB_Big.fasta',
                    'Test_DB_Protein.fasta' => 'Description for Test_DB_Protein.fasta'
                }
            );
        }

        $sbe->settings->database('Test_DB_Big.fasta');

        my $sequence = 'ttattagatataccaaaccagagaaaacaaatacat';

        if ( defined $sbe->features->{NATIVE_ALIGNMENTS} ) {
            my $msu
                = 'aaaTTATTAGATATACCAAACCAGAGAAAACAAATACATaatcggagaaatacagattacagagagcga';

            if ( defined $sbe->features->{GUMISMATCHES} ) {
                $sbe->settings->gumismatches(0);
            }

            $sbe->settings->query($sequence);
            $sbe->settings->upstream(30);
            $sbe->settings->downstream(30);
            $sbe->search();
            while ( my $res = $sbe->next_res ) {
                my $t_msu = $res->mark_subject_uppercase();
                $t_msu =~ tr/Uu/Tt/;
                is( $t_msu, $msu, 'mark subject uppercase works' );
                my $t_el = 3 + length($sequence) + 30;
                is( length($t_msu), $t_el, 'length of sequence correct' );
                is( $res->begin, 3, 'begin is 3' );
                my $t_ss = $res->sequence->seq;
                $t_ss =~ tr/Uu/tt/;
                is( lc($t_ss), lc($msu), 'subject ok' );
                my $seqio = $sbe->get_sequences( [ $res->sequence_id ] );
                my $db_seq = $seqio->next_seq;
                is( lc( $db_seq->subseq( 4, 3 + length($sequence) ) ),
                    lc($sequence), 'subject found in db' );
                is( lc( $db_seq->subseq( 1, $t_el ) ),
                    lc($t_ss), 'sequence found in db' );
            }
            $sbe->settings->set_attributes( {} );
        }
        if ( defined $sbe->features->{MAXHITS} ) {
            $sequence = 'ttatt';

            $sbe->settings->query($sequence);
            if ( defined $sbe->features->{GUMISMATCHES} ) {
                $sbe->settings->gumismatches(0);
            }
            $sbe->settings->query($sequence);
            $sbe->settings->maxhits(5);
            $sbe->search();
            my $cnt = 0;
            while ( my $res = $sbe->next_res ) {
                $cnt++;
            }
            is( $cnt, 5, 'maxhits(5) returned 5 hits' );

            $sbe->settings->set_attributes( {} );
        }

        if ( $sbe->features->{DIRECT_AND_REV_COM} ) {
            my $sbe2 = Bio::Grep->new($backendname);
            $sbe2->settings->datapath('t/data2');
            $sbe2->generate_database( { file => 't/Test_DB_RevCom.fasta' } );
            $sbe2->search(
                {   query              => 'GAGCCCTT',
                    direct_and_rev_com => 1,
                    database           => 'Test_DB_RevCom.fasta',
                }
            );
            my @drc_results;
            while ( my $res = $sbe2->next_res ) {

                #   warn Dumper $res;
                push @drc_results, $res->sequence->id . ':'
                    . $res->alignment->get_seq_by_pos(1)->start;
            }
            @drc_results = sort @drc_results;
            is_deeply(
                \@drc_results,
                [ sort( 'both:29', 'both:3', 'first:6', 'second:21' ) ],
                "Direct and Rev_Com works"
            ) || diag join ',', @drc_results;

            #warn Dumper $sbe2->get_databases;
            is_deeply(
                { $sbe2->get_databases },
                { 'Test_DB_RevCom.fasta' => 'Test_DB_RevCom.fasta' },
                'filename as description when no desc'
            );

        }
        goto ENDLONGSEQS
            if ( $backendname eq 'GUUGle' || $backendname eq 'RE' );

        my $test_seq_internal_id = '';
        $sequence = 'tgacagaagagagtgagcac';

        # now search for 1 to 5 mismatches, test if reverse complement works
################################################################################
        for my $j ( 0 .. 1 ) {
            if ( $j == 0 ) {
                $sbe->settings->query($sequence);
                $sbe->settings->reverse_complement(1);
            }
            else {
                $sbe->settings->query( revcom_as_string($sequence) );
                $sbe->settings->reverse_complement(0);
            }
            for my $i ( 1 .. 5 ) {

                # test some vmatch flags
                # they should not change anything in the results
                if ( $j && $i == 5 && defined( $sbe->features->{ONLINE} ) ) {
                    $sbe->settings->online(1);
                }
                if ( !$j && $i == 5 && defined( $sbe->features->{ONLINE} ) ) {
                    $sbe->settings->online(0);
                }
                if ( $j && $i == 4 && defined( $sbe->features->{QSPEEDUP} ) )
                {
                    $sbe->settings->qspeedup(2);
                }
                if (   $j == 0
                    && $i == 4
                    && defined( $sbe->features->{QSPEEDUP} ) )
                {
                    $sbe->settings->qspeedup(2);
                }
                $sbe->settings->mismatches($i);

                $sbe->search();
                $sbe->settings->online_reset;
                $sbe->settings->qspeedup_reset;
                my @ids = ();
                while ( my $res = $sbe->next_res ) {

                    #   print STDERR "IS: " . $res->sequence->id . "\n";
                    push( @ids, $res->sequence->id );
                    $test_seq_internal_id = $res->sequence_id
                        if $res->sequence->id eq $test_seq{id};
                    if ( $i == 1 && $j == 1 ) {
                        is( uc( $res->query->seq ),
                            uc( $sbe->settings->query ),
                            'query sequence in results'
                        );
                    }
                }
                my @shouldbe = _get_ids_where_mm_smaller($i);
                foreach (@shouldbe) {

                    #    print "SHOULDBE: $_\n";
                }
                @ids = sort @ids;
                is_deeply( \@shouldbe, \@ids, "Results ok" );

                #warn Dumper(\@shouldbe, \@ids);
            }
        }

        # test if backend returns correct sequence

        isnt( $test_seq_internal_id, '', 'Found internal id' );
        my $seqio = $sbe->get_sequences( [$test_seq_internal_id] );
        my $test_seq_obj = $seqio->next_seq();

    SKIP: {
            skip "Could not get sequence object ($backendname)", 3
                if !defined $test_seq_obj;

            is( $test_seq_obj->id,   $test_seq{id} );
            is( $test_seq_obj->desc, $test_seq{desc} );
            is( $test_seq_obj->seq,  $test_seq{seq} );
        }

    ENDLONGSEQS:

        # testing, if backends find matches at the end of long sequences
################################################################################
        $sbe->settings->query('CGAGCTGATGCAAAGCTCGCGGGACTGA');
        $sbe->settings->reverse_complement(0);
        $sbe->settings->mismatches(0);
        $sbe->settings->no_alignments(1);
        $sbe->settings->gumismatches(0) if $backendname eq "GUUGle";

        $sbe->search();

        my @ids              = ();
        my $alignment_string = '';
        while ( my $res = $sbe->next_res ) {
            push( @ids, $res->sequence->id );
            eval {
                $res->verbose(2);
                $alignment_string .= $res->alignment_string;
            };
            if ( !defined $sbe->features->{NATIVE_ALIGNMENTS} ) {
                cmp_ok(
                    $EVAL_ERROR, '=~',
                    qr{No alignment calculated},
                    'Warning occured'
                ) || diag $EVAL_ERROR;
            }
        }

        is( $alignment_string, '', 'alignmentstring empty' )
            if $backendname eq 'Agrep';
        $sbe->settings->no_alignments_reset;

        #$sbe->verbose(0);
        my @shouldbe = qw( At1g67120 );
        is_deeply( \@ids, \@shouldbe, "Results ok" );

        if ( defined $sbe->features->{COMPLETE} ) {
            $sbe->settings->complete(1);
        }
        $sbe->search();

        @ids = ();
        while ( my $res = $sbe->next_res ) {
            push( @ids, $res->sequence->id );
        }
        is_deeply( \@ids, \@shouldbe, "Results ok" );

        $sbe->settings->query_reset;
        if ( $backendname eq 'Vmatch' ) {
            for my $i ( 0 .. 2 ) {
                $sbe->settings->query_file('t/Test_query.fasta');
                if ( $i == 2 ) {
                    $sbe->settings->showdesc(20);
                }
                if ( $i == 1 ) {
                    $sbe->settings->query_file('t/Test_query_revcom.fasta');
                    $sbe->settings->reverse_complement(1);
                }
                $sbe->search();

                @ids = ();
                my %multi_query_result = (
                    'At1g01020.1' => {
                        id   => 'b',
                        desc => 'descb',
                        seq  => 'CGAGTGTGAACGCATGATTATTTTCATCGATTTAA'
                    },
                    'At1g01030.1' => {
                        id   => 'c',
                        seq  => 'gttttcttccgattctagggttttcatatttc'
                    },
                    'At1g01010.1' => {
                        id   => 'a',
                        desc => 'desca',
                        seq  => 'TGTAGTGAGGGCTTTCGTGGTAAGATT'
                    }
                );
                while ( my $res = $sbe->next_res ) {

                    is( $res->query->id,
                        $multi_query_result{ $res->sequence->id }->{id} );
                    is( $res->query->desc,
                        $multi_query_result{ $res->sequence->id }->{desc} );
                    if ( $sbe->settings->reverse_complement ) {
                        is( $res->query->revcom->seq,
                            $multi_query_result{ $res->sequence->id }
                                ->{seq} );
                    }
                    else {
                        is( $res->query->seq,
                            $multi_query_result{ $res->sequence->id }
                                ->{seq} );
                    }
                }
                $sbe->settings->showdesc_reset;
                $sbe->settings->reverse_complement_reset;
            }
            my $seqio = $sbe->get_sequences( ['At2g42200'] );
            my $db_seq = $seqio->next_seq;
            is( $db_seq->seq, $test_seq{seq},
                "vmatch get_sequences with description works" );
        }

        $sbe->settings->complete_reset();
        $sbe->settings->query_file_reset();
        my $long_query
            = 'AAATTATTAGATATACCAAACCAGAGAAAACAAATACATAATCGGAGAAATACAGATTACAGAGAGCGAGAGAGATCGACGGCGAAGCTCTTTACCCGGAAACCATTGAAATCGGACGGTTTAGTGAAAATGGAGGATCAAGTTGGGTTTGGGTTCCGTCCGAACGACGAGGAGCTCGTTGGTCACTATCTCCGTAACAAAATCGAAGGAAACACTAGCCGCGACGTTGAAGTAGCCATCAGCGAGGTCAACATCTGTAGCTACGATCCTTGGAACTTGCGCTTCCAGTCAAAGTACAAATCGAGAGATGCTATGTGGTACTTCTTCTCTCGTAGAGAAAACAACAAAGGGAATCGACAGAGCAGGACAACGGTTTCTGGTAAATGGAAGCTTACCGGAGAATCTGTTGAGGTCAAGGACCAGTGGGGATTTTGTAGTGAGGGCTTTCGTGGTAAGATTGGTCATAAAAGGGTTTTGGTGTTCCTCGATGGAAGATACCCTGACAAAACCAAATCTGATTGGGTTATCCACGAGTTCCACTACGACCTCTTACCAGAACATCAGAGGACATATGTCATCTGCAGACTTGAGTACAAGGGTGATGATGCGGACATTCTATCTGCTTATGCAATAGATCCCACTCCCGCTTTTGTCCCCAATATGACTAGTAGTGCAGGTTCTGTGGTCAACCAATCACGTCAACGAAATTCAGGATCTTACAACACTTACTCTGAGTATGATTCAGCAAATCATGGCCAGCAGTTTAATGAAAACTCTAACATTATGCAGCAGCAACCACTTCAAGGATCATTCAACCCTCTCCTTGAGTATGATTTTGCAAATCACGGCGGTCAGTGGCTGAGTGACTATATCGACCTGCAACAGCAAGTTCCTTACTTGGCACCTTATGAAAATGAGTCGGAGATGATTTGGAAGCATGTGATTGAAGAAAATTTTGAGTTTTTGGTAGATGAAAGGACATCTATGCAACAGCATTACAGTGATCACCGGCCCAAAAAACCTGTGTCTGGGGTTTTGCCTGATGATAGCAGTGATACTGAAACTGGATCAATGATTTTCGAAGACACTTCGAGCTCCACTGATAGTGTTGGTAGTTCAGATGAACCGGGCCATACTCGTATAGATGATATTCCATCATTGAACATTATTGAGCCTTTGCACAATTATAAGGCACAAGAGCAACCAAAGCAGCAGAGCAAAGAAAAGGTGATAAGTTCGCAGAAAAGCGAATGCGAGTGGAAAATGGCTGAAGACTCGATCAAGATACCTCCATCCACCAACACGGTGAAGCAGAGCTGGATTGTTTTGGAGAATGCACAGTGGAACTATCTCAAGAACATGATCATTGGTGTCTTGTTGTTCATCTCCGTCATTAGTTGGATCATTCTTGTTGGTTAAGAGGTCAAATCGGATTCTTGCTCAAAATTTGTATTTCTTAGAATGTGTGTTTTTTTTTGTTTTTTTTTCTTTGCTCTGTTTTCTCGCTCCGGAAAAGTTTGAAGTTATATTTTATTAGTATGTAAAGAAGAGAAAAAGGGGGAAAGAAGAGAGAAGAAAAATGCAGAAAATCATATATATGAATTGGAAAAAAGTATATGTAATAATAATTAGTGCATCGTTTTGTGGTGTAGTTTATATAAATAAAGTGATATATAGTCTTGTATAAG';

        my $gum = 1;
        $gum = 0 if $backendname eq 'GUUGle';
        my $long_matches = 0;
        if ( $backendname ne 'Agrep' ) {

            #'Agrep wants shorter queries
            $sbe->search(
                {   database     => 'Test_DB_Big.fasta',
                    query        => $long_query,
                    gumismatches => $gum,
                }
            );
            while ( my $res = $sbe->next_res ) {
                is( $res->sequence->id, 'At1g01010.1', 'id correct' );
                my $seq = lc( $res->sequence->seq );
                $seq =~ tr{u}{t};

                is( $seq, lc($long_query), 'id correct' );
                $long_matches++;
            }
            is($long_matches, 1, 'only one longmatch' );
        }
################################################################################
        # test upstream/downstream
################################################################################
        if ( $backendname eq 'Agrep' ) {
            ok( !( defined( $sbe->features->{UPSTREAM} ) ),
                "$backendname does not support upstream"
            );
            ok( !( defined( $sbe->features->{DOWNSTREAM} ) ),
                "$backendname does not support downstream"
            );
        }
        else {
            ok( defined( $sbe->features->{UPSTREAM} ),
                "$backendname does support upstream"
            );
            ok( defined( $sbe->features->{DOWNSTREAM} ),
                "$backendname does support downstream"
            );
            goto EXCEPTIONS
                if ( $backendname eq 'GUUGle' || $backendname eq 'RE' );
            my $sequence = 'tgacagaagagagtgagcac';
            if ( defined( $sbe->features->{COMPLETE} ) ) {
                $sbe->settings->complete(0);
            }
            $sbe->settings->query($sequence);
            $sbe->settings->reverse_complement(1);
            $sbe->settings->mismatches(5);
            $sbe->settings->no_alignments(1);
            $sbe->settings->upstream(20);
            $sbe->settings->downstream(10);
            $sbe->settings->gumismatches($gum);

            $sbe->search();
            $sbe->settings->complete_reset;
            my @ids = ();
            while ( my $res = $sbe->next_res ) {

                #         print STDERR "IS: " . $res->sequence->id . "\n";
                #       print STDERR $res->mark_subject_uppercase() . "\n";
                my $subject = $hits_sequences{ $res->sequence->id };
                $subject =~ s/[^AGCT]//g;
                is( $res->subject->id, $res->sequence->id,
                    "Subject id same as sequence id" );
                is( uc( $res->subject->seq ), $subject, "Subject correct" );
                is( $res->mark_subject_uppercase(),
                    $hits_sequences{ $res->sequence->id },
                    "sequence und marking subject correct."
                );
                push( @ids, $res->sequence->id );

            }
            my @shouldbe = _get_ids_where_mm_smaller(5);
            @ids = sort @ids;
            is_deeply( \@shouldbe, \@ids, "Results ok" );
        }

    EXCEPTIONS:
        $sbe->settings->database('BLA');
        eval { $sbe->search() };

        cmp_ok(
            $EVAL_ERROR, '=~',
            qr{Database not found},
            'Database not found'
        ) || diag $EVAL_ERROR;

        # check exceptions with insecure sortmode
        $sbe->settings->database('Test_DB_Big.fasta');
        $sbe->settings->sort('&& ls *;');
        $sbe->settings->query('ATTTTCG');
        $sbe->settings->mismatches(0);
        $sbe->settings->reverse_complement(0);
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong sort mode" );

        $sbe->settings->sort('gd');
        $sbe->verbose(2);
        my @results;
        eval { $sbe->search() };
        if ( $backendname eq "Agrep" ) {
            cmp_ok( $EVAL_ERROR, '=~',
                qr{Sort mode not valid},
                "$backendname: Exception occured with invalid sort mode."
            ) || diag $EVAL_ERROR;
        }
        else {
            cmp_ok( $EVAL_ERROR, '=~',
                qr{Not sorting results by dG because some results have},
                "$backendname: Not sorting warning occured."
            ) || diag $EVAL_ERROR;
        }
        # add random dG values to avoid warning
        $sbe->settings->filters( TestFilter->new() );
        eval { $sbe->search() };
        if ( $backendname ne "Agrep" ) {
            ok( !$EVAL_ERROR, 
                "$backendname: No exception occured with valid sort mode."
            ) || diag $EVAL_ERROR;
            @results = BioGrepTest::get_sorted_result_ids($sbe);
            # guugle also allows GU
            cmp_ok(scalar(@results),'>=', 5, '>5 results') ||
                diag join ',', @results;
        }
        $sbe->verbose(0);
        $sbe->settings->query( substr( $long_query, 0, 25 ) );


        $sbe->settings->filters_reset;
        $sbe->settings->sort_reset;

        if (   defined $sbe->features->{MISMATCHES}
            && defined $sbe->features->{EDITDISTANCE} )
        {
            $sbe->settings->mismatches(1);
            $sbe->settings->editdistance(1);
            eval { $sbe->search() };
            cmp_ok(
                $EVAL_ERROR, '=~',
                "Can't combine editdistance and mismatches",
                'Exception with editdistance and mismatches'
            );

            $sbe->settings->mismatches(0);
            eval { $sbe->search() };
            ok( !$EVAL_ERROR,
                'No Exception with editdistance and 0 mismatches' )
                || diag $EVAL_ERROR;

            $sbe->settings->mismatches_reset;
            eval { $sbe->search() };
            ok( !$EVAL_ERROR,
                'No Exception with editdistance and undef mismatches' )
                || diag $EVAL_ERROR;

            $sbe->settings->mismatches(0);
            $sbe->settings->editdistance(0);
            eval { $sbe->search() };
            ok( !$EVAL_ERROR,
                'No Exception with 0 editdistance and 0 mismatches' )
                || diag $EVAL_ERROR;

            $sbe->settings->editdistance_reset;
        }

        #check exceptions with insecure database
        $sbe->settings->database('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong database" );
        $sbe->settings->database('Test_DB_Big.fasta');
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct database" )
            || diag $EVAL_ERROR;
        $sbe->settings->database_reset;
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with no database" );

        # check exceptions with insecure mismatches
        $sbe->settings->database('Test_DB_Big.fasta');
        $sbe->settings->mismatches('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong mismatches" );
        $sbe->settings->mismatches(0);
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct mismatches" )
            || diag $EVAL_ERROR;

        # check exceptions with insecure insertions
        $sbe->settings->insertions('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong insertions" );
        $sbe->settings->insertions(0);
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct insertions" )
            || diag $EVAL_ERROR;

        # check exceptions with insecure insertions
        $sbe->settings->no_alignments('&& ls *;');
        eval { $sbe->_check_search_settings };
        ok( $EVAL_ERROR, "Exception occured with wrong no_alignments" );
        $sbe->settings->no_alignments(1);
        eval { $sbe->_check_search_settings };
        ok( !$EVAL_ERROR, "No Exception occured with correct insertions" )
            || diag $EVAL_ERROR;
        $sbe->settings->no_alignments_reset;

        if ( defined $sbe->features->{QUERY_LENGTH} ) {

            # check exceptions with insecure query_length
            $sbe->settings->query_length('&& ls *;');
            eval { $sbe->search() };
            ok( $EVAL_ERROR, "Exception occured with wrong query_length" );
            $sbe->settings->query_length(10);
            eval { $sbe->search() };
            ok( !$EVAL_ERROR,
                "No Exception occured with correct query_length" )
                || diag $EVAL_ERROR;
            $sbe->settings->query_length_reset;
            eval { $sbe->search() };
            ok( !$EVAL_ERROR,
                "No Exception occured with correct query_length" )
                || diag $EVAL_ERROR;
        }

        my $tmp_query = $sbe->settings->query;
        if ( defined $sbe->features->{QUERY_FILE} ) {
            $sbe->settings->query_file('t/Test_query.fasta');
            $sbe->settings->query_length(50);
            $sbe->settings->reverse_complement(1);
            eval { $sbe->search() };
            ok( $EVAL_ERROR, "Exception occured with query and query_file" );
            $sbe->settings->query_reset;
            eval { $sbe->search() };
            ok( !$EVAL_ERROR, "No Exception occured with correct query_file" )
                || diag $EVAL_ERROR;

            $sbe->settings->query_file('&& ls *;');
            eval { $sbe->search };
            ok( $EVAL_ERROR, "No Exception occured with unsafe query_file" );
            $sbe->settings->query_file_reset;
            $sbe->settings->query_length_reset;
        }
        $sbe->settings->query_file_reset;
        $sbe->settings->query_reset;
        eval { $sbe->search() };
        ok( $EVAL_ERROR =~ 'Query not defined.',
            "Exception occured when query and query_file undef" );

        $sbe->settings->query($tmp_query);

        if ( $backendname eq 'Vmatch' ) {
            $sbe->settings->hxdrop('&& ls *;');
            eval { $sbe->search() };
            ok( $EVAL_ERROR, "Exception occured with wrong hxdrop" );
            $sbe->settings->hxdrop(1);
            eval { $sbe->search() };
            ok( !$EVAL_ERROR, "No Exception occured with correct hxdrop" )
                || diag $EVAL_ERROR;
            $sbe->settings->hxdrop_reset;
            $sbe->settings->exdrop('&& ls *;');
            eval { $sbe->search() };
            ok( $EVAL_ERROR, "Exception occured with wrong exdrop" );
            $sbe->settings->exdrop(1);
            eval { $sbe->search() };
            ok( !$EVAL_ERROR, "No Exception occured with correct exdrop" )
                || diag $EVAL_ERROR;
            $sbe->settings->exdrop_reset;
        }

        # check exceptions with insecure upstream
        $sbe->settings->upstream('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong upstream" );
        $sbe->settings->upstream(0);
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct upstream" );
        $sbe->settings->upstream_reset;
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct upstream" );

        # check exceptions with insecure downstream
        $sbe->settings->downstream('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong downstream" );
        $sbe->settings->downstream(0);
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct downstream" );
        $sbe->settings->downstream_reset;
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct upstream" );

        # check exceptions with insecure maxhits
        $sbe->settings->maxhits('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong maxhits" );

        @results = ();
        if ( defined $sbe->features->{MISMATCHES} ) {
            $sbe->settings->mismatches(5);

            $sbe->settings->maxhits(3);
            $sbe->settings->query($sequence);
            $sbe->settings->reverse_complement(1);

            $sbe->verbose(2);
            eval { $sbe->search() };
            $sbe->verbose(0);

            if ( defined $sbe->features->{MAXHITS} ) {
                ok( !$EVAL_ERROR,
                    "No Exception occured with correct maxhits" )
                    || diag $EVAL_ERROR;

                @results = BioGrepTest::get_sorted_result_ids($sbe);
                is( scalar @results, 3,, "only 3 results ($backendname)" );
            }
            else {
                cmp_ok(
                    $EVAL_ERROR, '=~',
                    qr{maxhits not available in this back-end},
                    'Warning when maxhits not available'
                );
            }
            $sbe->settings->maxhits_reset;
            eval { $sbe->search() };
            ok( !$EVAL_ERROR, "No Exception occured with correct maxhits" );
            @results = BioGrepTest::get_sorted_result_ids($sbe);
            is_deeply(
                \@results,
                [   qw(At1g09950 At1g22000 At1g27360 At1g53160 At2g42200  At3g47170)
                ],
                "all results ($backendname)"
            );
        }
        $sbe->settings->mismatches(0);
        $sbe->settings->maxhits_reset;

        # check exceptions with insecure edit distance
        $sbe->settings->editdistance('&& ls *;');
        eval { $sbe->search() };
        ok( $EVAL_ERROR, "Exception occured with wrong editdistance" );
        $sbe->verbose(2);
        $sbe->settings->editdistance(1);
        eval { $sbe->search() };
        $sbe->verbose(0);

        if ( defined $sbe->features->{EDITDISTANCE} ) {
            ok( !$EVAL_ERROR,
                "No Exception occured with correct editdistance" )
                || diag $EVAL_ERROR;
        }
        else {
            cmp_ok(
                $EVAL_ERROR, '=~',
                qr{editdistance not available in this back-end},
                'Warning when editdistance not available'
            );
        }
        goto CLEANUP if ( $backendname eq 'GUUGle' || $backendname eq 'RE' );

        $sbe->settings->editdistance_reset;
        $sbe->settings->mismatches(1);
        eval { $sbe->search() };
        ok( !$EVAL_ERROR, "No Exception occured with correct editdistance" );

        $sbe->settings->database('Test_DB_Protein.fasta');
        eval { $sbe->search() };
        ok( $EVAL_ERROR,
            "Exception occured when searching dna seq in pep db" );

        $sbe->settings->query('IDSPALKELHLSEV');
        $sbe->settings->reverse_complement(0);
        eval { $sbe->search() };
        ok( !$EVAL_ERROR,
            "No Exception occured when searching pep seq in pep db" );
        @results = BioGrepTest::get_sorted_result_ids($sbe);
        is_deeply( \@results, ['AT1G22000.1'], 'Correct results' );

        $sbe->settings->reverse_complement(1);
        eval { $sbe->search() };
        cmp_ok(
            $EVAL_ERROR, '=~',
            qr{Reverse complement only available for},
            "No Exception occured when searching pep seq in pep db"
        );
        $sbe->settings->reverse_complement(0);

        if ( defined $sbe->features->{DIRECT_AND_REV_COM} ) {
            $sbe->settings->direct_and_rev_com(1);
            eval { $sbe->search() };
            cmp_ok(
                $EVAL_ERROR, '=~',
                qr{Reverse complement only available for},
                "No Exception occured when searching pep seq in pep db"
            );
            $sbe->settings->reverse_complement(0);
        }

        $sbe->settings->database('Test_DB_Big.fasta');
        eval { $sbe->search() };
        ok( $EVAL_ERROR,
            "Exception occured when searching pep seq in dna db" );

        if ( $backendname eq 'Vmatch' ) {
            eval {
                $sbe->search(
                    {   query => 'GACCTCTTACCAGAACATCAGAGGACATATGTCATCTGCA',
                        reverse_complement => 0,
                        upstream           => 5,
                        showdesc           => 100,
                    }
                );
            };
            ok( $EVAL_ERROR, 'Exception occured when upstream and showdesc' );
            eval {
                $sbe->search(
                    {   query => 'GACCTCTTACCAGAACATCAGAGGACATATGTCATCTGCA',
                        reverse_complement => 0,
                        downstream         => 5,
                        showdesc           => 100,
                    }
                );
            };
            ok( $EVAL_ERROR,
                'Exception occured when downstream and showdesc' );
            eval {
                $sbe->search(
                    {   query => 'GACCTCTTACCAGAACATCAGAGGACATATGTCATCTGCA',
                        reverse_complement => 0,
                        upstream           => 5,
                        downstream         => 5,
                        showdesc           => 100,
                    }
                );
            };
            ok( $EVAL_ERROR,
                'Exception occured when up-&downstream and showdesc' );
            eval {
                $sbe->search(
                    {   query => 'GACCTCTTACCAGAACATCAGAGGACATATGTCATCTGCA',
                        reverse_complement => 0,
                        showdesc           => 100,
                    }
                );
            };
            ok( !$EVAL_ERROR, 'No exception occured without up/down' )
                || diag $EVAL_ERROR;
            eval {
                $sbe->search(
                    {   query => 'GACCTCTTACCAGAACATCAGAGGACATATGTCATCTGCA',
                        reverse_complement => 0,
                        complete           => 1,
                        qspeedup           => 2,
                    }
                );
            };
            ok( $EVAL_ERROR,
                'Exception occured without qspeedup and complete' );

            eval { $sbe->search( { query_file => 't/Test_query.fasta', } ); };
            ok( $EVAL_ERROR =~ /You have to specify complete/,
                'Exception occured missing complete or query_file'
            );
            eval {
                $sbe->search(
                    {   query_file => 't/Test_query.fasta',
                        complete   => 1,
                    }
                );
            };
            ok( !$EVAL_ERROR, 'No exception occured with complete' )
                || diag $EVAL_ERROR;

            eval {
                $sbe->search(
                    {   query_file   => 't/Test_query.fasta',
                        query_length => 30,
                    }
                );
            };
            ok( !$EVAL_ERROR, 'No exception occured with query_length' )
                || diag $EVAL_ERROR;

            diag("\n** Now you should see a Vmatch error **\n");
            eval {
                $sbe->search(
                    {   query      => 'AACCCTCAAAGCC',
                        mismatches => 10,
                        maxhits    => 100,
                    }
                );
            };
            ok( $EVAL_ERROR =~ /Vmatch call failed/,
                'Exception occured with too many mismatches'
            );

            $sbe->search(
                {   query              => 'AACCCTCAAAGCC',
                    reverse_complement => 0,
                    mismatches         => 3,
                    maxhits            => 100,
                    sort               => 'sa',
                }
            );
            my @ids;

            while ( my $res = $sbe->next_res() ) {
                push @ids, $res->sequence->id;
            }
            is_deeply(
                \@ids,
                [ 'At1g01040.1', 'At1g01040.1', 'At1g67120', 'At3g47170' ],
                'sorting works'
            );

        }
        elsif ( $backendname eq 'Agrep' ) {
            eval {
                $sbe->search(
                    {   query      => 'CCCCCCCACCCCCCCCCCCCCCCCCC',
                        mismatches => 0,
                    }
                );
            };
            cmp_ok(
                $EVAL_ERROR, '=~',
                qr{Agrep call failed. Command was},
                'Exception occured when agrep call failed'
            );
        }

################################################################################
        # clean up
    CLEANUP:
        foreach my $file (@files) {
            $file = $sbe->is_word($file);
            unlink("t/data/$file") || diag "Can't delete $file: $!";
        }

        #diag (`ls -lah t/data/`);
        #diag (`cat t/data/*`);
        #diag join("\n", 'XXX', readdir(DIR), 'ZZZ');
        rmdir("t/tmp"), rmdir("t/data"),

#        ok( rmdir("t/tmp"),
#           "Can remove tmp directory (all temp files deleted)" );
# caused problems on NFS drives
#ok( rmdir("t/data"),
#    "Can remove data directory (all data files deleted-just a test for the test)"
#) or diag $!;
#exit if $backendname eq 'RE'
    }    #SKIP

}

eval { Bio::Grep->new('UnknownBackend'); };
ok( $EVAL_ERROR, 'Exception occured with unknown backend' );


# some helper functions
################################################################################
################################################################################
sub _get_ids_where_mm_smaller {
    my $mm = shift;
    my @results;
    foreach my $key ( keys %hits ) {
        push( @results, $key ) if $hits{$key} <= $mm;
    }
    return sort @results;
}

1;

# vim: ft=perl sw=4 ts=4 expandtab
