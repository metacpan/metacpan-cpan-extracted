#!/usr/bin/env perl -w
use strict;
use Test::Cukes;
use Chart::Timecard;
use DateTime;

{
    local $/ = undef;
    feature(<DATA>);
}

my ($chart, @times, @weights, $size, $url);

Given qr/100 time objects and their weights/ => sub {
    @times = map { DateTime->from_epoch(epoch => time() + int(rand(86400))) } 1..100;
    @weights = map { int(rand(20)) } 1..100;
    $size = "900x300";
};

Given qr/a random size/ => sub {
    $size = int(rand(300)) . "x" . int(rand(300));
};

When qr/they are used to instantiate a timecard object/ => sub {
    $chart = Chart::Timecard->new(times => \@times, size => $size);
    assert $chart;
};

Then qr/the url of timecard chart can be returned/ => sub{
    assert( $chart->can("url") );

    $url = $chart->url;
    assert($url =~ m{^http://chart.apis.google.com/chart\?cht=s.+$});
};

Then qr/the url of timecard should specify the wanted chart size/ => sub {
    $url = $chart->url;
    # Test::More::note("size = ${size}\nurl = $url");

    assert($url =~ m/chs=${size}/);
};

runtests;

__DATA__
Feature: generate a timecard chart url
  In order to see an interesting presentation of times
  Here the Chart::Timecard object comes

  Scenario: from a series of time
    Given 100 time objects and their weights
    When they are used to instantiate a timecard object
    Then the url of timecard chart can be returned

  Scenario: with specified size
    Given 100 time objects and their weights
    And a random size
    When they are used to instantiate a timecard object
    Then the url of timecard chart can be returned
    And the url of timecard should specify the wanted chart size
