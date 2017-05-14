#!/usr/bin/env perl

use Dancer2;
use Dancer2::Plugin::ProbabilityRoute;

get '/' => probability
    33 => sub { "1/3 good job!"},
    67 => sub { "2/3, so common..." };

get '/showme' => sub {
    "Your score is : ".probability_user_score;
};

start;
