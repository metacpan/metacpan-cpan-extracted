#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::Most tests => 1;

=encoding utf8

=head1 NAME

Cast from native types to perl types back and fort

=head1 TESTS

=cut

BEGIN {
    use_ok('AI::XGBoost::CAPI::RAW');
}

