use strict;
use Test2::V0;
use BettingStrategy::MonteCarlo;

# new
my $strategy = BettingStrategy::MonteCarlo->new;
isa_ok $strategy, 'BettingStrategy::MonteCarlo';

# array
{
    my $got      = $strategy->array;
    my $expected = +[qw{1 2 3}];
    is $got, $expected;
}

# bet
{
    my $got      = $strategy->bet;
    my $expected = 4;
    is $got, $expected;
}

# lost
{
    $strategy->lost;
    my $got      = $strategy->array;
    my $expected = +[qw{1 2 3 4}];
    is $got, $expected;
}

# bet
{
    my $got      = $strategy->bet;
    my $expected = 5;
    is $got, $expected;
}

# won
{
    $strategy->won;
    my $got      = $strategy->array;
    my $expected = +[qw{2 3}];
    is $got, $expected;
};

# is_finished
ok !$strategy->is_finished;

# bet
{
    my $got      = $strategy->bet;
    my $expected = 5;
    is $got, $expected;
}

# won
{
    $strategy->won;
    my $got      = $strategy->array;
    my $expected = +[];
    is $got, $expected;
}

# is_finished
ok $strategy->is_finished;

like dies { $strategy->bet },  qr{\Qfinished\E};
like dies { $strategy->won },  qr{\Qfinished\E};
like dies { $strategy->lost }, qr{\Qfinished\E};

done_testing;
__END__
