<?php


// Catalog.pm configuration file
//
//
// HTML code that separates two component of the path
//
//path_separator = &nbsp;/&nbsp;
$path_separator = "/";

//
// Label for the root of the hierarchy tree
//
$path_root_label = "<b>GRBusiness.com</b>";


//
// When cgi-bin is invoked with path_info instead of regular arguments,
// pretend that these parameters were used. It must at least contain
// the name of the catalog (name=<name>) and may also contain a style, for instance.

// The id and path parameters are automaticaly calculated from the path_info.
//
// Perl Style pathcontext_params = "name=grbusiness&style=grbusiness";
if (!$name)
	$name = "grbusiness";
if (!$style)
	$style = "";


//
// Encoding of the catalog data (default is ISO-8859-1)
//
//$encoding = "ISO-8859-1";



//Other defaults
if (!$page_length)
	$page_length = 100;


?>
