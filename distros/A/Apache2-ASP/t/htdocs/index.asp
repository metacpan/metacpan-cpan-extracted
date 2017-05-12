<%@ OutputCache Duration="60" VaryByParam="someparam" VaryBySession="user_id" %>
<%@ Page UseMasterPage="/masters/main.asp" %>

<asp:Content PlaceHolderID="ph_title" id="content2" runat="server">This is the title</asp:Content>

<asp:Content PlaceHolderID="placeholder1" id="content1" runat="server">
  Page content inside of content1:
  <%= "Hello, World!\n"x2 %>
<%
  for( 1...100_000 )
  {
    my $ABC = 123;
#    $Response->Write("I am a little teapot<br>\n");
  }
%>

Files ~ /hello


<%
  if( 1 ) {
%>
  Include: <% $Response->Include( $Server->MapPath("/inc.asp"), { somevar => "val1", anothervar => "val2" } ); %>
  VirtualInclude: <!-- #include virtual="/inc.asp" -->
  TrapInclude: <%= join ", ", reverse split /:/, $Response->TrapInclude( $Server->MapPath("/inc.asp"), { trap_arg => time() } ) %>
<%
  }# end if()
%>
</asp:Content>

