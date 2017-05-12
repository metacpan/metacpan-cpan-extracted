use Apache::ASP::CGI;

&Apache::ASP::CGI::do_self(
			   GlobalPackage => "Test", 
#			   UniquePackages => 1, 
			   UseStrict => 0, 
			   Debug => 3,
			   NoState => 1,
			   NoCache => 1,
			   );

__END__
<% 
$Response->Include(\"\n<\% \$var = 1; %\>\n");
$t->eok($var, "unique namespace script and include");
$t->eok($Test::var, "unique namespace script and include");

$test_value = 0;
&include_test(1);
&include_test(2);
&include_test(3);
$test_value = 0;
&include_test(1);

sub include_test {
    my($value) = shift;
    $main::Server->{asp}->CompileInclude('no_cache.inc');
    $Test::t->eok($test_value == $value, "value load check");
}

%>


