<html>
<body>
<%
  if( my $file = $Request->FileUpload("filename") )
  {
    my $tmp = '/tmp/' . rand();
    $file->SaveAs( $tmp );
    unlink($tmp);
%>
<form name="form1">
<%= $file->FileName %> -- <%= $file->FileExtension %> -- <%= $file->FileSize %><br/>
<textarea name="file_contents"><%= $file->FileContents %></textarea>
</form>
<%
  }
  else
  {
%>
<form name="form1" action="/useragent/upload-form.asp" method="post" enctype="multipart/form-data">
  <input type="file" name="filename">
  <br>
  <input type="submit" value="Submit" >
</form>
<%
  }# end if()
%>
</body>
</html>
