use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(
#	Debug => 1
#	StateDir => '/tmp/asp_test',
	SessionSerialize => 1,
);

__END__

<% 
  $Response->Include('session.inc');
%>


