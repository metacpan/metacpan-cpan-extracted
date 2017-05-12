#!/usr/bin/perl /usr/bin/asp-perl

<my:include src='header.inc' title="XMLSubsMatch Demo"/>

This is a demonstration of the XMLSubsMatch extension which
allows for the developer to construct a set of custom XML style
tags for use in ASP scripts.  These tags could be used 
to render entire XML documents, or even simply give some nice
short cuts for use when site building.
<p>

<% if($Server->Config('XMLSubsStrict')) { %>
  Further, the <b>XMLSubsStrict</b> setting has been set.
  <p>
<% } %>

Currently, XMLSubsMatch is set to:
<my:ttb> 
  <% $Response->Write('['); %>
  <%=$Server->Config('XMLSubsMatch')%> 
  <% $Response->Write(']'); %>
</my:ttb>

<p>
Whatever tags XMLSubsMatch matches of the form
<pre><%=
$Server->HTMLEncode('
 <matchtag param1="value1" param2="value2">
   text
 </matchtag>
  -- or --
 <matchtag param1="value1" param2="value2"/>
')%></pre>

will be parsed into perl subroutines of matchtag name with
arguments and text passed in, so these subs would be called
respectively for the above XMLMatchSubs:

<pre><%=$Server->HTMLEncode('
&matchtag( { param1 =>"value1", param2=>"value2" }, \'text\' );
  -- and --
&matchtag( { param1 =>"value1", param2=>"value2" }, \'\');
')
%></pre>

Note that XMLSubs tags of the form <my:ttb>foo:bar</my:ttb> will be changed into a
call to <my:ttb>&foo::bar()</my:ttb>, so that the XML concept of tag prefix
namespaces is translated to the concept of perl packages.
<p>

<my:table width="400" title="Title Box" border='3' bgcolor=red>
  <h3>XML Subs Demo</h3>
  The bgcolor=red param should have been skipped because it was
  not surrounded with quotes like bgcolor="red" or bgcolor='red'
</my:table>
<p>
<my:table width="400" title="Title Box" border='3' 
	  bgcolor = 'red' >
  The color='red' param is OK here as it had the correct syntax.  
</my:table>

<p>
The my::* perl subs defining the XMLSubs are located in the 
global.asa.
<p>

<my:include src="footer.inc"/>

