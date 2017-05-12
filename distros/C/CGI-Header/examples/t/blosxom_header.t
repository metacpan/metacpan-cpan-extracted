use strict;
use warnings;
use Test::Output;
use Test::More tests => 2;

BEGIN {
    use_ok 'Blosxom::Header';
}

sub run_blosxom {
    package blosxom;
    require CGI;

    our $static_entries = 0;
    our $header = { -type => 'text/html' };
    our $output = 'hello, world';

    my $plugin = 'my_plugin';
    $plugin->start && $plugin->last;

    print CGI::header($header) . $output;
}

package my_plugin;

sub start {
    !$blosxom::static_entries;
}

sub last {
    my $header = Blosxom::Header->instance;
    $header->set( 'Content-Length' => length $blosxom::output );
}

package main;

stdout_like \&run_blosxom, qr{Content-length: 12};
