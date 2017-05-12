#!/usr/bin/perl
use lib '../';
use Benchmark qw(:all);
use Data::Dumper;
use Algorithm::SAT::Expression;
my $result = cmpthese(
    100000,
    {   'SAT::Backtracking' => sub {
            my $expr = Algorithm::SAT::Expression->new;
            $expr->or( '-foo@2.1', 'bar@2.2' );
            $expr->or( '-foo@2.3', 'bar@2.2' );
            $expr->or( '-baz@2.3', 'bar@2.3' );
            $expr->or( '-baz@1.2', 'bar@2.2' );
            $expr->solve;
        },
        'SAT::Backtracking::DPLL' => sub {
            my $expr = Algorithm::SAT::Expression->new->with(
                "Algorithm::SAT::Backtracking::DPLL");
            $expr->or( '-foo@2.1', 'bar@2.2' );
            $expr->or( '-foo@2.3', 'bar@2.2' );
            $expr->or( '-baz@2.3', 'bar@2.3' );
            $expr->or( '-baz@1.2', 'bar@2.2' );
            $expr->solve;
        },
        'SAT::Backtracking::DPLLProb' => sub {
            my $expr = Algorithm::SAT::Expression->new->with(
                "Algorithm::SAT::Backtracking::DPLLProb");
            $expr->or( '-foo@2.1', 'bar@2.2' );
            $expr->or( '-foo@2.3', 'bar@2.2' );
            $expr->or( '-baz@2.3', 'bar@2.3' );
            $expr->or( '-baz@1.2', 'bar@2.2' );
            $expr->solve;
        },
            'Algorithm::SAT::Backtracking::Ordered' => sub {
            my $expr = Algorithm::SAT::Expression->new->with(
                "Algorithm::SAT::Backtracking::Ordered");
            $expr->or( '-foo@2.1', 'bar@2.2' );
            $expr->or( '-foo@2.3', 'bar@2.2' );
            $expr->or( '-baz@2.3', 'bar@2.3' );
            $expr->or( '-baz@1.2', 'bar@2.2' );
            $expr->solve;
            }

    }
);

