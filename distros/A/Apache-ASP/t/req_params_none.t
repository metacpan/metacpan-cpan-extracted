use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self( NoState => 1);

__END__

<% use lib '.';	use T;	$t =T->new(); %>
<% 
eval { my $Params = $Request->Params(); };
$t->eok($@ && ( $@ =~ /Request.*Params does not exist/i ), "Error message for NULL \$Request->Params");
%>
<% $t->done; %>
