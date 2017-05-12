#!/usr/bin/perl

# Creation date: 2003-10-05 20:02:42
# Authors: Don
# Change log:
# $Id: login_form.cgi,v 1.1 2003/10/19 06:57:18 don Exp $

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
    my $cgi = CGI::Utils->new;
    $cgi->parse;
    
    my $fields = $cgi->Vars;
    
    print "Content-Type: text/html\n\n";
    print "<pre>\n";
    print "Login form.<br />\n";
    print "</pre>\n";
    my $msg = $$fields{msg};
    if (defined($msg)) {
        print qq{<p><font color="#ff0000">$msg</font></p>};
    }

    my $ref_dir = $cgi->getSelfRefUrlDir;
    my $form = qq{<form action="$ref_dir/login.cgi" method="POST">\n};
    $form .= qq{<input type="hidden" name="ref_url" value="$$fields{ref_url}" />\n};
    $form .= qq{<input type="text" name="username" /><br />\n};
    $form .= qq{<input type="password" name="password" /><br />\n};
    $form .= qq{<input type="submit" name="submit" value="Submit" />\n};
    $form .= qq{</form>\n};
    
    print $form;
}

exit 0;

###############################################################################
# Subroutines

