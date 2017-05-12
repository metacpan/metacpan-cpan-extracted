<?php
include("header.php3");

$sql = "select * from $catalogname where CompanyName like '$letter%' order by CompanyName ";

$result = mysql_query($sql, $connectid);

$rowcount = mysql_num_rows($result);

if ($page_length < $rowcount) {
  $pages = ceil($rowcount / $page_length);

  if ($page) {
    $offset = ($page -1) * $page_length;
    $sql = $sql."limit $offset, $page_length";
    mysql_free_result($result);
    $result = mysql_query($sql, $connectid);    

  } else {
    $sql = $sql."limit $page_length";
    mysql_free_result($result);
    $result = mysql_query($sql, $connectid);    
    $page = 1;
  }
}
$columns = 2;

print("<TABLE WIDTH='100%' BORDER='0'>\n");

$row = mysql_fetch_object($result);
while($row) {
  for ( $i = 1; $i <= $columns; $i++) {
    if (!$row)
      break;
    print("<TD>");
    print("<A HREF='");
    print($row->CompanyURL);
    print("'>");
    print($row->CompanyName);
    print("</A>");
    print("</TD>\n");
    print("<TD>\n");
    print($row->Address);
    print("\n</TD>\n");
    $row = mysql_fetch_object($result);
  }
  print("</TR>\n");
}

print ("</TABLE>\n");
mysql_free_result($result);

if ($pages > 1) {
  print("<BR><BR><CENTER><B>\n");
  print ("Number of pages: $pages<BR><BR>\n");
  for($i = 1; $i <= $pages; $i++) {
    if ($page == $i) {
      print("$i ");
    } else {
      print("<A HREF='$SCRIPT_NAME?name=$name&letter=$letter&page=$i&page_length=$page_length'>");
      print("$i</A> \n");
    }
  }
  print("</B>");
}

?>

</BODY>
</html>
