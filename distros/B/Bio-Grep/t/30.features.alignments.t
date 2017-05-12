#!perl #-T
################################################################################
# does the alignments look the same in all back-ends?
################################################################################

BEGIN {
    use lib 't';
    use Test::More;
    use Test::NoWarnings;
    use BioGrepSkip;
    my ( $skip, $msg ) = BioGrepSkip::skip_all();
    plan skip_all => $msg if $skip;
}
use BioGrepTest;

register_backend_tests( { Agrep => 20, Vmatch => 29, GUUGle => 29, RE => 29 } );
plan tests => (1+number_backend_tests);

################################################################################

BACKEND:
while ( my $sbe = next_be() ) {
SKIP: {
        # diag current_backend_name;
        my ( $skip, $msg ) = skip_backend_test();
        skip $msg, $skip if $skip;

        $sbe->generate_database(
            {  file     => 't/Test_DB_Small.fasta', }
        );
        $sbe->generate_database(
            {  file     => 't/Test_DB_RevCom.fasta', }
        );
        my $gumm = 1;
        $gumm = 0 if current_backend_name eq 'GUUGle';
        
        # search with string query
        ######################################################################
        my $query = 'AGCGATTACCGAGTATCGTTGGGTATGCT';

        eval {
            $sbe->search(
                {   query        => $query,
                    gumismatches => $gumm,
                    database     => 'Test_DB_Small.fasta',
                }
            );
        }; # eval

        ok( !$EVAL_ERROR, 'Search successful' ) || diag $EVAL_ERROR;

        while ( my $res = $sbe->next_res ) {
            my $subject = $res->alignment->get_seq_by_pos(1);
            my $seq;

        SKIP: {
                skip 'WuManber Agrep', 3
                    if ( current_backend_name eq 'Agrep'
                    && !$sbe->is_tre_agrep );
                is( $subject->start, 550, 'Pos Alignment Subject no revcom' );
                is( $subject->end,   578, 'Pos Alignment Subject no revcom' );
                $seq = uc( $subject->seq );
                $seq =~ tr{U}{T};
                is( $seq,
                    'AGCGATTACCGAGTATCGTTGGGTATGCT',
                    'Sequence Subject no revcom'
                );
            } # skip

            my $query = $res->alignment->get_seq_by_pos(2);
            is( $query->start, 1,  'Pos Alignment Query no revcom' );
            is( $query->end,   29, 'Pos Alignment Query no revcom' );
            $seq = uc( $query->seq );
            $seq =~ tr{U}{T};
            cmp_ok(
                $seq, '=~',
                qr{AGCGATTACCGAGTATCGTTGGGTATGCT},
                'Query Subject Correct'
            );
            is( $query->id, '1',  'Alignment Query id no revcom' );
            is( $res->query->desc, 'Query' ,  'Query desc no revcom' );
        } # while

        eval {
            $sbe->search(
                {   query              => revcom_as_string($query),
                    gumismatches       => $gumm,
                    reverse_complement => 1,
                }
            );
        }; # eval    

        ok( !$EVAL_ERROR, 'Search successful' ) || diag $EVAL_ERROR;
        while ( my $res = $sbe->next_res ) {
            my $subject = $res->alignment->get_seq_by_pos(1);
            my $seq;
            my $query = $res->alignment->get_seq_by_pos(2);
            is( $query->id, '1',  'Alignment Query id revcom' );
            is( $res->query->desc, 'Query (reverse complement)' ,  
                'Query desc revcom' );
        }; # while

        # search with Bio::Seq Query
        ######################################################################
        my $query_obj = Bio::Seq->new(-id => '42',
                                      -desc => 'Some Query',
                                      -seq  => revcom_as_string($query));

        eval {
            $sbe->search(
                {   query              => $query_obj,
                    gumismatches       => $gumm,
                    reverse_complement => 1,
                }
            );
        }; # eval
        ok( !$EVAL_ERROR, 'Search successful' ) || diag $EVAL_ERROR;
        while ( my $res = $sbe->next_res ) {
            #warn $res->alignment_string;
            my $subject = $res->alignment->get_seq_by_pos(1);
            my $seq;
            my $query = $res->alignment->get_seq_by_pos(2);
            is( $query->id, '42',  'Alignment Query id Bio::Seq revcom' );
            is( $res->query->desc, 'Some Query (reverse complement)' ,  
                'Query desc Bio::Seq revcom' );
            ok($res->reverse_complement, 'reverse_complement is 1');
        }; # while 
        
        $query_obj = Bio::Seq->new(-id => '42',
                                   -desc => 'Some Query',
                                   -seq  => $query);
                                  #warn Dumper $query_obj;                          
        eval {
            $sbe->search(
                {   query              => $query_obj,
                    gumismatches       => $gumm,
                }
            );
        }; # eval

        ok( !$EVAL_ERROR, 'Search successful' ) || diag $EVAL_ERROR;
        while ( my $res = $sbe->next_res ) {
            #warn $res->alignment_string;
            my $subject = $res->alignment->get_seq_by_pos(1);
            my $seq;
            my $query = $res->alignment->get_seq_by_pos(2);
            is( $query->id, '42',  'Alignment Query id Bio::Seq no revcom' );
            is( $res->query->desc, 'Some Query' ,  
                'Query desc Bio::Seq no revcom' );
            ok(!$res->reverse_complement, 'reverse_complement is 0');
        }; # while 

        next BACKEND if !defined $sbe->features->{DIRECT_AND_REV_COM};

        # search with Bio::Seq, direct and revcom
        ######################################################################
        $query_obj = Bio::Seq->new(-id => '42',
                                      -desc => 'Some Query',
                                      -seq  => 'GAGCCCTT');

        eval {
            $sbe->search(
                {   query              => $query_obj,
                    gumismatches       => $gumm,
                    direct_and_rev_com => 1,
                    database           => 'Test_DB_RevCom.fasta',
                }
            );
        }; # eval
        #exit if current_backend_name eq 'GUUGle';
        #exit if current_backend_name eq 'Vmatch';

        ok( !$EVAL_ERROR, 'Search successful (direct_and_revcom)' ) || diag $EVAL_ERROR;

        my $rct =  ' (reverse complement)';
        #if (defined $sbe->features->{NATIVE_D_A_REV_COM}) {
        #    $rct = '';
        #}

        my %query_desc = ( 
            'both:3'    => 'Some Query',
            'both:29'   => 'Some Query' . $rct,
            'first:6'   => 'Some Query',
            'second:21' => 'Some Query' . $rct,
        ); 

        while ( my $res = $sbe->next_res ) {
            #warn $res->alignment_string;
            my $key = $res->subject->id . ':' . $res->alignment->get_seq_by_pos(1)->start;
            is( $res->query->id, '42',  'Alignment Query id Bio::Seq direct_and_revcom' );
            is( $res->query->desc, $query_desc{$key}, 'Desc Query Bio::Seq direct_and_revcom' );
        }; # while 


    } # skip
}

delete_files;
rmdir('t/data');
rmdir('t/tmp');

# vim: ft=perl sw=4 ts=4 expandtab
