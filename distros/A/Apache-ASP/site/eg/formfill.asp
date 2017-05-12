#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file=header.inc-->

<%
  $Response->{FormFill} = 1;
%>

<table width=80%><tr><td>

This page makes use of the <b>FormFill</b> feature which
populates a HTML form from $Request->Form data.  The FormFill
functionality is provided by the HTML::FillInForm module,
which in turn relies on HTML::Parser.
<p>
It is enabled with:
  <pre>
  at runtime: $Response->{FormFill} = 1

    -- or --

  in config:  PerlSetVar FormFill 1
  </pre>

At HTML::FillInForm v.07, select boxes must have 
their option values defined explicitly to be auto filled
by the form fill feature, such as:
<pre>
<b><%=$Server->HTMLEncode('<option value="Value">')%></b>
</pre>

<table border=1 cellpadding=5>
<form method=POST>
  <tr><td align=center colspan=2><b>Example Form</b></td></tr>
  <tr>
	<td>Your Name:</td>
	<td><input name=name type=text size=30 value="Your Name"></td>
  </tr>
  <tr>
     <td>Your Favorite Color:</td>
     <td>
         <select name=color>
         <% for my $color (sort('Red', 'Blue', 'Green', 'Yellow')) { %>
 	   <option value="<%=$color%>"><%= $color %></option>
	 <% } %>
         </select>
     </td>
  </tr>
  <tr><td colspan=2><input type=submit value="Submit Info"></td></tr>
</form>
</table>

<% if(%{$Request->{Form}}) { %>

<hr size=1>

  Your name is <tt><%=$Request->Form('name')%></tt> <br>
  Your favorite color is <tt><%= $Request->{Form}{color} %> </tt>
<% } %>

<hr size=1>

The following are the contents of the data returned
from doing a binary read of the form data:
<p>
<tt>
<%=$Request->BinaryRead($Request->{TotalBytes})%>
</tt>

</td></tr></table>

<!--#include file=footer.inc-->
