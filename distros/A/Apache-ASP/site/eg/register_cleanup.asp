#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file=header.inc-->

<% my $Sleep = 3; %>
We are about to sleep for <%=$Sleep %> seconds.  Before that, 
this script registers a routine to be executed after this script 
finishes, which will increment a count.  This count displayed after 
these <%=$Sleep %> seconds if you do nothing.
<p>
Try this.  Hit reload, then your browser <b>STOP</b> button quickly.  
Do this repeatedly.  Then let the script execute normally.  You will 
see the registered code executed appropriately.  
<p>
Up through Apache version 1.3.4, this method is important, because mod_perl 
halts script execution immediately when the user hits a STOP button, 
so doing $Server-&gt;RegisterCleanup is the only way to consistently
execute code that you have to for that script.
<p>
sleeping for <%=$Sleep %> seconds...
<p>
<%	
$Response->Flush();
$Server->RegisterCleanup( sub { $main::Session->{cleanup_count}++ }); 
for(1..$Sleep) {
    print 'sleeping 1 second...<br>';
    $Response->Flush();
    if(! $Response->{IsClientConnected}) {
	$Response->Debug("ending script execution since client is no longer connected");
	$Response->End;
    }
    sleep(1);
}
%>
<p>
Count incremented in $Server-<%=$Server->HTMLEncode('>')%>RegisterCleanup 
<b><%=$Session->{cleanup_count} || 0 %></b>

<!--#include file=footer.inc-->

