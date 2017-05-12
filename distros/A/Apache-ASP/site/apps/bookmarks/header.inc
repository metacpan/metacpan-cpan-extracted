<html>
<head><title><%=$Title%></title></head>
<body bgcolor=white link=purple alink=yellow vlink=gray>

<form src=<%=$Basename%> method=POST>
<table border=0 width=100% cellpadding=5 cellspacing=0>
<tr bgcolor=<%= $DarkColor %>>
	<td>
	<b><font <%=$FontBase%> size=+1 color=yellow>
		<%=$Title%>
		<% if($Session->{user}) { %>
		  for <%= $Session->{user} %>
		<% } %>
	</font></b>
	</td>
	<td align=right>
	<font <%=$FontBase%>>
	<% if($Session->{'user'}) { %>
		<input type=submit name=logout value=Logout>
	<% } else { %>
		&nbsp;
	<% } %>
	</font>
	</td>
</tr>
</form>
</table>

<table border=0 cellpadding=5 width=100% ><tr><td valign=top>
<font <%=$FontBase%> size=+0>

