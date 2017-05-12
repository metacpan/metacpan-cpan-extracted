#!/usr/bin/perl
#

use strict;
use CGI;
use CGI::Cookie;

my $q = new CGI;

#my $retrieve_cookie = $q->cookie('CookieName');
my $retrieve_cookie = undef;

if ($retrieve_cookie) {
    print $q->header;
    print $q->start_html;
    use Data::Dumper;
    print Dumper($retrieve_cookie);
}
else {

    # Create a new cookie
    my $cookie = new CGI::Cookie(
        -name    => 'CookieName2dd1',
        -value   => 'CookieValue',
        -expires => '+1d'
    );

    # set the Cookie
    print $q->header(-cookie => $cookie);
    print $q->start_html;
}

print $q->end_html;
exit;
