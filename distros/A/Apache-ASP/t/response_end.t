use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(NoState => 1);

__END__
<% 
  $t->ok;
  $Response->End;
  $t->not_ok;
%>


