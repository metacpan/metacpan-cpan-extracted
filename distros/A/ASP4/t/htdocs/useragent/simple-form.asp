<html>
<body>
<form name="form1" action="/useragent/simple-form.asp" method="post">
  Color: <input type="text" name="color" value="<%= $Server->HTMLEncode( $Form->{color} ) %>" ><br>
  Pet's Name: <input type="text" name="pet_name" value="<%= $Server->HTMLEncode( $Form->{pet_name} ) %>"><br>
  <br>
  <input type="submit" value="Submit" >
</form>
</body>
</html>
