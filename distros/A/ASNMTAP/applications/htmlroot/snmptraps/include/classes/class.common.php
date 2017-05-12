<?
#########################################################
#         SNMPTraps-Frontend for Nagios & ASNMTAP       #
#                                                       #
#                    by Michael Lübben                  #
#                   --- Lizenz GPL ---                  #
#########################################################

/**
* This Class with functions for the frontend-class 
*/
class common extends frontend {
  
	/**
 	 Check the Request (OK, WARNING, ......)
	*
	* @param string $request
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function checkRequest($request) {
	   if (!isset($request) or $request == "")
       {
          $retRequest = 'All';
       } else {
          $retRequest = $request;
       }
    return($retRequest);  
	}

	/**
	* Check if the Option selected
	*
	* @param string $optionValue
	* @param string $type
	* @param string $sel
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function selected($optionValue,$type,$sel) {
       $state = '';
       if ($optionValue == $type)
       {
          $state = $sel;
       }
    return($state);
	}

	/**
	* Read Trap-Information from database
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
    function readTrapInfo() {
	   global $table;
	   $DATABASE = new database($configINI);
	   $DATABASE->connect();
	   $trapInfo = $DATABASE->infoTrap($table['name']);
	   return($trapInfo);
	}
	
	/**
	* Check if use unknown-Traps in the Database
	*
	* @param boolean $useUnknownTraps
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function checkIfEnableUnknownTraps($useUnknownTraps) {
	  	unset($option);
	   if ($useUnknownTraps == "1") {
	      $option='                        <OPTION VALUE="UNKNOWN" '.common::selected("UNKNOWN",$_REQUEST['severity'],"selected").' >Traps unknown</OPTION>';
	   }
	   return($option);   
	}
	
	/**
	* Print error-lines
	*
	* @param string $lines
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function printErrorLines($errorLines,$systemError) {
	   $this->site[] = '   <DIV CLASS="errorDescription">';
	   foreach($errorLines as $lines) {
	      $this->site[] = '      '.$lines.'<BR>';  
	   }
	   if($systemError) {
	      $this->site[] = '      Error: <I>'.$systemError.'</I>';
	   }
	   $this->site[] = '   </DIV>';
	}
	
	/**
	* Delete not used fields in the frontend, when unknown-traps was selected
	*
	* @params string $action 
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function showTrapFields($action,$trap,$rowColor,$styleLine) {
       if ($_REQUEST['severity'] != "UNKNOWN") {
          if ($action == "field") {
             global $languageXML;
             $this->site[] = '      <TH CLASS="status">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['CATEGORY'].'</TH>';
             $this->site[] = '      <TH CLASS="status">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['SEVERITY'].'</TH>';
          }
	      elseif ($action == "entry") {
	         $this->site[] = '      <TD CLASS="'.$rowColor.'"><P '.$styleLine.'>'.$trap['category'].'</P></TD>';
	         $this->site[] = '      <TD CLASS="'.status.$trap['severity'].'" ALIGN="center"><P '.$styleLine.'>'.$trap['severity'].'</P></TD>'; 
	      }
	   } 
    }
	
    /**
	* Read Traps from Database and create Buttons for pages with limited trap entrys
	*
	* @author Jörg Linge
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function readTraps() {
	   global $configINI, $FRONTEND;
	   $step = $configINI['global']['step'];
	   if(!$_GET['site']){
          $site = 0;
          $from = 1;
          $to = $step;
          $limit = "0,$step";
       } else {
          $site = $_GET['site'];
          $from = ($site*$step)+1;
          $to = (($site*$step)+$step);
          $limit = ($site*$step).",".$step;
       }
       
       $DATABASE = new database($configINI);
	   $DATABASE->connect();
	   // Read traps from database
	   $traps = $DATABASE->readTraps($limit);
	   
	   $count = sizeof($traps);
	   
  	   /**
	   * @author Alex Peeters [alex.peeters@citap.be]
       */
       $countRecords = $DATABASE->readTraps('0');
       if($countRecords[0] > $step){
          if($to > $countRecords[0]){
             $to = $countRecords[0];
          }
          $page = $site + 1;
          $wantedRecordFirst = ($page * $step) + 1;
          $TwantedRecordLast = $wantedRecordFirst + ($step - 1);
          $wantedRecordLast  = ($TwantedRecordLast < $countRecords[0]) ? $TwantedRecordLast : $countRecords[0];
          $numberOffRecords  = (($wantedRecordLast - 1) % $step) + 1;
          $numberOffPagesMax = floor((($countRecords[0] - 1) / $step) + 1);
          $this->site[] = '<table border="0" width="100%"><tr><td align="center" width="36"><B>'.$from.'-'.$to.'</B></td><td align="center">';
          if ($wantedRecordLast > 1) {
             $urlWithAccessParameters = 'index.php?severity='.$_REQUEST['severity'].'&amp;category='.rawurlencode($_REQUEST['category']).'&amp;hostname='.$_REQUEST['hostname'].'&amp;trapOID='.$_REQUEST['trapOID'].'&amp;FQDN='.$_REQUEST['FQDN'];
             if ($page > 1) {
                $this->site[] = "      &nbsp;<a href=\"$urlWithAccessParameters&amp;site=0\"><IMG SRC=\"$ICONSRECORD{first}\" ALT=\"First\" BORDER=0></a>&nbsp;<a href=\"$urlWithAccessParameters&amp;site=". ($site - 1) ."\"><IMG SRC=\"". $configINI['global']['images'].$configINI['global']['iconStyle'] ."/previous.png\" ALT=\"First\" BORDER=0></a>&nbsp;&nbsp;<a href=\"$urlWithAccessParameters&amp;site=0\">1</a>";
             } else {
                $this->site[] = '      &nbsp;1';
             }
             for ($currentPage = 2; $currentPage < $numberOffPagesMax; $currentPage++) {
                if ( $page != $currentPage ) {
                   $offsetOffRecords = ($step * ($currentPage - 1));
                   $this->site[] = "      &nbsp;<a href=\"$urlWithAccessParameters&amp;site=". ($currentPage - 1) ."\">$currentPage</a>";
                } else {
                   $this->site[] = "      &nbsp;$currentPage";
                }
             }
             if ($page < $numberOffPagesMax) {
                $this->site[] = "      &nbsp;<a href=\"$urlWithAccessParameters&amp;site=". ($numberOffPagesMax - 1) ."\">$numberOffPagesMax</a>&nbsp;&nbsp;<a href=\"$urlWithAccessParameters&amp;site=". ($site + 1) ."\"><IMG SRC=\"". $configINI['global']['images'].$configINI['global']['iconStyle'] ."/next.png\" ALT=\"First\" BORDER=0></a> <a href=\"$urlWithAccessParameters&amp;site=". ($numberOffPagesMax - 1) ."\"><IMG SRC=\"$IMAGESURL/$ICONSRECORD{last}\" ALT=\"Last\" BORDER=0></a>";
             } else {
                $this->site[] = "      &nbsp;$numberOffPagesMax";
             }
             $this->site[] = '</td><td align="center" width="36"><B>'. $page .'/'. $numberOffPagesMax .'</B>';
          } else {
             $this->site[] = '      &nbsp;';
          }
          $this->site[] = '      </td></tr></table>';
       }

