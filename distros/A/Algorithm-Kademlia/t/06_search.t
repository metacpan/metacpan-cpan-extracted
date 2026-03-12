use v5.40;
use Test2::V0;
use lib '../lib';
use Algorithm::Kademlia;
#
my $target = pack 'H*', 'f0' . ( '00' x 19 );
my $search = Algorithm::Kademlia::Search->new( target_id_bin => $target, k => 2, alpha => 2 );
#
subtest 'Iterative Search State' => sub {
    my $p1 = { id => pack( 'H*', 'f1' . ( '00' x 19 ) ), data => { ip => '1.1.1.1' } };
    my $p2 = { id => pack( 'H*', 'f2' . ( '00' x 19 ) ), data => { ip => '2.2.2.2' } };
    my $p3 = { id => pack( 'H*', 'a0' . ( '00' x 19 ) ), data => { ip => '3.3.3.3' } };
    $search->add_candidates( $p1, $p2, $p3 );
    my @to_query = $search->next_to_query();
    is scalar(@to_query), 2,         'Returns alpha=2 candidates';
    is $to_query[0]{id},  $p1->{id}, 'Closest first';
    is $to_query[1]{id},  $p2->{id}, 'Second closest';
    ok !$search->is_finished, 'Not finished yet';
    $search->mark_responded( $p1->{id} );
    $search->mark_failed( $p2->{id} );
    @to_query = $search->next_to_query();
    is scalar(@to_query), 1,         'One more candidate available (p3)';
    is $to_query[0]{id},  $p3->{id}, 'p3 is next';
    $search->mark_responded( $p3->{id} );
    ok $search->is_finished, 'Finished because no more candidates';
    my @results = $search->best_results();
    is scalar(@results), 2,         'Returns up to k=2 results';
    is $results[0]{id},  $p1->{id}, 'Best result is p1';
};
#
done_testing;
