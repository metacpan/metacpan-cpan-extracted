#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::SearchIO');
}

{
    ok(my $in = Bio::SearchIO->new(
        -format  => 'hmmer',
        -version => 3,
        -file    => 't/data/hmmscan_no_hits.out'
    ),'Initalised search io with hmmscan3 results with no hits');
    ok( my $result = $in->next_result, 'This should return nothing');
    
    ok($in = Bio::SearchIO->new(
        -format  => 'blast',
        -version => undef,
        -file    => 't/data/blast_results.out'
    ),'Initalised search io with blast results and undef version');
    ok( $result = $in->next_result, 'This should return some blast results');
    
    # Causes an infinite loop in certain versions of Bio::SearchIO
    # ok($in = Bio::SearchIO->new(
    #     -format  => 'hmmer3',
    #     -file    => 't/data/hmmscan_no_hits.out'
    # ),'Initalised search io with hmmscan3 results with no hits');
    # 
    # is(undef, $result = $in->next_result, 'This causes an infinite loop on certain versions of SearchIO');
}



done_testing();