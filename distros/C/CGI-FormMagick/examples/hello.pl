#!/usr/bin/perl -wT 

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib";
use CGI::FormMagick;

my $fm = new CGI::FormMagick();

$fm->display();

sub say_hello {
    my $cgi  = shift;
    my $name = $cgi->param('name');
    print qq(
        <h2>Hello, $name</h2>
        <p>It is moderately nice to meet you.</p>
    );
    return 1;
}

