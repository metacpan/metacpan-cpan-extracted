use 5.010;
use strict;
use warnings;

use Data::EventStream;
use Data::EventStream::Statistics::Discrete;
use Data::EventStream::Statistics::Continuous;
use Math::Random qw(random_exponential random_normal);
use Time::HiRes;

my $es = Data::EventStream->new(
    time_sub => sub { $_[0]->{time}; },
    time     => 0,
);

my $stat = Data::EventStream::Statistics::Discrete->new( value_sub => sub { $_[0]->{val}; }, );
$es->add_aggregator( $stat, count => 100 );
my $proc = Data::EventStream::Statistics::Continuous->new(
    time_sub  => sub { $_[0]->{time}; },
    value_sub => sub { $_[0]->{val}; },
);
$es->add_aggregator( $proc, duration => 100 );

my $time  = 0;
my $value = 0;

my $start = Time::HiRes::time;
for ( 1 .. 10000 ) {
    $time += random_exponential( 1, 1 );
    $value += random_normal( 1, 0, 1 );
    $es->add_event( { time => $time, val => $value } );
}
my $duration = Time::HiRes::time - $start;

printf "processed %d events/sec\n", 10000 / $duration;
