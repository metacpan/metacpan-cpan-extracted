use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self();

__END__
<%@ LANGUAGE="PerlScript" %>
<% 
for(@Apache::ASP::Objects) {
	if(${$_}) {
		$t->ok;
	} else {
		$t->not_ok("object $_ not defined in ASP namespace");
	}
}
%>	

