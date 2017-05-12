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

register_backend_tests( { Vmatch => 15, GUUGle => 15, RE => 15 } );
plan tests => (1+number_backend_tests);

################################################################################

my %hits_sequences = (
 'At1g01010.1' => { upstream   => 'tgaaa',
                    subject    => 'atggaggatcaagttgg',
                    downstream => 'gtttg',}, 
 'At1g01010.2' => { upstream   => 'aaa',
                    subject    => 'atggaggatcaagttgg',
                    downstream => 'gtttg',}, 
 'At1g01010.3' => { upstream   => 'tgaaa',
                    subject    => 'atggaggatcaagttgg',
                    downstream => 'gtt',}, 
);

BACKEND:
while ( my $sbe = next_be() ) {
SKIP: {
        #diag current_backend_name;
        my ( $skip, $msg ) = skip_backend_test();
        skip $msg, $skip if $skip;

        $sbe->generate_database(
            {  file     => 't/Test_DB_Extend.fasta', }
        );

        my $gum = 1;
        $gum = 0 if current_backend_name eq 'GUUGle';

        $sbe->search({
                query => 'ATGGAGGATCAAGTTGG',
                database => 'Test_DB_Extend.fasta',
                upstream => 5,
                downstream  => 5,
                gumismatches => $gum,
            });        
        while (my $res = $sbe->next_res() ) {
            my $subject = lc $res->subject->seq;
            $subject =~ tr[u][t];
            is($subject, lc $sbe->settings->query, 'subject is query');
            my $hs = $hits_sequences{$res->sequence->id};
            my $sequence = lc $res->sequence->seq;
            $sequence =~ tr[u][t];
            is($sequence, lc join(q{},($hs->{upstream},
                        $hs->{subject}, $hs->{downstream})), 'sequence correct'); 

            my $upstream = lc $res->upstream->seq;
            $upstream =~ tr[u][t];
            is($upstream,   lc $hs->{upstream},   'upstream correct');

            is($subject,    lc $hs->{subject},    'subject correct');

            my $downstream = lc $res->downstream->seq;
            $downstream =~ tr[u][t];
            is($downstream, lc $hs->{downstream}, 'downstream correct');
        }


    } # skip
}

delete_files;
rmdir('t/data');
rmdir('t/tmp');

# vim: ft=perl sw=4 ts=4 expandtab
