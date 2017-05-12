<?php

function print_url_path() {
  global $connectid;
  global $path, $catalogname, $base;
  global $SCRIPT_NAME, $path_root_label, $path_separator;
  
  //Start tree path links
  $item = explode(",",$path);
  
  while ( list( $key, $val ) = each( $item ) ) {
    if ($val != "")
      $sqlpathtemp[] = $val;
  }
  
  $sqlpath = implode($sqlpathtemp, ",");
  $sql = "select b.pathname, a.name  from catalog_category_$catalogname as a
 left join catalog_path_$catalogname as b on a.rowid = b.id where a.rowid in($sqlpath)";

  $result = mysql_query($sql, $connectid);
  if ($result) {
    print("<A HREF='$SCRIPT_NAME/'>$path_root_label</A>");
    print("$path_separator\n");
    $column = mysql_fetch_object($result);
    while($column) {
      print("<A HREF='$SCRIPT_NAME$column->pathname'>$column->name</A>");
      print("$path_separator\n");
      $column = mysql_fetch_object($result);
    }
  }
  mysql_free_result($result);
}


function print_categories( $style = 'table', $columns = 1) {
  global $connectid;
  global $path, $catalogname, $base, $id;  
  global $SCRIPT_NAME, $path_root_label, $path_separator;
  $sql = "select c.pathname, b.name, b.count, a.info  from 
catalog_category2category_$catalogname as a
left join catalog_category_$catalogname as b
on a.down = b.rowid 
left join catalog_path_$catalogname as c 
on a.down = c.id 
where a.up = $id order by b.name";

  $result = mysql_query($sql, $connectid);  
  $column = mysql_fetch_object($result);
  switch ($style) {
  case "table":
    print("<TABLE WIDTH='70%' BORDER='0'>\n");
    
    while ($column) {
      print ("<TR>\n");

      for ($i = 1; $i <= $columns; $i++) {
	if (!$column)
	  break;

	print("<TD>");
	print("<A HREF='$SCRIPT_NAME$column->pathname'><B>$column->name</B></A>");
	if (strstr($column->info,"symlink")) {
	  print(" (@)");
	} else {
	  print(" ($column->count)");
	}
	print("</TD>\n");
	
	$column = mysql_fetch_object($result);
      }
      print("</TR>\n");
    }
    print ("</TABLE>\n");
  default:
  }
  mysql_free_result($result);
}

?>

<?php include("header.php3");?>

<H2>
<?php print_url_path(); ?>
</H2>
</TABLE>
<BR><BR>

<?php print_categories("table", 2);?>

<BR>
<CENTER>
<HR width="90%" color="007BB7" noshade>
</CENTER>
<BR>


<?php
$sql = "select * from $catalogname as a left join 
catalog_entry2category_$catalogname as b on a.rowid = b.row
where b.category = $id order by CompanyName";

$result = mysql_query($sql, $connectid);

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
?>
