#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file="header.inc" args=""-->

This example serves as how one may use the global.asa 
file event handlers.  Please see the global.asa file
for the code relevant to this example.

<p>

The following table lists the sessions that have been
recorded in the global.asa file into $Application.  When
a session ends, its time lived is recorded and displayed
below.  Active sessions are also listed.  
<p>
<%
my $count;
my @sessions;
for(keys %{$Application}) {
	next unless ($_ =~ /^Session/);
	$count++;
	push(@sessions, $_);
}
%>
<center>
<%=$count%> Sessions Recorded <br>

<!-- 
	Please read the README or the perldoc Apache::ASP before using
	the following routine in your code, as it is non-portable.
-->
<%=$Application->SessionCount()%> Active Sessions
<p>
<% if($count > 200) { %>
<center>  First 200 of <%= $count %> displayed. </center>
<% } %>
<p>
<table border=0 width=90%>
	<tr><td colspan=2><hr size=1></td></tr>
<%
$count = 0;
for(sort @sessions) {
	next unless ($_ =~ /^Session/);
	last if $count++ >= 200;

	my $session_id = $_;
	$session_id =~ s/^Session//io;
	my $session = $Application->GetSession($session_id);
	my $session_data = $session ? { %$session } : undef;

	my $session_time = ($Application->{$_} eq '?') ?
		"in session" : "$Application->{$_} seconds";

	%>
	<tr bgcolor="#c0c0c0">
		<td><%=substr($session_id, 0, 6)."..."%></td>
		<td><%=$session_time%></td>
	</tr>	
	<tr><td colspan=2><pre><%=$session_data ? Data::Dumper->Dump([$session_data]) : '' %></pre></td></tr>

	<tr><td colspan=2><hr size=1></td></tr>
	<%
}
%>
</table>
</center>
<p>
To see multiple sessions listed you may  
create a 2nd session by closing and then reopening
the browser you are using to view this file, or 
you may also open a 2nd kind of browser to create this 2nd
session.  There is only one session-id generated
per browser session for an asp application.

<hr size=1>

Here is a simple use of the Script_OnStart & Script_OnEnd
event handlers, keeping track of the number of scripts
executed this session:

<center>
<table>
<tr>
	<td align=right>Scripts Started This Session:</td>
	<td><tt><%=$Session->{Started}%></tt></td>
</tr>
<tr>
	<td align=right>Scripts Ended This Session:</td>
	<td><tt><%=$Session->{Ended} || 0 %></tt></td>
</tr>
</table>
</center>

<!--#include file="footer.inc"-->