       return($traps);
    }
    
    /**
	* Check a page with read traps form database
	*
	* @param string $traps
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function createTrapPage($traps) {
	   global $configINI;
	   // Check if a trap mark as read
	   if(isset($traps)){
	      foreach($traps as $trap) {
             if ($trap['trapread'] == "1" or $trap['trapread'] == "2"){
                $styleLine = "style='text-decoration: line-through;'";
             } else {
                $styleLine = '';
             }
             // Set first row color
             if(!isset($rowColor)) {
			    $rowColor = "statusOdd";  
			 }
			 // Save the Trap-Message and delete " from Trap-Output
			 $trap['orgFormatline'] = str_replace('"',"",$trap['formatline']);
			 $arrIllegalCharJavabox = explode(",",$configINI['global']['illegalCharJavabox']);
			 foreach ($arrIllegalCharJavabox as $illegalChar) {
			    $trap['orgFormatline'] = str_replace($illegalChar,"",$trap['orgFormatline']);
			 }
			 
			 // Cut Trap-Message if that set in the Configurationfile
			 if($configINI['global']['cutTrapMessage'] != "") {
			    if(strlen($trap['formatline']) > $configINI['global']['cutTrapMessage']) {
			       $trap['formatline'] = substr($trap['formatline'],0,$configINI['global']['cutTrapMessage']).'.....';
				} 
			 }
             // Print trap
             $this->showTrap($trap,$rowColor,$styleLine);
             // Change color from row
			 if ($rowIndex == "0") {
                $rowColor = "statusOdd";
                $rowIndex = "1";
             } else {
                $rowColor = "statusEven";
                $rowIndex = "0";
             }
	      }
	   }   
	}
	
	/**
	* Create entry for Category, if selected table not "unknown"
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*
	*/
	function createCategoryEntry() {
	   global $table,$languageXML;
	   if($table['name'] != "snmptt_unknown") {
	      $this->site[] = '                     <TR>';
          $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">'.$languageXML['LANG']['HEADER']['FILTER']['CATEGORY'].':</TD>';
          $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">';
          $this->site[] = '                            '.common::checkRequest(rawurldecode($_REQUEST['category']));
          $this->site[] = '                        </TD>';
          $this->site[] = '                     </TR>';
	   }
	}

	/**
	* Create filter menu for categories
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*
	*/
	function createCategoryFilter() {
	   global $table,$languageXML;
	   if($table['name'] != "snmptt_unknown") {
	      $DATABASE = new database($configINI);
	      $DATABASE->connect();
	      $allCategory = $DATABASE->readCategory($table['name']);
          if ($allCategory) {
	        $this->site[] = '               <TR>';
            $this->site[] = '                  <TD ALIGN="left" COLSPAN="2" CLASS="optBoxItem">'.$languageXML['LANG']['HEADER']['OPTBOX']['CATEGORY'].':</TD>';
            $this->site[] = '               <TR>';
            $this->site[] = '                  <TD ALIGN="left" COLSPAN="2" class="optBoxItem">';
            $this->site[] = '                     <SELECT NAME="category">';
            $this->site[] = '                        <OPTION VALUE="" '.common::selected("",$_REQUEST['category'],"selected").' >'.$languageXML['LANG']['HEADER']['OPTBOX']['OPTION']['VALUEALL'].'</OPTION>';
	        foreach($allCategory as $category) {
	           $this->site[] = '                        <OPTION VALUE='.rawurlencode($category).' '.common::selected($category,rawurldecode($_REQUEST['category']),"selected").'>'.$category.'</OPTION>'; 
 	        }
  	        $this->site[] = '                     </SELECT>';
            $this->site[] = '                  </TD>';
            $this->site[] = '               </TR>';
	      }
	   }
	}	
}
?>
