#!/usr/bin/perl -wT

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib/";
use CGI::FormMagick;

my $fm = new CGI::FormMagick();

$fm->display();

sub post {
    my $cgi  = shift;
    my $colour = $cgi->param('colour');
    my $os     = $cgi->param('os');
    print qq(
        <h2>Results</h2>
        <p>Colour is $colour</p>
        <p>OS is $os</p>
    );
    return 1;
}

