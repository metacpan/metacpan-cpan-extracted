#!/usr/bin/perl -wT

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib";
use CGI::FormMagick;

my $fm = new CGI::FormMagick();
my $uptime;

$fm->debug();
$fm->display();

sub form_pre {
    print qq(<p><b>This is the form pre-event, which runs only when you
    first look at the first page of the form, even before the titles and
    stuff. </b></p>);
}

sub page_pre {
    print qq(<p><b>Welcome to the first page. This is the page
    pre-event printing this message</b></p>);
}

sub page_post {
    print qq(<p><b>This is the page
    post-event for the first page.  It runs after you submit the first
    page.</b></p>);
}

sub showUptime {
    $ENV{PATH} = '/usr/bin';
    my $uptime = `uptime`;
    chomp $uptime;
    return $uptime;
}

sub say_hello {
    print qq(<p>hello!</p><p>This is the form post-event, which runs
    when you successfully submit the last page by hitting "Finish"</p>);
    return 1;
}
