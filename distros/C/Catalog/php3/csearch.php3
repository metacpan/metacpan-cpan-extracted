<?php
include("header.php3");


$catalogname = $name;

function search_categories () {

  global $text, $catalogname, $base, $SCRIPT_NAME;
  
  $searchpieces = explode (" ", $text);
  
  $i = 1;
  while ( list( $key, $val ) = each( $searchpieces ) ) {
    if ($val != " ") {
      $searchstr[] =  "name like \"%$val%\"";
    }
  }
  
  $searchstring = implode($searchstr, " AND ");
  
  
  //  $sql = "select pathname from catalog_path_$catalogname where $searchstring 
  //order by pathname";
  $sql = "select pathname 
from catalog_path_$catalogname as a
left join catalog_category_$catalogname as b
on a.id = b.rowid
where $searchstring 
order by pathname";

  $result = mysql_db_query($base, $sql);
  $row = mysql_fetch_row($result);
  if ($row) {
      print("<CENTER><FONT SIZE='+1'>");
      print("Categories matching <B>$text</B>: (");
      print(mysql_num_rows($result));
      print(")</CENTER></FONT><BR>");
      while($row) {
	print("<FONT SIZE='+1'>");
	print("<A HREF='$SCRIPT_NAME$row[0]'>");
	print("$row[0]</A><BR>\n");
	print("</FONT>");
	$row = mysql_fetch_row($result);
      }
  } else {
    print("<BR><BR><CENTER><B>No matching categories</B></CENTER><BR>");
  }
  mysql_free_result($result);
} //end function search_categories()

function search_records () {

  global $text, $catalogname, $base, $SCRIPT_NAME;
  
  $searchpieces = explode (" ", $text);
  
  $i = 1;
  while ( list( $key, $val ) = each( $searchpieces ) ) {
    if ($val != " ") {
      $searchstr[] =  "CompanyName like \"%$val%\"";
    }
  }
  
  $searchstring = implode($searchstr, " AND ");
  
  
  $sql = "select a.CompanyName, a.CompanyURL, a.Address, c.pathname 
from $catalogname as 
a left join catalog_entry2category_$catalogname as b on a.rowid = b.row
left join catalog_path_$catalogname as c on b.category = c.id where 
$searchstring 
order by c.pathname, a.CompanyName";

  $result = mysql_db_query($base, $sql);
  $row = mysql_fetch_row($result);
  if ($row) {
    print("<CENTER><FONT SIZE='+1'>");
    print("Records matching <B>$text</B>: (");
    print(mysql_num_rows($result));
    print(")</FONT></CENTER><BR>");
    print("<TABLE BORDER='0' CELLPADDING='3'>\n");
    while($row) {
      $category = $row[3];
      print("<TR>\n");
      print("<TD COLSPAN='3'>\n");
      print("<A HREF='$SCRIPT_NAME$row[3]'>");
      print("<FONT SIZE='+1'>\n");
      print("<B>$row[3]</B></A>\n");
      print("</FONT>\n");
      print("</TD>\n");
      print("</TR>\n");
      while ($category == $row[3]) {
	print("<TR>\n");
	print("<TD WIDTH='40'>\n");
	print("</TD>\n");
	print("<TD>\n");
	print("<A HREF='$row[1]'>");
	print("$row[0]");
	print("</A>\n");
	print("</TD>\n");
	print("<TD>\n");
	print("$row[2]");
	print("</TD>\n");
	print("</TR>\n");
	$row = mysql_fetch_row($result);
      }
    }
    print("</TABLE>");
  } else {
    print("<BR><BR><CENTER><B>No matching records</B></CENTER><BR><BR>");
  }
  mysql_free_result($result);
} //end function search_records()



switch ($what) {

 case "categories":
   search_categories();
   break;

 case "records":
   search_records();
   break;

 case "":
 default:
   search_categories();
   print("<BR><HR width='90%' color='007BB7' noshade><BR>");
   search_records();
}

?>

</BODY>
</html>
