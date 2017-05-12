#!/usr/bin/perl

use strict;
use constant MP2 => ($mod_perl::VERSION >= 1.99);

my $r = MP2 ? Apache2::RequestUtil->request
            : Apache->request;

# Setting the status to 200 here causes the default apache 403 page to be
# appended to the custom error document.  We understand but the user may not
# $r->status(200);
my $uri = $r->prev->uri;

my $creds = $r->prev->pnotes("WhatEverCreds");

# if there are args, append that to the uri
my $args = $r->prev->args;
if ($args) {
    $uri .= "?$args";
}

my $reason = $r->prev->subprocess_env("AuthCookieReason");

my $form = <<HERE;
<HTML>
<HEAD>
<TITLE>Enter Login and Password</TITLE>
</HEAD>
<BODY onLoad="document.forms[0].credential_0.focus();">
HERE

# output creds in a comment so the test case can see them.
if (defined $creds) {
    $form .= "<!-- creds: @{$creds} -->\n";
}

$form .= <<HERE;
<FORM METHOD="POST" ACTION="/LOGIN">
<TABLE WIDTH=60% ALIGN=CENTER VALIGN=CENTER>
<TR><TD ALIGN=CENTER>
<H1>This is a secure document</H1>
</TD></TR>
<TR><TD ALIGN=LEFT>
<P>Failure reason: '$reason'.  Please enter your login and password to authenticate.</P>
</TD>
<TR><TD>
<INPUT TYPE=hidden NAME=destination VALUE="$uri">

</TD></TR>
<TR><TD>
<TABLE ALIGN=CENTER>
<TR>
<TD ALIGN=RIGHT><B>Login:</B></TD>
<TD><INPUT TYPE="text" NAME="credential_0" SIZE=10 MAXLENGTH=10></TD>
</TR>
<TR>
<TD ALIGN=RIGHT><B>Password:</B></TD>
<TD><INPUT TYPE="password" NAME="credential_1" SIZE=8 MAXLENGTH=8></TD>
</TR>
<TR>
<TD COLSPAN=2 ALIGN=CENTER><INPUT TYPE="submit" VALUE="Continue"></TD>
</TR></TABLE>
</TD></TR></TABLE>
</FORM>
</BODY>
</HTML>
HERE

$r->no_cache(1);
my $x = length($form);
$r->content_type("text/html");
$r->headers_out->set("Content-length","$x");
$r->headers_out->set("Pragma", "no-cache");
unless (MP2) {
    $r->send_http_header;
}

$r->print ($form);
