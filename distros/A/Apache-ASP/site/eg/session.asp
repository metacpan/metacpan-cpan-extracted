#!/usr/bin/perl /usr/bin/asp-perl

<%
    my $form = $Request->Form();

# process form here
if($form->{increment}) {
    $Session->{Count}++;
} elsif($form->{timeout}) {
    $Session->Timeout(.25);
} elsif($form->{abandon}) {
    $Session->Abandon();
}

my @rows = (
	 '$Session->{Count}',
	 '$Session->{Timeout}',
	 '$Session->{SessionID}'
	 );
%>
<!--#include file=header.inc-->

This file demonstrates the use of the $Session object, as well
as one implementantion of cookieless sessions involving the 
use of the SessionQuery setting, and the <nobr>$Server->URL($url, \%params)</nobr>
method to add session ids to the form query string.
<p>
To demo the cookieless sessions, just turn off your cookies
and use this form.
<p>
<center>
<table border=1>
<tr><td colspan=2 align=center><b>Session Object Demonstration</b></td></tr>
<form action=<%=$Server->URL($demo->{file})%> method=POST>
<tr>
	<td colspan=2 align=center>
	<input type=submit name=increment value="Increment Count">
	<input type=submit name=timeout   value="Timeout 15 Seconds">
	<input type=submit name=abandon   value="Abandon">
	<td>
</tr>
</form>
<% for (@rows){ %>
	<tr>
		<td><tt><%=$Server->HTMLEncode($_)%></tt></td>		 
		<td><%=eval($_) || $@%></td>
	</tr>
<% } %>
</table>
</center>
<p>
The value for $Session->{Count} gets reset to 10 on every session start
in the global.asa file.

<!--#include file=footer.inc-->


