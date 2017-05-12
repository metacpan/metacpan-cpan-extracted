#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use CPAN::Critic::Module::Abstract qw(critique_cpan_module_abstract);

my $res;

my @tests = (
    {abstract=>"", res=>{pass=>0}},
    {abstract=>"A module to do foo", res=>{pass=>0}},
);

#for my $t (@tests) {
#    subtest ($t->{name} // $t->{abstract}) => sub {
#        my $res = critique_cpan_module_abstract(abstract=>$t->{abstract});
#    };
#}

ok(1);
done_testing();
