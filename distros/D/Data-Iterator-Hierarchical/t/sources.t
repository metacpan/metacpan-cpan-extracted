#!perl

# Test the input sources

use Test::More tests => 3;

use strict;
use warnings;

use Data::Iterator::Hierarchical;

my @test_data=([1,1],[2,2]);

sub test_identity_iterator {
    my ($test,$sth) = @_;
    my $it = hierarchical_iterator($sth);
    is_deeply([map{[$it->()]} 0..@test_data],[@test_data,[]],$test);
}

test_identity_iterator('array',[@test_data]);

my @consulmable = @test_data;
sub Data::Iterator::Hierarchical::Test::fetchrow_array { @{shift(@consulmable)||[]} }
test_identity_iterator('object', bless {},'Data::Iterator::Hierarchical::Test');

@consulmable = @test_data;
test_identity_iterator('code',\&Data::Iterator::Hierarchical::Test::fetchrow_array);



