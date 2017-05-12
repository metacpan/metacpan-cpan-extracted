#!/usr/bin/perl -wT

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib/";
use CGI::FormMagick;

my $fm = new CGI::FormMagick( DEBUG => 1);

$fm->display();

sub say_hello {
    my $cgi     = shift;
    my $name    = $cgi->param('name');
    my $howmany = $cgi->param('howmany');
    print "<h2>Hello, $name</h2>\n" x $howmany;
    return 1;
}

