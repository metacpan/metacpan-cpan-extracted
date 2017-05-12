#!/usr/bin/env perl
use strict;
use Test::More;
{

    package BasicPaxos;
    use Moose;
    with qw(
        Algorithm::Paxos::Role::Proposer
        Algorithm::Paxos::Role::Acceptor
        Algorithm::Paxos::Role::Learner
    );
}

my @synod = map { BasicPaxos->new() } ( 0 .. 2 );

# wire up acceptors
$synod[0]->_set_acceptors( \@synod );
$synod[1]->_set_acceptors( \@synod );
$synod[1]->_set_acceptors( \@synod );

# wire learners
$synod[0]->_set_learners( \@synod );
$synod[1]->_set_learners( \@synod );
$synod[1]->_set_learners( \@synod );

{
    ok( !$synod[1]->proposal_count, 'no proposal recorded' );
    my $id = $synod[0]->prospose('Hello World');
    ok( defined $id, 'made a proposal' );
    is( $synod[1]->proposal_count, 1, 'got a proposal recorded' );
    ok( $synod[1]->proposal($id) eq $synod[2]->proposal($id),
        'same proposal in two nodes' );
}

{
    my $id = $synod[0]->prospose('All good things');
    ok( defined $id, 'made a proposal' );
    is( $synod[1]->proposal_count, 2, 'got a proposal recorded' );
    ok( $synod[1]->proposal($id) eq $synod[2]->proposal($id),
        'same proposal in two nodes' );
}

{
    my $id = $synod[0]->prospose('Must end');
    ok( defined $id, 'made a proposal' );
    is( $synod[1]->proposal_count, 3, 'got a proposal recorded' );
    ok( $synod[1]->proposal($id) eq $synod[2]->proposal($id),
        'same proposal in two nodes' );
}

done_testing();
