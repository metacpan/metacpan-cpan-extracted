#!/usr/bin/perl -w

# Creation date: 2003-08-13 22:38:08
# Authors: Don
# Change log:
# $Id: 03cookies.t,v 1.2 2003/09/21 17:40:02 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };


    use Test;
    BEGIN { plan tests => 1 }

    use CGI::Utils;

    $ENV{HTTP_COOKIE} = 'cook1=val1;cook2=val2; cook3=val3';
    my $utils = CGI::Utils->new;
    my $cookies = $utils->getParsedCookies;

    ok(&test_parsed_cookies($cookies));
}

exit 0;

###############################################################################
# Subroutines

sub test_parsed_cookies {
    my ($cookies) = @_;
    my @keys = keys %$cookies;
    return undef unless scalar(@keys) == 3;

    return undef unless $$cookies{cook1} eq 'val1' and $$cookies{cook2} eq 'val2'
        and $$cookies{cook3} eq 'val3';


    return 1;
}
