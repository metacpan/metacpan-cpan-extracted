<?php
require("config.inc.php3");
require("view.inc.php3");



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
    
    while ($column = mysql_fetch_object($result)) { 
      print ("<TR>\n");
      for ( $i = 1; $i <= $columns; $i++) {
	print("<TD>");
	print("<A HREF='$SCRIPT_NAME$column->pathname'><B>$column->name</B></A>");
	if (strstr($column->info,"symlink")) {
	  print(" (@)");
	} else {
	  print(" ($column->count)");
	}
	print("</TD>\n");
	$column = mysql_fetch_object($result);
	if (!$column)
	  break;
      }
      print("</TR>\n");

    }
    print ("</TABLE>\n");
  default:
  }
  mysql_free_result($result);
}

?>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<HTML>
  <HEAD>
    <TITLE>
      _CATEGORY_
    </TITLE>
  </HEAD>
  <BODY 
    bgcolor="#ffffff" 
    alink="#FFFFFF" 
    vlink="#FFFFFF" 
    link="#FFFFFF">
    <CENTER>
      <CENTER>
        <IMG 
	  SRC="/images/grbus.gif" 
	  ALT="grlogo"
	  WIDTH="189"
	  HEIGHT="150"> 
        <HR width="90%" color="007BB7" noshade>
        <TABLE width="90%" border="0" cellpadding="5" summary="search form">
          <TR>
            <TD>
<FORM 
		action="<?php echo $SCRIPT_NAME; ?>" 
		method="POST">
                <INPUT 
		  type="hidden" 
		  name="name" 
		  value="grbusiness"> 
		<INPUT 
		  type="hidden" 
		  name="context"
		  value="csearch"> 
		<INPUT 
		  type="hidden" 
		  name="style"
		  value="urlcatalog"> 
		<INPUT 
		  type="hidden" 
		  name="mode"
		  value="pathcontext"> 
		<INPUT 
		  type="hidden" 
		  name="page_length"
		  value="30"> 
                <CENTER>
                  <INPUT 
		    type="text" 
		    name="text" 
		    value=''> 
		  <INPUT
		    type="submit" 
		    value="search">
		  <SELECT NAME="what">
		    <OPTION SELECTED VALUE="">All</OPTION>
		    <OPTION  VALUE="categories">Categories</OPTION>
		    <OPTION  VALUE="records">Records</OPTION>
		  </SELECT>
                </CENTER>
              </FORM>
            </TD>
<TD ALIGN="RIGHT">
</TD>
          </TR>
        </TABLE>
        <HR width="90%" color="007BB7" noshade>
        <CENTER>
          <TABLE 
	    width="90%" border="0" cols="3" align="CENTER"
	    cellpadding="5" cellspacing="0" summary="listing">
            <TR>
              <TD bgcolor="#000080" align="LEFT" width="48%">
                <B><FONT size="+1">
		    <A href='<?php echo $SCRIPT_NAME; ?>/Entertainment_&amp;_Recreation/'>
		      Entertainment &amp;<WBR> Recreation
		    </A>
		  </FONT></B>
              </TD>
              <TD width="5%">
              </TD>
              <TD bgcolor="#000080" align="LEFT" width="48%">
                <B><FONT size="+1">
		    <A href='<?php echo $SCRIPT_NAME; ?>/Government/'>
		      Government
		    </A>
		  </FONT></B>
              </TD>
            </TR>
            <TR>
              <TD bgcolor="A0A0A4">
                <A href="<?php echo $SCRIPT_NAME; ?>/Entertainment_&_Recreation/Restaurants/">Restaurants,</A>
		<A href="">Movies,</A>
                <A href="">Sports,</A> 
		<A href="">Travel...</A>
              </TD>
              <TD>
              </TD>
              <TD bgcolor="A0A0A4">
                <A href="">Local,</A>
		<A href="">State,</A>
		<A href="">National</A>
              </TD>
            </TR>
            <TR>
              <TD>
                <BR>
              </TD>
            </TR>
            <TR>
              <TD bgcolor="#000080" align="LEFT" nowrap width=
              "48%">
                <B><FONT size="+1">
		    <A href='<?php echo $SCRIPT_NAME; ?>/Manufacturing/'>
		      Manufacturing
		    </A>
		  </FONT></B>
              </TD>
              <TD>
              </TD>
              <TD bgcolor="#000080" align="LEFT" nowrap width=
		"48%">
                <B><FONT size="+1">
		    <A href= '<?php echo $SCRIPT_NAME; ?>/News_&amp;_Media/'>
		      News &amp; Media
		    </A>
		  </FONT></B>
              </TD>
            </TR>
            <TR>
              <TD bgcolor="A0A0A4">
                <A href="">Die molding,</A>
		<A href="">Furniture manufacturing,</A>
		<A href="">Paper mills...</A>
              </TD>
              <TD>
              </TD>
              <TD bgcolor="A0A0A4">
                <A href="">TV,</A>
		<A href="">Newspapers,</A>
		<A href="">Radio,</A>
		<A href="">Magazines...</A>
              </TD>
            </TR>
            <TR>
              <TD>
                <BR>
              </TD>
            </TR>
            <TR>
              <TD bgcolor="#000080" align="LEFT" nowrap width=
              "48%">
                <B><FONT size="+1">
		    <A href='<?php echo $SCRIPT_NAME; ?>/Retail_Business/'>
		      Retail Business
		    </A>
		  </FONT></B>
              </TD>
              <TD>
              </TD>
              <TD bgcolor="#000080" align="LEFT" nowrap width=
              "48%">
                <B><FONT size="+1">
		    <A href='<?php echo $SCRIPT_NAME; ?>/Service_Companies/'>
		      Service Companies
		    </A>
		  </FONT></B>
              </TD>
            </TR>
            <TR>
              <TD bgcolor="A0A0A4">
                <A href="">Shopping,</A>
		<A href="">Stores,</A> 
		<A href="">Shops...</A>
              </TD>
              <TD>
              </TD>
              <TD bgcolor="A0A0A4">
                <A href="">Attorneys,</A>
		<A href="">Automotive repair,</A> 
		<A href="">Banking,</A> 
		<A href="">Insurance...</A>
              </TD>
            </TR>
            <TR>
              <TD>
                <BR>
              </TD>
            </TR>
          </TABLE>
        </CENTER>
      </CENTER>
    </CENTER>
  </BODY>
</HTML>

