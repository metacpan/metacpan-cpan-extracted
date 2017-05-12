

<% 
use vars qw ($Ads $PageCount);
if($Ads && ( $0 !~ /index.html$/ )) { # turn off for now
	$PageCount++;
	%>

=pod

		<!--- Begin HitExchange Code --->
               <CENTER><TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0><TR><TD>
               <TABLE BORDER=0 BGCOLOR="#0000FF" CELLPADDING=1 CELLSPACING=0>
               <TR><TD><A HREF="http://gif.hitexchange.net/HX589936/468x60/<%=$PageCount%>" TARGET="_top">
               <IMG SRC="http://gif.hitexchange.net/HX589936/468x60/<%=$PageCount%>.gif" BORDER=0
                 HSPACE=0 WIDTH=468 HEIGHT=60 ALT="Banner Ad"></A></TD>
               </TR></TABLE></TD></TR><TR><TD ALIGN=CENTER>
               <A HREF="http://gif.hitexchange.net/HX589936/468x15/map" TARGET="_top">
               <IMG SRC="http://gif.hitexchange.net/logo/468x15.gif" BORDER=0 
                 HSPACE=0 ISMAP WIDTH=468 HEIGHT=15 ALT="Click!"></A></TD>
               </TR></TABLE></CENTER>
               <!--- End HitExchange Code --->

	<!-- BEGIN LINKEXCHANGE CODE --> 
	<center><iframe src="http://leader.linkexchange.com/<%=$PageCount%>/X709880/showiframe?" 
	width=468 height=60 marginwidth=0 marginheight=0 hspace=0 vspace=0 frameborder=0 scrolling=no>
	<a href="http://leader.linkexchange.com/<%=$PageCount%>/X709880/clickle" target="_top"><img width=468 
	height=60 border=0 ismap alt="" 
	src="http://leader.linkexchange.com/<%=$PageCount%>/X709880/showle?"></a></iframe>
	<br><a href="http://leader.linkexchange.com/<%=$PageCount%>/X709880/clicklogo" 
	target="_top"><img src="http://leader.linkexchange.com/<%=$PageCount%>/X709880/showlogo?" 
	width=468 height=16 border=0 ismap alt=""></a><br></center>
	<!-- END LINKEXCHANGE CODE -->
=cut

<% } %>

