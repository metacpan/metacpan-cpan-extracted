#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 29;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";  # t/lib
use lib "$Bin/../lib";  # CX-LF/lib


# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/start', 'Reset SQLite DB');

$mech->get_ok('/list/track', 'Get /list/track');

$mech->content_like(qr{TEMPLATE\sOK}xsm, 'Template compiles');
$mech->content_like(qr{\b13\sentries}xsm, 'Right number of records');
$mech->content_like(qr{track\scode.+track\stitle.+album\sreleased.+artist\sname}xism, 'Display column headings cascade');
$mech->content_like(qr{02/03/1989}xsm, 'Date format helper works');
$mech->content_like(qr{Mike\sSmith}xsm, 'Compound name fields work');

$mech->get_ok('/list/track?myprefixsort=fromalbum.artist.acombined_name-asc');
$mech->content_like(qr{\b13\sentries}xsm, 'Right number of records after 2nd call (i.e. $c updated in FB cache)');
$mech->content_like(qr{David\sBrown.+Adam\sSmith.+Mike\sSmith}xsm, 'Sorting on surname,firstname works');

$mech->get_ok('/listsearch/track');
$mech->content_like(qr{of\s13}xsm, 'Searchboxes template working');

$mech->get_ok('/listsearch/track?myprefixsearch-fromalbum.artist.apn=beta');
$mech->content_like(qr{name="myprefixsearch-fromalbum.artist.apn"[^>]+value="beta"}xsm, 'Textfield filled-in after search');
$mech->content_like(qr{\b10\b.+of\s1}xsm, 'Search works');

$mech->get_ok('/get/track/1');
$mech->content_like(qr{T-Time.+1:30}xsm, 'Infoboxes work');
# TODO  Need to check more than this

$mech->get_ok('/complete/track/fromalbum.artist.id/fromalbum.artist.artist_pseudonym?query=Group');
$mech->content_like(qr{"count":1\D}xsm, 'Autocomplete/JSON works');

$mech->get_ok('/update/track/10?ttitle=My%20track%20title');
$mech->get_ok('/get/track/10');
$mech->content_like(qr{My\strack\stitle}xsm, 'Updating local table works');

# LF only allows updates to fields exposed by infoboxes
$mech->get_ok('/update/track/10?fromalbum.albtitle=My%20album%20title');
$mech->get_ok('/get/album/4');
$mech->content_like(qr{My\salbum\stitle}xsm, 'Updating foreign table works');

# NEED A TEST 8b which updates a foreign, i.e. abc.def.OBJECT
$mech->get_ok('/update/track/11?trackcopyright.OBJECT=3');
$mech->get_ok('/list/track');
$mech->content_like(qr{Label\sC}xsm, 'Updating belongs_to relationship works');


#SKIP: {
#    open $fh, '>test-out-9.html';
#    $out = get('/create/track');
#    print $fh $out;
#    close $fh;
#    like($out, qr{New\strack}xism, '/create works');
#}
