#!/usr/bin/perl -wT 

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib";
use CGI::FormMagick;
use Data::Dumper;

my $fm = new CGI::FormMagick();

$fm->display();
$fm->finishbutton(0);

sub wibble {
    my ($fm, $data) = @_;
    return "OK" if $data eq "wibble";
    return "NOT_WIBBLE";
}
