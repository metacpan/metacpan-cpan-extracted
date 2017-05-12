#!/usr/bin/env perl

use strict;
use warnings;

use LWP::UserAgent;
use Digest::MD5;

#digest computed 2014.04.02
use constant DIGEST => 'f9cca745b0f283ad9dd34cb616866bc2';

#digest computed 2013.11.20
#use constant DIGEST => '0965ae60031c0eec29b4d31e5b626cbc';
#digest computed 2013.09.25
#use constant DIGEST => '9e755db99003c847ec12d1290481de37';
#digest computed 2013.08.07
#use constant DIGEST => 'd841c978faf5d572c40beceafbd3e7e0';
#digest computer 2013.06.27
#use constant DIGEST => 'a11f6023278a998ae40d276afc6a6e03';
#digest computed 2013.02.08
#use constant DIGEST => 'db6da93209efbba920cb6aecc668e0d3';
#digest computed 2012.09.27
#use constant DIGEST => '0cdc9ea7135349d22a8771d9df1d1961';
#digest computed 2012.05.16
#use constant DIGEST => 'cd269f917ee290b3007aee1cb856c2f9';
#digest computed 2012.04.11
#use constant DIGEST => '11d46cee24739c361171f31444428e95';

#https://logiclab.jira.com/wiki/display/BDKPST/Notes
#my $url = 'http://www.postdanmark.dk/da/documents/lister/postnummerfil_excel.xls';
my $url
    = 'http://www.postdanmark.dk/da/Documents/Lister/postnummerfil-excel.xls';

my $ua = LWP::UserAgent->new;

my $response = $ua->get($url);

if ( $response->is_success ) {
    my $content = $response->decoded_content;

    my $ctx = Digest::MD5->new;

    $ctx->add($content);
    my $digest = $ctx->hexdigest;

    if ( $digest ne DIGEST ) {
        die "Calculated digest: $digest differs from known digest: " . DIGEST
            . " - check URL: $url\n";
    } else {
        print "Nothing new under the sun for: $url\n";
    }
} else {
    die $response->status_line;
}

exit 0;
