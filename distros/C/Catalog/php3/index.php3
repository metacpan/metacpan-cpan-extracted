<?php
  
include("mysql.conf.php3");
include("catalog.conf.php3");


if ($connectid = mysql_pconnect($host . $port, $user, $passwd))   {
  mysql_select_db($base, $connectid);
  
  switch ($context) {
  case "csearch":
    include("csearch.php3");
    break;

  case "cbrowse":
  default:
    $sql = "select tablename, navigation from catalog where name = '$name'";
    $resultid = mysql_query($sql, $connectid);
    $column = mysql_fetch_object($resultid);
    $catalogname = $column->tablename;
    $navigation = $column->navigation;
    mysql_free_result($resultid);
    
    switch ($navigation) {
    case "theme":
      
      //If path info supplied, use it to set the id
      if ($PATH_INFO) { 
	
	$md5path = md5($PATH_INFO);
	$sql = "select *  from catalog_path_$catalogname where md5 = '$md5path'";
	$resultid = mysql_query($sql, $connectid);
	if ($resultid) {
	  $column = mysql_fetch_object($resultid);
	  $pathname = $column->pathname;
	  $path = $column->path;
	  $id = $column->id;
	  mysql_free_result($resultid);
	} 
      } elseif ($id) { //No path info, check for id#
	$sql = "select *  from catalog_path_$catalogname where id = '$id'";
	$resultid = mysql_query($sql, $connectid);
	if ($resultid) {
	  $column = mysql_fetch_object($resultid);
	  $pathname = $column->pathname;
	  $path = $column->path;
	  mysql_free_result($resultid);
	}
	
	
      } else { //No path info or ID#: Show index.html
	include("index.html");
	exit();
      }
      
      //Display the page for the current id
      if ($pathname == "/") {
	include("cbrowse_root.php3");
      } else {
	
	include("cbrowse.php3");
      }
      
      break;
    case "alpha":
      if ($letter) {
	include("calpha.php3");
      } else {
	include("calpha_root.php3");
      }
      break;
    default:
    }
  }    
} else { 
  die("Could not connect to the database");    
}

//phpinfo();


?>
