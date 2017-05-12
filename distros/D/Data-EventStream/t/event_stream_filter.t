use Test::Most;
use Test::FailWarnings;

use Data::EventStream;

use lib 't/lib';
use Averager;
use TestStream;

my %params = ( 'c2' => { count => 2 }, );

my @events = (
    {
        val => 2,
        ins => { c2 => 2, },
    },
    { val => 4, },
    {
        val => 1,
        ins => { c2 => 1.5 },
    },
    { val => 5, },
    {
        val  => 0,
        outs => { c2 => 1.5 },
        ins  => { c2 => 0.5 },
    },
    {
        val  => 2,
        outs => { c2 => 0.5 },
        ins  => { c2 => 1 },
    },
    { val => 5, },
);

TestStream->new(
    aggregator_class  => 'Averager',
    aggregator_params => \%params,
    filter            => sub { $_[0]{val} < 3 },
    events            => \@events,
)->run;

done_testing;
