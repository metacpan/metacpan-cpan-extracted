#!/usr/bin/perl

use Dancer;
use lib '/home/davidp/dev/git/Dancer-Plugin-TimeRequests/lib';
use Dancer::Plugin::TimeRequests;
use Time::HiRes;
# Quick example app.

set logger => 'console';
set log => 'debug';

get '/' => sub {
    <<INDEX;
<h1>Dancer::Plugin::TimeRequests example</h1>

<p>
This simple example provides a few routes which implement a delay before
returning - hit a few of them, then go to 
<a href="/plugin-timerequests">/plugin-timerequests</a> to see the timing
information.
</p>

<h2>Simple /hello route: (random delay)</h2>
<p><a href="/hello/dave">/hello/dave</a></p>
<p><a href="/hello/bob">/hello/bob</a></p>

<h2>Fixed delays</h2>
<p><a href="/wait1">1 second</a></p>
<p><a href="/wait2">2 seconds</a></p>
<p><a href="/wait3">3 seconds</a></p>
<p><a href="/wait4">4 seconds</a></p>
<p><a href="/wait5">5 seconds</a></p>

INDEX
};

get '/hello/:name' => sub {
    sleep rand(5);
    return "Hi there, " . ucfirst params->{name};
};

get '/wait/:secs' => sub {
    sleep params->{secs};
    return "Waited for " . params->{secs} . " secs";
};

for my $wait (1..5) {
    get "/wait$wait" => sub { sleep $wait; "You waited $wait secs"; };
}

Dancer->dance;
