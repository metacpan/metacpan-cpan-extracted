use Apache::ASP::CGI;
use strict;

&Apache::ASP::CGI::do_self(NoState => 1);

__END__
<% 
eval { $Response->TrapInclude('.'); };
$t->eok($@, "should be error");

eval { $Response->TrapInclude('include.inc'); };
$t->eok(! $@, "should not be error");

%>	

