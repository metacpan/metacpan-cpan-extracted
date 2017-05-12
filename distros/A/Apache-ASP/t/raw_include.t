
use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(Global => 'null', NoState => 1, Debug => 0);

__END__

<% $Response->Include('raw_include.inc'); %>
