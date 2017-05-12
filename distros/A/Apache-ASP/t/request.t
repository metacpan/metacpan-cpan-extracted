use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self( NoState => 1 );

__END__

<% use lib '.';	use T;	$t =T->new(); %>

<% 
if(%{$Request->ServerVariables()}) {
	$t->ok();
} else {
	$t->not_ok('could not get the environment / server variables');
}

# $Request->{Method}, defaults to GET
$t->eok($Request->{Method} eq 'GET', "\$Request->{Method} eq 'GET'");

%>

<% $t->done; %>
