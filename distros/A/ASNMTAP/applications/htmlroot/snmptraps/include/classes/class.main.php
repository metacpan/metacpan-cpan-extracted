<?
#########################################################
#         SNMPTraps-Frontend for Nagios & ASNMTAP       #
#                                                       #
#                    by Michael Lübben                  #
#                   --- Lizenz GPL ---                  #
#########################################################

/**
* This Class with funtions
*/
class main {
  
	/**
	* Read the Config-File and return a array
	*
	* @param string $configFile
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
	function readConfig($configFile) {
		$config = @parse_ini_file($configFile, TRUE) or die ("Could not open Configuration-File $configFile !");
		return($config);
	}
	
	/**
	* Replace characters
	*
	* @param string $String
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
    function replaceCharacters($string) {
	   $searchChr = array('ä', 'ü', 'ö', 'Ä', 'Ü', 'Ö', 'ß');
	   $searchChr = array('_a_', '_u_', '_o_', '_A_', '_U_', '_O_', '_sz_');
       $replaceChr = array('&auml;', '&uuml;', '&ouml;', '&Auml;', '&Uuml;', '&Ouml;', '&szlig;');
	   foreach ($searchChr as $key=>$character) {
	     $string = str_replace($searchChr[$key], $replaceChr[$key], $string); 
	   } 
	   return($string); 
	}
    
	/**
	* Read a XML-File and return a array
	*
	* @param string $XMLFile
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
	function readXML($xmlFile) {
       $xml_parser = xml_parser_create();

       if (!($fp = fopen($xmlFile, "r"))) {
          die("Could not open XML-File $xmlFile !");
       }

       $data = fread($fp, filesize($xmlFile));
       fclose($fp);
       xml_parse_into_struct($xml_parser, $data, $vals, $index);
       xml_parser_free($xml_parser);

       $params = array();
       $level = array();
       
       foreach ($vals as $xml_elem) {
          if ($xml_elem['type'] == 'open') {
             if (array_key_exists('attributes',$xml_elem)) {
                list($level[$xml_elem['level']],$extra) = array_values($xml_elem['attributes']);
             } else {
                $level[$xml_elem['level']] = $xml_elem['tag'];
             }
          }
          if ($xml_elem['type'] == 'complete') {
             $start_level = 1;
             $php_stmt = '$params';
             while($start_level < $xml_elem['level']) {
                $php_stmt .= '[$level['.$start_level.']]';
                $start_level++;
             }
             $xml_elem['value'] = $this->replaceCharacters($xml_elem['value']);
             $php_stmt .= '[$xml_elem[\'tag\']] = $xml_elem[\'value\'];';
             eval($php_stmt);
          }
       }
       return($params);
    }
	
	/**
	* Check which table was used
	*
	* @param string $tableName
	* @param string $optionSeverity
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
    function setTable($tableName,$optionSeverity) {
       global $configINI;
	   if(!isset($tableName))
       {
          $table['name'] = $configINI['database']['tableSnmptt'];
       }
       
	   if($optionSeverity == "UNKNOWN") {
          $table['name'] = $configINI['database']['tableSnmpttUnk'];
          $table['severity'] = "all";
       } elseif($optionSeverity == "OK" or $optionSeverity == "WARNING" or $optionSeverity == "CRITICAL") {
          $table['severity'] = $optionSeverity;
       } else {
          $table['severity'] = "all";
       }  
       return($table);
	}
	
	/**
	* Checked logged in User, when authentification was enabled
	*
	* @param string $useAuthenfication
	* @param string $loggedInUser
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
	function checkUser() {
	   global $configINI;
	   $userAllowed = "0";
	   if ($configINI['global']['useAuthentification'] == "0") {
	      $userAllowed = "1";  
	   } else {
	      $authorized = explode(",",$configINI['global']['allowedUser']);
		  if (in_array($_SERVER['PHP_AUTH_USER'],$authorized)) {
             $userAllowed ="1";
          }   	  
	   }
	   return($userAllowed);
	}
	
	/**
	* Checked logged in User, when authentification was enabled
	*
	* @param string $useAuthenfication
	* @param string $allowedAction
	*
	* @author Alex Peeters [alex.peeters@citap.be]
    */
	function checkAction() {
	   global $configINI;
	   $actionAllowed = "0";
	   if ($configINI['global']['useAuthentification'] == "0") {
	      $actionAllowed = "1";  
	   } else {
	      $authorized = explode(",",$configINI['global']['allowedAction']);
		  if (in_array($_SERVER['PHP_AUTH_USER'],$authorized)) {
             $actionAllowed ="1";
          }   	  
	   }
	   return($actionAllowed);
	}
}
?>
