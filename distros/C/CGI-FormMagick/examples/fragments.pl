#!/usr/bin/perl -w

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib/";
use CGI::FormMagick;
use Data::Dumper;

my $fm = new CGI::FormMagick();

#print Dumper $fm->{xml};

$fm->display();

sub say_hello {
    my $cgi     = shift;
    my $name    = $cgi->param('name');
    my $howmany = $cgi->param('howmany');
    print "<h2>Hello, $name</h2>\n" x $howmany;
    return 1;
}

sub subroutine {
    return qq(
    <p>
    <font color="009900">This is another fragment, this time from a
    subroutine.</font>
    </p>
    );
}



