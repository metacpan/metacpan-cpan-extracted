use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(
	XMLSubsMatch => '(aaa|bbb):(?:[a-z]|[0-9])+',
	NoState => 1,
	UseStrict => 1,
	BufferingOn => 0,
#	Debug => -3,
);

__END__

<%
sub aaa::a2z { $t->ok };
sub bbb::a2z { $t->ok };
%>
<aaa:a2z />
<bbb:a2z />
<aaa:a2z a="b">asdfdsaf</aaa:a2z>
<bbb:a2z a="b"/>

