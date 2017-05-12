<%
# process user login
my $error;
my $user = $Form->{'user'};
if(defined $user) {
	$user =~ /^\w+$/ or $error = 
		"Your username must made of only letter and numbers";
	length($user) > 3 or $error = 
		"Your username much be at least 4 character long";
	
	unless($error) {
		$Session->{user} = $user;
		$Response->Redirect('bookmarks.asp');
	}
}
$user ||= $Session->{user};
%>
Hello, and welcome to the MyBookmarks Apache::ASP demo application.
To begin your bookmark experience, please login now:

<center>
<% if($error) { %>
	<p><b><font color=red size=-1>* <%=$error%></font></b>
<% } %>
<form src=<%=$Basename%> method=POST>
<input type=text name=user value="<%=$Server->HTMLEncode($user)%>">
<input type=submit value=Login>
</form>
</center>

This demo makes use of the Apache::ASP objects, especially
<tt>$Session</tt> and <tt>$Response</tt>, modularizes html 
via SSI file includes, and uses the <tt>Script_OnStart</tt>
and  <tt>Script_OnEnd</tt> event hooks to 
simplify common tasks done for each script in this web
application.
