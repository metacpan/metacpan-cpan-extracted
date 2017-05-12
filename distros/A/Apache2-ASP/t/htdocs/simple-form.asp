<html>
<head>
  <title>Color Selection Form</title>
</head>
<body>
<%
  if( $Form->{color} )
  {
%>
<p>
  Your color is "<%= $Server->HTMLEncode($Form->{color}) %>"
</p>
<%
  }# end if()
%>
<form action="/simple-form.asp" method="get">
  <input type="text" name="color">
  <input type="submit" value="Submit">
</form>

</body>
</html>
