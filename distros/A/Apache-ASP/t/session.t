use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(
#	Debug => 1,
#	StateDir => '/tmp/asp_test',
);

__END__

<% 
  $Response->Include('session.inc');
%>


