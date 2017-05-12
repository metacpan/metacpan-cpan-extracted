<%@ Page UseMasterPage="/masters/global.asp" %>

<asp:Content PlaceHolderID="init"><%
  $Response->Status( 404 );
  return $Response->End;
%></asp:Content>

<asp:Content PlaceHolderID="page_body"><%
  die "Should not get here.";
%></asp:Content>

