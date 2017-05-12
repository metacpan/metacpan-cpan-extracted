#!/usr/bin/env perl

package FakeSystem;
use strict;

our @commands;

sub stub {
    return unless $_[0] eq 'wget';
    my @args = @_;
    push @commands, [ @args ];
    my $outputfile;
    do { $outputfile = shift @args } while (@args && $outputfile ne '-O');
    $outputfile = shift @args;
    open my $fp, ">$outputfile" or die "could not open $outputfile: $!";
    print $fp <<'ENDOFXML';
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:georss="http://www.georss.org/georss"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:gml="http://www.opengis.net/gml"
 xmlns:datacasting="http://datacasting.jpl.nasa.gov/datacasting"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://omiopsmds1:8202/service/rss?esdt=OMTO3">
<title>OMTO3</title>
<link>http://omiopsmds1:8202/service/rss?esdt=OMTO3</link>
<description>OMTO3 data</description>
<dc:language>en-us</dc:language>
<dc:date>2007-03-13T07:00+00:00</dc:date>
<dc:subject>rss feed for OMTO3 data</dc:subject>
<syn:updatePeriod>daily</syn:updatePeriod>
<syn:updateFrequency>1</syn:updateFrequency>
<syn:updateBase>1901-01-01T00:00+00:00</syn:updateBase>

</channel>
</rdf:RDF>

ENDOFXML
    close $fp or die "error closing $outputfile: $!";
    return 1;
}

package main;

# Pragmas
use strict;
use warnings;

# Modules
use Data::Downloader;
use Test::More  tests => 6;
use t::lib::functions;


Log::Log4perl->get_logger("")->level("DEBUG");

my $test_dir = scratch_dir();
# diag "storing tree in $test_dir";

my $mds = Data::Downloader::Repository->new(
    name              => "mds2",
    storage_root      => "$test_dir/store",
    cache_strategy    => "LRU",
    cache_max_size    => 1024,
    file_url_template => "http://example.com/data/<md5>/<filename>",
    disks             => [ map +{ root => "disk$_/"}, (1..100) ],
    feeds             => {
        name          => "georss",
        feed_template => 'https://example.com?esdt=<esdt>',
        file_source   => {
            url_xpath      => "default:link",
            md5_xpath      => "datacasting:md5",
            filename_xpath => "datacasting:filename",
        },
    },
);
ok($mds->save, "Saved repository");

is($mds->name,             "mds2",   "set repository name");
is($mds->feeds->[0]->name, "georss", "set feed name");

ok(my $db = $mds->init_db, "Initialize DB") or BAIL_OUT $mds->error;

$ENV{TEST_SYSTEM_STUB} = "FakeSystem::stub";

$mds->feeds->[0]->refresh( download => 0, esdt => 'OMNO2', user => 'fakeusr',
			   password => 'fakepwd' );

my $found = 0;
for my $cmd (@FakeSystem::commands) {
   for my $arg (@$cmd) {
        $found++ if $arg =~ /(fakeusr|fakepwd)/
   } 
}

is($found, 2, "found user and password in system calls");

ok(test_cleanup($test_dir, $db), "Test clean up");

1;

