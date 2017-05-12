#!/usr/bin/perl

use CGI;
use CGI::Session::AUS;

my $cgi = new CGI;
my $session = CGI::Session::AUS->new;
my $user = $session->user;

print $cgi->header("text/plain");

print "Admin test page.\n";

if($user) {
    print "User $user->{name}.\n";
    if($user->{flags}{administrator}) {
        print "Administrator flag.\n";
    }
    if($user->{permissions}{administrator}) {
        print "Administrator permission.\n";
    }
} else {
    print "No user.\n";
}
