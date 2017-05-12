# $Id: Header.pm,v 1.9 2003/09/29 21:20:13 clajac Exp $

package CPANXR::Apache::Header;
use strict;

my $header = q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
  <title>CPAN Cross Reference (ALPHA)</title>
  <link rel="stylesheet" type="text/css" href="/css/perl.css" title="Default CSS2" media="screen">
</head>
<body>

<table cellspacing="0" width="730">
<tr>
<td width="100%" colspan="2" class="BANNER">CPAN Cross Reference (ALPHA)</td>
</tr>

<tr>
<td width="100%" colspan="2"  id="NAV" style="border-bottom: 1px solid #191970;">
 <a href="/">Home</a> |
 <a href="/cpanxr/">Browse</a> |
 <a href="/search.html">Search</a> |
 <a href="/cpanxr/classes">Class browser</a> |
 <a href="/about.html">About</a> |
 <a href="/cpanxr/stats">Statistics</a>
</td>
</tr>

</table>

<div id="MAIN">
};

sub header {
  my ($self, $r) = @_;

  $r->print($header);
}

1;
