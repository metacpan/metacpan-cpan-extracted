<%@ MasterPage %>
<%@ Page UseMasterPage="/masters/global.asp" %>

<asp:Content PlaceHolderID="meta_title">Submaster Title</asp:Content>

<asp:Content PlaceHolderID="meta_keywords">submaster keywords</asp:Content>

<asp:Content PlaceHolderID="meta_description">submaster description</asp:Content>

<asp:Content PlaceHolderID="page_heading">The Submaster Page</asp:Content>

<asp:Content PlaceHolderID="page_body">
  The first part.<br/>
  <asp:ContentPlaceHolder id="sub_section">aaa</asp:ContentPlaceHolder>
  The final part.
</asp:Content>

