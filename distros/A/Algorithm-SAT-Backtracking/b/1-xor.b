#!/usr/bin/perl
use lib '../';
use Benchmark qw(:all);
use Data::Dumper;
use Algorithm::SAT::Expression;
my $result = cmpthese(
    100000,
    {   'SAT::Backtracking' => sub {
            my $expr = Algorithm::SAT::Expression->new;
            $expr->xor( "foo", "bar" );
	    $expr->xor( "foo", "bar", "baz" );
            $expr->solve;
        },
        'SAT::Backtracking::DPLL' => sub {
            my $expr = Algorithm::SAT::Expression->new->with(
                "Algorithm::SAT::Backtracking::DPLL");
            $expr->xor( "foo", "bar" );
            $expr->xor( "foo", "bar", "baz" );
            $expr->solve;
        },
        'SAT::Backtracking::DPLLProb' => sub {
            my $expr = Algorithm::SAT::Expression->new->with(
                "Algorithm::SAT::Backtracking::DPLLProb");
            $expr->xor( "foo", "bar" );
            $expr->xor( "foo", "bar", "baz" );
            $expr->solve;
        },
            'Algorithm::SAT::Backtracking::Ordered' => sub {
            my $expr = Algorithm::SAT::Expression->new->with(
                "Algorithm::SAT::Backtracking::Ordered");
            $expr->xor( "foo", "bar" );
            $expr->xor( "foo", "bar", "baz" );
            $expr->solve;
            }

    }
);

