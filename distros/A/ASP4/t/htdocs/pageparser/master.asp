<%@ MasterPage %>
<html>
<asp:ContentPlaceHolder id="init"><% $Response->Expires( -5 ); %></asp:ContentPlaceHolder>
<head>
<title><asp:ContentPlaceHolder id="meta_title"></asp:ContentPlaceHolder></title>
<meta name="keywords" value="<asp:ContentPlaceHolder id="meta_keywords"></asp:ContentPlaceHolder>" />
<meta name="description" value="<asp:ContentPlaceHolder id="meta_description"></asp:ContentPlaceHolder>" />
</head>
<body>
<p>Before Outer</p>
<asp:ContentPlaceHolder id="outer">
  <p>Inside Outer</p>
  
  <p>Before Inner 1</p>
  <asp:ContentPlaceHolder id="inner1"> <p>Inner 1</p>
    
    <p>Before Inner 2</p>
    <asp:ContentPlaceHolder id="inner2">
      <p>Inner 2</p>
    </asp:ContentPlaceHolder>
    <p>After Inner 2</p>
    
  </asp:ContentPlaceHolder>
  <p>After Inner 1</p>
  
</asp:ContentPlaceHolder>
<p><font color="white" style="background-color: green; border: solid 1px black;">After Outer^^^</font></p>
</body> 
</html>

