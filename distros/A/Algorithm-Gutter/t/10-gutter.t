#!perl
# 10-gutter.t - test basic functionality
use Test2::V0;
use Algorithm::Gutter;

my ( $rgv, $rsv );

my $g = Algorithm::Gutter->new(
    rain => sub {
        my ( $gutter, $stash ) = @_;
        $rgv = $gutter;
        $rsv = $stash;
    },
);

is $g->gutter, [];
$g->rain($$);
is $rgv,      [];
is $rsv,      $$;
is $g->slosh, undef;    # slosh had nothing to work with

$g->set_rain(
    sub {
        my ( $gutter, $stash ) = @_;
        $gutter->[0]->amount++;
    }
);
push @{ $g->gutter }, Algorithm::Gutter::Cell->new;
is $g->gutter->[0]->amount, 0;
$g->rain;
is $g->gutter->[0]->amount, 1;
is $g->slosh,               undef;    # not enough to work with

push @{ $g->gutter }, Algorithm::Gutter::Cell->new;
$g->rain;
is $g->gutter->[0]->amount, 2;
# once to move the value, and another loop where nothing happens
is $g->slosh,               2;
is $g->gutter->[0]->amount, 1;
is $g->gutter->[1]->amount, 1;

$_->amount = 0 for $g->gutter->@*;
push @{ $g->gutter }, Algorithm::Gutter::Cell->new;
$g->set_rain(
    sub {
        my ( $gutter, $stash ) = @_;
        $gutter->[1]->amount = 3;
    }
);
$g->rain;
is $g->slosh(1), 1;    # only one iteration allowed
is [ map $g->gutter->[$_]->amount, 0 .. 2 ], [ 1, 1, 1 ];

$_->amount                 = 0 for $g->gutter->@*;
$g->gutter->[1]->context   = "middle";
$g->gutter->[1]->enabled   = 1;
$g->gutter->[1]->threshold = 2;
$g->gutter->[1]->update    = sub {
    my ( $cell, $index, $amount, $stash ) = @_;
    return [ $cell->context, $index, $amount, $stash ];
};
$g->rain;
is [ $g->drain ],           [ [ "middle", 1, 3, undef ] ];
is $g->gutter->[1]->amount, 0;

# Only drains up to the threshold value, not everything which is
# the default.
$g->rain;
is [ $g->drain( 0, "stash" ) ], [ [ "middle", 1, 2, "stash" ] ];
is $g->gutter->[1]->amount,     1;

# Nothing drains if we disable the hole in the gutter.
$g->gutter->[1]->enabled = 0;
$g->rain;
is [ $g->drain ], [];

# TODO need more code coverage tests

done_testing
