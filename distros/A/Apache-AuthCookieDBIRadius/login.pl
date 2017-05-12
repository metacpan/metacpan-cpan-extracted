#!/usr/bin/perl

use strict;
my $r = Apache->request;

$r->status(200);
my $uri = $r->prev->uri;
my $reason = $r->prev->subprocess_env("AuthCookieReason");

# added args so we can redirect correctly.
my $args = $r->prev->args;
$uri = "$uri?$args" if $args;

my $form;

$form = <<HERE;
<HTML>
<HEAD>
<TITLE>Enter Login and Password</TITLE>
</HEAD>
<BODY bgcolor=909A6E link=blue vlink=blue alink=blue onLoad="document.forms[0].credential_0.focus();">
<center>
<BR><BR><BR>
<FORM METHOD="POST" ACTION="/LOGIN">
<TABLE ALIGN=CENTER VALIGN=CENTER>
<TR><TD colspan=2 align=center>
<font color=red>$reason</font>
</TD></TR>
<INPUT TYPE=hidden NAME=destination VALUE="$uri">
<TR><TD colspan=2 align=center>

<!--login-->
<table>
<TR><TD align=right>
<B>Login:</B></TD>
<TD><INPUT TYPE="text" NAME="credential_0" SIZE=20 MAXLENGTH=50></TD>
</TR>
<TR>
<TD ALIGN=RIGHT><B>Password:</B></TD>
<TD><INPUT TYPE="password" NAME="credential_1" SIZE=20 MAXLENGTH=20></TD>
</TR>
</table>
<!--end login-->

</TD></TR>
<TR>
<TD COLSPAN=2 ALIGN=CENTER><INPUT TYPE="submit" VALUE="Continue"></TD>
</TR>
</TABLE>
</FORM>
<P>
<a href=>I need to request a new login</a>
<P>
<a href=>I forgot my password</a>
<P>
<a href=>I'm having problems with my existing login</a>
</body>
</html>
HERE

$r->no_cache(1);
my $x = length($form);
$r->content_type("text/html");
$r->header_out("Content-length","$x");
$r->header_out("Pragma", "no-cache");
$r->send_http_header;

$r->print ($form);