use Apache::ASP::CGI;

&Apache::ASP::CGI::do_self(
			   GlobalPackage => "Test", 
			   UniquePackages => 1, 
			   UseStrict => 0, 
			   Debug => 3,
			   NoState => 1,
			   );

__END__
<% 
$Test::t->eok(! $t, "\$t defined in this namespace");

$Response->Include(\"\n<\% \$var = 1; %\>\n");
$Test::t->eok(!$var, "unique namespace script and include");
$Test::t->eok($Test::var, "unique namespace script and include");

my @compile_keys = keys %Apache::ASP::CompiledIncludes;
$Test::t->eok(grep(/Test::.+::/, @compile_keys) == 1);
$Test::t->eok(grep(/Test::/, @compile_keys) == 1);

$Response->Include("unique_packages.inc");
@compile_keys = keys %Apache::ASP::CompiledIncludes;
$Test::t->eok(grep(/Test::.+::/, @compile_keys) == 1);
$Test::t->eok(grep(/Test::/, @compile_keys) == 2);

# run test again to make sure caching worked
$Response->Include("unique_packages.inc");
@compile_keys = keys %Apache::ASP::CompiledIncludes;
$Test::t->eok(grep(/Test::.+::/, @compile_keys) == 1);
$Test::t->eok(grep(/Test::/, @compile_keys) == 2);
%>

