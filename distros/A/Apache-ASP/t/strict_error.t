use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(UseStrict => 1, NoState => 0, Debug => 3);

__END__

<%
eval { $Response->Include('strict_error.inc') };
my $error = $@;
$t->eok($error, "no strict error");
$t->eok($error =~ /MyStrictError/ ? 1 : 0, "wrong strict error, should match MyStrictError");
%>
