#!/usr/bin/perl -w

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::kSession;
use CGI::Cookie;

    my $cgi = new CGI;
    my $last_sid = $cgi->param("SID");
    my $c = new CGI::Cookie(-name=>'SID',-value=>$last_sid);
    my ($id, $key, $value);

    my $s = new CGI::kSession(path=>"/tmp/");

    print $cgi->header(-cookie=>$c);

    print $cgi->start_html();

    if ($last_sid) {
        # note: the following I used for mozilla - your mileage may vary
        my $cookie_sid = (split/[=;]/, (fetch CGI::Cookie)->{SID})[1];

        if ($cookie_sid) {
            print "<b>We are now reading from the cookie:</b><p>";
            $id = $s->id($cookie_sid);
            $s->start($cookie_sid);
            print "The cookie's id: $cookie_sid<br>";
            print "Here's the test_value: ".$s->get("test_key")."<br>";
        } else {
            print "<b>We are now reading from the URL parameters:</b><p>";
            $id = $s->id($last_sid);
            $s->start($last_sid);
            print "Last page's id: $last_sid<br>";
            print "Here's the test_value: ".$s->get("test_key")."<br>";
        }
    } else {
        print "<b>Here we will set the session values:</b><p>";
        $s->start();
        $id = $s->id();
        print "My session id: $id<br>";
        $s->register("test_key");
        $s->set("test_key", "Oh, what a wonderful test_value this is...");
        print "Here's the test_value: ".$s->get("test_key")."<br>";
    }

    # note: the first click will set the session id from the URL the
    #           second click will retrieve a value from the cookie

print "<a href=".(split/\//,$0)[-1]."?SID=$id>Next page</a>";
print $cgi->end_html();
