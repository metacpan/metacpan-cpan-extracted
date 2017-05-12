use strict;
use warnings;
use lib 'lib';
use Benchmark qw(cmpthese :hireswallclock);
use Data::WeightedRoundRobin;
use Data::RoundRobin;

my @data = ('a'..'z', 'A'..'Z', 0..9);
my $rr1 = Data::RoundRobin->new(@data);
my $rr2 = Data::RoundRobin->new(qw/foo bar baz/);

my $dwr1 = Data::WeightedRoundRobin->new([@data]);
my $dwr2 = Data::WeightedRoundRobin->new([qw/foo bar baz/]);

cmpthese -1, {
    rr1  => sub { $rr1->next },
    rr2  => sub { $rr2->next },
    dwr1 => sub { $dwr1->next },
    dwr2 => sub { $dwr2->next },
}, 'all';
