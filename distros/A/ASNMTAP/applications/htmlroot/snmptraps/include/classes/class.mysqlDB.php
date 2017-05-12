<?
#########################################################
#         SNMPTraps-Frontend for Nagios & ASNMTAP       #
#                                                       #
#                    by Michael Lübben                  #
#                   --- Lizenz GPL ---                  #
#########################################################

/**
* This Class handles database-connection and - queries
*/
class database {
  
   
  
   /**
	* Constructor
	*
	* @param config $configINI
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/  
    function database(&$configINI) {
		$this->configINI = &$configINI;
	}
	
	/**
	* Make a connection to the database
	*
	* @param array $configINI
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/  
	function connect() {
       global $configINI, $FRONTEND;
       $connect = @mysql_pconnect($configINI['database']['host'], $configINI['database']['user'], $configINI['database']['password']);
       $dbSelect['code'] = @mysql_select_db($configINI['database']['name'], $connect);
       // On error, create a array entry with the mysql error
       if(!$dbSelect['code']) {
          $FRONTEND->printError("DBCONNECTION",mysql_error());
		  $FRONTEND->closeSite();
          $FRONTEND->printSite();
          exit;
       }
       return($dbSelect);
    }
    
    /**
	* Read Traps from database
	*
	* @param string $sort
	* @param boolean $limit
	* @param array $table
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/  
    function readTraps($limit) {
       global $table, $FRONTEND;
  	   /**
	   * @author Alex Peeters [alex.peeters@citap.be]
       */
       // Create WHERE clausel
       if($_REQUEST['severity'] == "" and $_REQUEST['hostname'] == "" and $_REQUEST['trapOID'] == "" and $_REQUEST['category'] == "") {
          $dbQuery = '';
       } elseif ($_REQUEST['severity'] == "UNKNOWN" and $_REQUEST['hostname'] == "" and $_REQUEST['trapOID'] == "") {
          $dbQuery = '';
       } else {
          if($_REQUEST['severity'] != "UNKNOWN") {
 	         if ($_REQUEST['severity'] != "") {
                if ($_REQUEST['severity'] == "OK") {
  	               $dbQuerySet[] = "(severity = 'Normal' or severity = 'INFORMATIONAL')";
                }elseif ($_REQUEST['severity'] == "WARNING") {
  	               $dbQuerySet[] = "(severity = 'MINOR' or severity = 'WARNING')";
                }elseif ($_REQUEST['severity'] == "CRITICAL") {
  	               $dbQuerySet[] = "(severity = 'CRITICAL' or severity = 'MAJOR' or severity = 'SEVERE')";
                }
	         }
   	         if ($_REQUEST['category'] != "") {
	            $dbQuerySet[] = "category = '".rawurldecode($_REQUEST['category'])."'"; 
	         }
          }
	      if ($_REQUEST['hostname'] != "") {
            $a = 0;
            $hostnames = split ( '\,', $_REQUEST['hostname'] );
            foreach ( $hostnames as $hostname ) {
              if ($_REQUEST['FQDN'] == "T") {
	            $hostnames[$a++] = "hostname = '$hostname'"; 
              } else {
	            $hostnames[$a++] = "hostname like '$hostname.%'";
   	          }
            }
            $dbQuerySet[] = '('. join (' or ', $hostnames ) .')';
	      }
	      if ($_REQUEST['trapOID'] != "") {
             $teller = 0;
             $trapOIDsString = split ('\|', $_REQUEST['trapOID']);
             foreach ($trapOIDsString as $value) { $trapOIDsString[$teller++] = "trapOID = '$value'"; }
			 
             if ( count($trapOIDsString) ) { 
  	           $dbQuerySet[] = '( '. implode ( ' or ', $trapOIDsString ) .' )';
             }
	      }
	      $dbQuery = "WHERE ".implode($dbQuerySet," AND ");
	   }
	   // Set which trap must reed first from database
	   if ($_REQUEST['oldestfirst'] == "on") {
          $sort = "ASC";
       } else {
          $sort = "DESC";
       } 
       if ($limit == "0"){
         // Count traps from database
         $query = "SELECT count(*) FROM ".$table['name']." ".$dbQuery;
       } else {
         // Read traps from database
         $query = "SELECT * FROM ".$table['name']." ".$dbQuery." ORDER BY id ".$sort." LIMIT ".$limit;
       }
       $result = @mysql_query($query);
       // On error, create a array entry with the mysql error
       if(!$result) {
          $FRONTEND->printError("DBTABLE",mysql_error());
		  $FRONTEND->closeSite();
          $FRONTEND->printSite(); 
          exit; 
       }
   
       if ($limit == "0"){
         $traps = @mysql_fetch_array($result);
       } else {
         while ($line = @mysql_fetch_array($result)) {      
           $traps[] = $line;
         }
       }
       return($traps);
	}
	
	/**
	* Handle a Traps in the database
	*
	* @param boolean $trapID
	* @param string $tableName
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/  
	function handleTrap($handle,$trapID,$tableName) {
	   global $configINI, $FRONTEND;
	   if($handle == "mark") {
          $query = "UPDATE $tableName SET trapread = 1 WHERE id = $trapID";
       }elseif($handle == "delete") {
          if($configINI['database']['tableArchiveExt'] != "") {
             if($configINI['database']['tableSnmpttUnk'] == $tableName) {
               $query = "REPLACE INTO $tableName". $configINI['database']['tableArchiveExt'] ." SELECT * FROM $tableName WHERE id = $trapID";
             }else{
               $query = "REPLACE INTO $tableName". $configINI['database']['tableArchiveExt'] ." SELECT * FROM $tableName WHERE id = $trapID and category <> 'ASNMTAP'";
             }
             $result = mysql_query($query);
             if(!$result) {
                $FRONTEND->printError("DBTABLE",mysql_error());
        		$FRONTEND->closeSite();
                $FRONTEND->printSite(); 
                exit; 
             }
          }
          $query = "DELETE FROM $tableName WHERE id = $trapID";
       } 
       $result = mysql_query($query);
       if(!$result) {
          $FRONTEND->printError("DBHANDLETRAP",mysql_error());
		  $FRONTEND->closeSite();
          $FRONTEND->printSite(); 
          exit; 
       }
       return($result);
    }
    
    /**
	* Read Trap-Infromation from the database
	*
	* @param string $tableName
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/  
    function infoTrap($tableName) {
       global $FRONTEND;
       $query = "SELECT id,traptime FROM $tableName ORDER BY id";
       $result = mysql_query($query);
       if(!$result) {
          $FRONTEND->printError("DBREADTRAP",mysql_error());
		  $FRONTEND->closeSite();
          $FRONTEND->printSite(); 
          exit; 
       }
       while ($line = mysql_fetch_array($result)) {
          $trapTime[] = $line['traptime']; 
       }
       if ($trapTime[0] != "") {
   	      $trap[last] = array_pop($trapTime);
   	      $trap[first] = array_pop(array_reverse($trapTime));
       }
       return($trap);
    }

	/**
	* Read category from database
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*
	*/
	function readCategory($tableName) {
	   global $FRONTEND;
	   $query = "SELECT DISTINCT category FROM $tableName";
	   $result = mysql_query($query);
	   if(!$result) {
          $FRONTEND->printError("DBREADCATEGORY",mysql_error());
		  $FRONTEND->closeSite();
          $FRONTEND->printSite(); 
          exit; 
       }

	   while ($line = mysql_fetch_array($result)) {
	      $category[] = $line['category'];
	   }
	   return($category);
	} 

}
