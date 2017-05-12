<%
# only a logged in user may view the bookmarks
$Session->{'user'} || $Response->Redirect('index.asp');

my $error;
if($Form->{submit} =~ /create/i) {
	unless($Form->{new_url}) {
		$error = "The Url must be ".
			"filled in to create a new bookmark";
		goto ERROR;
	}

	my $sth = $Db->prepare_cached(
		"select url from bookmarks where username=? and url=?"
		);
	$sth->execute($Session->{'user'}, $Form->{new_url});
	if($sth->fetchrow_array) {
		$error = "You already have $Form->{new_url} ".
			"for a bookmark";
		goto ERROR;
	} else {
		$sth = $Db->prepare_cached(<<SQL);
insert into bookmarks (bookmark_id, username, url, title)
values (?,?,?,?)
SQL
	;
		$Application->Lock();
		$sth->execute(
			++$Application->{max_bookmark_id}, 
			$Session->{'user'}, 
			$Form->{new_url}, 
			$Form->{new_title}
			);
		$Application->UnLock();
	}
}

if($Query->{delete}) {
	my $sth = $Db->prepare_cached(<<SQL);

select * from bookmarks 
where bookmark_id = ?
and username = ?

SQL
	;
	$sth->execute($Query->{delete}, $Session->{user});
	if(my $data = $sth->fetchrow_hashref) {
		my $sth = $Db->prepare_cached(<<SQL);

delete from bookmarks 
where bookmark_id = ? 
and username = ?

SQL
	;
		$sth->execute($Query->{delete}, $Session->{user});
		$Form->{new_url} = $data->{'url'};
		$Form->{new_title} = $data->{'title'};
	}
}

# get all the bookmarks
ERROR:
my $sth = $Db->prepare_cached(
			"select * from bookmarks where username=? ".
			"order by bookmark_id"
			);
$sth->execute($Session->{'user'});
my @bookmarks;
while(my $bookmark = $sth->fetchrow_hashref()) {
	push(@bookmarks, $bookmark);
}
%>

<% if(@bookmarks) { %>
	Welcome to your bookmarks!
<% } else { %>
	You don't have any bookmarks.  Please feel free to 
	add some using the below form.
<% } %>

<center>
<% if($error) { %>
	<p><b><font color=red size=-1>* <%=$error%></font></b>
<% } %>
<form src=<%=$Basename%> method=POST>
<table border=0>
	<% for ('new_url', 'new_title') { 
		my $name = $_;
		my $title = join(' ', 
			map { ucfirst $_ } split(/_/, $name));
		%>
		<tr>
		<td><b><%=$title%>:</b></td>
		<td><input type=text name=<%=$name%> 
			value="<%=$Form->{$name}%>" 
			size=40 maxlength=120>
		</td>
		</tr>
	<% } %>
	<tr>
	<td>&nbsp;</td>
	<td>
		<font <%=$FontBase%>>
		<input type=submit name=submit 
			value="Create Bookmark"></td></tr>
		</font>
	</td>
</form>
</table>

<% if(@bookmarks) { 
	my $half_index = int((@bookmarks+1)/2);
	%>
	<p>
	<table border=0 width=80% bgcolor=<%= $DarkColor %> cellspacing=0>
	<tr><td align=center>

	<table border=0 width=100% cellspacing=1 cellpadding=3>
	<tr bgcolor=<%= $DarkColor %>><td align=center colspan=4>
		<font color=yellow><b>Bookmarks</b></font>
	</td></tr>
	<% for(my $i=0; $i<$half_index; $i++) { %>
		<tr>
		<% for($i, $i+$half_index) { 
			my $data = ($_ < @bookmarks) ? 
				$bookmarks[$_] : undef;
			$data->{title} ||= $data->{'url'};
			my $text = $data->{bookmark_id} ? 
				"<a href=$data->{'url'}
					>$data->{'title'}</a>" 
					: "&nbsp;";
			%> 
			<td bgcolor=#c0c0c0 width=30 align=center>
			<% if($data->{bookmark_id}) { %>
				<font size=-1><tt>
				<a href=<%=
				"$Basename?delete=$data->{bookmark_id}"
				%>>[DEL]</a>
				</tt></font>
			<% } else { %>
			  &nbsp;
			<% } %>
			</td>
			<td bgcolor=white><%= $text || '&nbsp;'%></td> 
		<% } %>
		</tr>
	<% } %>
	</table>	
	
	</td></tr></table>
	<br>
<% } %>

</center>
