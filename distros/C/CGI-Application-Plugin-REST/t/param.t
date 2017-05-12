#!/usr/bin/perl

# Test rest_param.  t/devpopup.t also tests some rest_param functionality.
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 3;
use lib 't/lib';
use Test::CAPREST;

my $app = Test::CAPREST->new;

my %params = (
    alpha => 1,
    beta  => 2,
    gamma => 3,
);

$app->rest_param(\%params);
my $result;
foreach my $param ($app->rest_param()) {
    $result .= $app->rest_param($param);
}
is($result, '123', 'set params by hashref');
is($app->rest_param(), 3, 'rest_param in scalar context');

eval { $app->rest_param('some', 'bogus', 'params'); };
ok (defined $EVAL_ERROR, 'odd number of params');
