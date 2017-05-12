#!/usr/bin/perl -w

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib/";
use vars qw($fm);
use CGI::FormMagick;

$fm = new CGI::FormMagick();

$fm->debug(1);
$fm->display();

sub fix_buttons {
    my $cgi = shift;
    use Data::Dumper;
    print "<pre>\n";
    print Dumper $cgi;
    print "</pre>\n";
    if ($cgi->param('previousbutton')) {
        $main::fm->previousbutton(1);
        print "<p>Turned previous button on</p>";
    } else {
        $main::fm->previousbutton(0); 
        print "<p>Turned previous button off</p>";
    }

    if ($cgi->param('nextbutton')) {
        $main::fm->nextbutton(1) ;
        print "<p>Turned next button on</p>";
    } else {
        $main::fm->nextbutton(0) ;
        print "<p>Turned next button off</p>";
    }

    if ($cgi->param('resetbutton')) {
        $main::fm->resetbutton(1) ;
        print "<p>Turned reset button on</p>";
    } else {
        $main::fm->resetbutton(0) ;
        print "<p>Turned reset button off</p>";
    }

    if ($cgi->param('startoverlink')) {
        $main::fm->startoverlink(1) ;
        print "<p>Turned start over link on</p>";
    } else {
        $main::fm->startoverlink(0) ;
        print "<p>Turned start over link off</p>";
    }

    # go to same page again
    $cgi->param(-name => "wherenext", -value => "buttons");

    return 1;
}

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

