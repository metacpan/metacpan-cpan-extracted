<?
//var_dump($_POST);
//var_dump($_GET);
// Disable error-message
error_reporting(E_ALL ^ E_NOTICE);

require("./include/classes/class.main.php");
require("./include/classes/class.frontend.php");
require("./include/classes/class.common.php");
require("./include/classes/class.mysqlDB.php");

$MAIN = new main();

// Read config.ini.php
$configINI = $MAIN->readConfig("./etc/config.ini.php");

// Read error.xml for error-messages
$errorXML = $MAIN->readXML("./include/xml/language/".$configINI['global']['language']."/error.xml");

// Read language 
$languageXML = $MAIN->readXML("./include/xml/language/".$configINI['global']['language']."/main.xml");

// Set table
$table = $MAIN->setTable($tableName,$_REQUEST['severity']);

$FRONTEND = new frontend($configINI);

$FRONTEND->openSite();

$FRONTEND->constructorHeader();

if ($MAIN->checkUser() == "0") {
   $FRONTEND->printError("AUTHENTIFICATION",NULL);
} else {
   if ($MAIN->checkAction() == "1") {
      // If set action, then mark or delete a trap in the database
      if($_GET['action'] == "mark" or $_GET['action'] == "delete") {
          $DATABASE = new database($configINI);
      	  $DATABASE->connect();
      	  $DATABASE->handleTrap($_GET['action'],$_GET['trapID'],$table['name']); 
      }
      // Mark more as one trap 
      if($_POST["markTraps"] AND $_POST["trapIDs"]){
         foreach($_POST["trapIDs"] as $trapID){
            $DATABASE = new database($configINI);
	        $DATABASE->connect();
   	        $DATABASE->handleTrap("mark",$trapID,$table['name']); 
         }
      }
      // Delete more as one trap 
      if($_POST["deleteTraps"] AND $_POST["trapIDs"]){
         foreach($_POST["trapIDs"] as $trapID){
            $DATABASE = new database($configINI);
      	    $DATABASE->connect();
            $DATABASE->handleTrap("delete",$trapID,$table['name']);
         }
      }
   }
   $FRONTEND->constructorMain();
   $FRONTEND->constructorFooter();
}
$FRONTEND->closeSite();
$FRONTEND->printSite();
?>