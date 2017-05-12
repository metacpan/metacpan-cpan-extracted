#!/usr/bin/perl -w

#####################################################################
# example1.cgi - Sample/Test program for CGI::Carp::Throw
# Demonstrates basic functionality of CGI::Carp::Throw module.
#####################################################################

use strict;
use lib 'lib', 'CGI-Carp-Throw/lib'; # IIS funiness

use CGI qw/:standard/;
use CGI::Carp::Throw qw/:carp_browser/;

print header, start_html(-title => 'Throw test'),
    p('expecting parameter: "need_this".');

if (my $need_this = param('need_this')) {
    if ($need_this =~ /^[\s\w.]+$/ and -e $need_this) {
        print h1('Thank you for providing parameter "need_this"'), end_html;
    }
    else {
        croak 'Invalid or non-existent file name: ', $need_this;
    }
}
else {
    throw_browser '***  Please provide parameter: need_this!  ***';
}


