<?php
include("header.php3");

$sql = "select letter, count from catalog_alpha_$name";
$resultid = mysql_query($sql, $connectid);
$column = mysql_fetch_object($resultid);

$i = 1;
$char = "0";

print("<TABLE border='0' ALIGN='CENTER' CELLPADDING='4'>");
while ($column) {
  print("<TR>\n");
  for ($cols = 1; $cols <= 12; $cols++) {
    print("<TD>"); 
    if ($column->count == 0) {
      print("<IMG ");
      print("SRC='/images/letters/letter" 
	    . $column->letter 
	    . "0.gif'");
    } else {
      print("<A href='$SCRIPT_NAME?name=$name&letter=$column->letter'>");
      print("<IMG SRC='/images/letters/letter$column->letter.gif'");
    }
    
    print("border='0'></A>");
    print("<FONT size='-1'>");
    print(" ($column->count)</FONT>");
      
    print("</TD>\n");
    
    $column = mysql_fetch_object($resultid);
  }
  print("</TR>\n");
}

print("</TABLE>");
?>

</BODY>
</HTML>

