#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 11;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

# Test of Catalyst::View::Download and Catalyst::View::Download::CSV
my $compare = "\"a\",\"b\",\"c\",\"d\"\n"
             ."\"1\",\"2\",\"3\",\"4\"\n"
             ."\" \",\"\n\",\"\t\",\"!\"\n"
             ."\"\@\",\",\",\"\"\"\",\"'\"\n";
$mech->get_ok('http://localhost/csv_test/','csv test');
$mech->content_is($compare, 'is this the csv result we are looking for?');

# Test of Catalyst::View::Download and Catalyst::View::Download::HTML
$mech->get_ok('http://localhost/html_test/', 'html test');
$mech->content_like(qr/\<\/head\>\<body\>Lorem ipsum dolor sit amet/i, 'is this the html text result we are looking for?');

# Test of Catalyst::View::Download and Catalyst::View::Download::XML
$mech->get_ok('http://localhost/xml_test/', 'xml test');
$mech->content_like(qr/\<text\>Lorem ipsum dolor sit amet/i, 'is this the xml text result we are looking for?');

# Test of Catalyst::View::Download and Catalyst::View::Download::Plain
$mech->get_ok('http://localhost/plain_test/', 'plain test');
$mech->content_like(qr/Lorem ipsum dolor sit amet/i, 'is this the plain text result we are looking for?');
