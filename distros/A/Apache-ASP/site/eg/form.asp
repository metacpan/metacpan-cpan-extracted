#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file=header.inc-->

<table>
<form method=POST>
<tr>
	<td>Your Name:</td>
	<td><input name=name type=text size=30 
		value="<%=$Request->Form('name')%>" >
	</td>
	<td><input type=submit value="Submit Name"></td>
</tr>
</table>

<% if($Request->Form('name')) { %>
	Your name is <tt><%=$Request->Form('name')%></tt>
<% } %>

<hr size=1>

The following are the contents of the data returned
from doing a binary read of the form data:
<p>
<tt>
<%=$Request->BinaryRead($Request->{TotalBytes})%>
</tt>

<!--#include file=footer.inc-->
