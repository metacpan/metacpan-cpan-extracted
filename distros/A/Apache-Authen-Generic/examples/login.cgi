#!/usr/bin/perl

# Creation date: 2003-10-05 21:23:01
# Authors: Don
# Change log:
# $Id: login.cgi,v 1.1 2003/10/19 06:57:18 don Exp $

# Copyright (c) 2003 Don Owens

# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { local(*STDERR) = *STDOUT;
                                 print "Content-Type: text/plain\n\n";
                                 &Carp::cluck(); exit 0 };

    use CGI::Utils;
    use Apache::Authen::Generic;
    
    my $cgi = CGI::Utils->new;
    $cgi->parse;
    my $fields = $cgi->vars;

    my $username = $$fields{username};
    my $password = $$fields{password};
    my $ref_url = $$fields{ref_url};

    if ($username eq 'test' and $password eq 'pwd') {
        my $key = q{abcdefghijklmnopqrstuvwxyz012346};
        my $auth = Apache::Authen::Generic->new;
        my $cookie = $auth->generateAuthCookie({ test_var1 => 1, auth_level => 8 },
                                               $key, {}, 'test_cookie');
        if ($ref_url =~ m{^/}) {
            $ref_url = $cgi->getSelfRefHostUrl . $ref_url;
        }
        print "Set-Cookie: $cookie\n";
        print "Location: $ref_url\n\n";
        exit 0;
    } else {
        my $args = { ref_url => $ref_url, msg => 'Password does not match' };
        my $url = '/cgi-bin/login/login_form.cgi';
        $url = $cgi->addParamsToUrl($url, $args);
        print "Location: $url\n\n";
        exit 0;
    }

}

exit 0;

###############################################################################
# Subroutines

