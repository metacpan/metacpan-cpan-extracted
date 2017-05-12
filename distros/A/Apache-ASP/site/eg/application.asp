#!/usr/bin/perl /usr/bin/asp-perl

<!--#include file=header.inc-->
<% 
	# Locking
	# --------
	# reads and writes to $Application as well as $Session are
	# always locked to ensure concurrency, but if you want to 
	# make sure that you have the only access during
	# some block of commands, then use the Lock() and UnLock()
	# functions

	$Application->Lock();
	$Application->{Count}+=1;
	$Application->UnLock();

%>
We just incremented the $Application->{Count} variable by 1.
Here is the value of the $Application->{Count} variable... <br>
<b><%= sprintf("%06d", $Application->{Count}) %></b>
<p>
We reset this value to 20 every Application_OnStart.  Check
out the global.asa!

<!--#include file=footer.inc-->
