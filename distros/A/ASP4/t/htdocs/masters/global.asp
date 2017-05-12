<%@ MasterPage %><asp:ContentPlaceHolder id="init"></asp:ContentPlaceHolder><html>
  <head>
    <title>
      <asp:ContentPlaceHolder id="meta_title">Default Title</asp:ContentPlaceHolder>
    </title>
    <meta name="keywords" content="<asp:ContentPlaceHolder id="meta_keywords"></asp:ContentPlaceHolder>" />
    <meta name="description" content="<asp:ContentPlaceHolder id="meta_description"></asp:ContentPlaceHolder>" />
  </head>
  <body>
    <h1>
      <asp:ContentPlaceHolder id="page_heading">HELLO</asp:ContentPlaceHolder>
    </h1>
    <p>
      <asp:ContentPlaceHolder id="page_body">Content coming soon!</asp:ContentPlaceHolder>
    </p>
  </body>
</html>

