#!/usr/bin/perl /usr/bin/asp-perl

<my:include src='header.inc' title="XMLSubsMatch Demo"/>

This is a demonstration of the XMLSubsMatch extension which
allows for the developer to construct a set of custom XML style
tags for use in ASP scripts.  These tags could be used 
to render entire XML documents, or even simply give some nice
short cuts for use when site building.
<p>

=pod
  This part just to demo embedding normal ASP constructs
  in the XMLsubs, which was no easy trick to implement!
=cut

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
&matchtag( { param1 => "value1", param2=>"value2" }, \'text\' );
  -- and --
&matchtag( { param1 => "value1", param2=>"value2" }, \'\');
')
%></pre>

Note that XMLSubs tags of the form <my:ttb>foo:bar</my:ttb> will be changed into a
call to <my:ttb>&foo::bar()</my:ttb>, so that the XML concept of tag prefix
namespaces is translated to the concept of perl packages.
<p>

<my:table width=200 title="Title Box" border=3>
  <h3>XML Subs Demo</h3>

  Another table here to demo embedded XMLSubs tags:
  <my:table border=1>
    Double Table to Show Embedded Tags
  </my:table>

  <p>

  And another embedded:
  <my:table border=1>
    Another table.
      <my:table border=1>
        Triply embedded XMLSubs <my:ttb>my:table</my:ttb> table.
      </my:table>  
  </my:table>  

</my:table>
<p>

<% for("yellow", "red", "blue") { %>
	<my:table bgcolor=$_ width=200 title=ucfirst($_)."Box" border=5>
		Colored Box
	</my:table>
	<p>
<% } %>

<p>
The my::* perl subs defining the XMLSubs are located in the 
global.asa.
<p>

<my:include src="footer.inc"/>
