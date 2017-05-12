<%@ Page UseMasterPage="/everything/master.asp" %>

<asp:Content PlaceHolderID="heading">This is the heading!</asp:Content>

<asp:Content PlaceHolderID="content">
  This is the content!
<%
  $Response->SetCookie(
    name  => "mycookie111",
    value => "woot!",
    expires => "30M",
  );
  $Response->SetCookie(
    name  => "mycookie222",
    value => "woot!",
    expires => "30M",
  );
%>
</asp:Content>

