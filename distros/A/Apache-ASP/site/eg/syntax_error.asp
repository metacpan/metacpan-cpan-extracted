#!/usr/bin/perl /usr/bin/asp-perl

<% 
use File::Basename;
if($Request->QueryString('buffer')) {
	$Response->{Buffer} = 1;
} else {
	$Response->{Buffer} = 0; 
}
%>
<!--#include file=header.inc-->
We are creating a perl syntax error... this should demonstrate 
how error handling is done.  Please check the error log file if 
you are interested in the output there.
<p>
You can turn this error messaging off by setting the Debug variable
in the ASP config to 1 or 0.
<p>
Also here is an example of how you can use debugging, an API
extension $Response->Debug(@args), in your script.  The debug 
output will show up below, and in your error logs.  This user 
style debugging is turned off with the same Debug setting set to 0.
<p>
=pod
This pod comment will be yanked upon compilation
=cut
<% 
   $Response->Debug(
	"Debugging", 
	['can', 'take'], 
	{'just'=>'about'},
	sub { ['any', 'kind']},
	\"of reference",
	"or scalar"
	);

   print "Try this script also with <a href=".basename($0)."?buffer=1>buffering on.</a>";
%>

<p>

This script by default does a runtime syntax error.  If you would like
to see a script <b>compile error, <a href="<%= basename($0) %>?compile_error=1">click here</a></b>.

<p>
<a href="source.asp?file=<%=$Request->ServerVariables("SCRIPT_NAME")%>">
view this file's source
</a>

<br>
<br>

<% 
if($Request->QueryString('compile_error')) {
  $Response->Include("compile_error.inc");
} else {
        my $Object;
	# create a run-time syntax error
	$Object->SyntaxError(); 
}
%>












Misc Text Below Error


