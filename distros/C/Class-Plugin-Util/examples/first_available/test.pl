#!/usr/bin/perl
use strict;
use warnings;

use MyApp::Export;

my %data = (
    'foo'       => 'bar',
    'bar'       => 'foo',
    'foobar'    => 'barfoo',
    'barfoo'    => 'foobar',
    'foobarfoo' => 'barfoobar',
    'barfoobar' => 'foobarfoo',
    'barbarfoo' => 'foofoobar',
);

my $exporter  = MyApp::Export->new({format => 'YAML'});
die unless $exporter;
print "EXPORT format => YAML ISA: ", ref $exporter, "\n";

print $exporter->export(\%data), "\n";

my $exporter2 = MyApp::Export->new({format => 'JSON'});
die unless $exporter2;

print $exporter2->export(\%data), "\n";

print "EXPORT format => JSON ISA: ", ref $exporter2, "\n";
