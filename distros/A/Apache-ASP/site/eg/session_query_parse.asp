#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file=header.inc-->
<% $Response->{Expires} = -100; %>
Here we are going to demo another cookieless session
implementation.  Unlike the one at 
<a href=session.asp>session.asp</a>, you as the developer
do NOT need to tag specific URLs with $Server->URL().
<p>
Instead what happens is that Apache::ASP will automatically
parse through the script output looking for all local 
URLs, and those URLs matching the SessionQueryParseMatch
config, currently set to <tt><%=$Server->Config('SessionQueryParseMatch')%></tt> ...
These URLs will then have the current $Session->SessionID 
inserted into their query strings.
<p>
So turn off the cookies and see what happens!  You 
should notice that all local URLs, including
the link to <a href=<%= $demo->{file} %>>itself</a>,
now have the session id carried by the query strings.
<p>
<table>
<tr>
<td>The current session id is:</td><td> <tt><%=$Session->SessionID%></tt> </td>
<tr>
<td>The current count is:</td> <td><%=++$Session->{Count}%></td>
</table>

<p>
Here are some other links that may or may not have
the session id parsed in depending whether they match 
SessionQueryParseMatch:

<ul>
<li><a href="http://localhost.blah.blah.localhost/">Link to localhost</a>
<li><a href="http://anotherhost.blah.blah.anotherhost/">Link to anotherhost</a>
</ul>

<!--#include file=footer.inc-->

