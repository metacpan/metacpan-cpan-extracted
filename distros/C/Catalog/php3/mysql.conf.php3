<?php
//
// MySQL client configuration file
//
// Name of the database to connect. Mandatory.
//

$base = "Catalog";

//
// Host name. Comment if using localhost.
//
  
$host = 
//
// Port number. Comment if using default.
//
$port = "";
//
// File name of the socket for local communications. Comment if
// using a remote host or if mysql does not support non-TCP/IP 
// communications on local host.
//
$unix_port = "";
//
// User name. Comment if authentification is off.
//
$user = "root";
//
// Password. Comment if authentification is off.
//
$passwd = "";
//
// Command line translation of mysql parameters
//
$cmd_opt =  "--user='root' --password=''";
//
// Uncomment to trigger special handling of the created field.
// If active, field whose name is 'created' will be filled with the 
// current date during insert.
// 
$auto_created = "yes";
?>
