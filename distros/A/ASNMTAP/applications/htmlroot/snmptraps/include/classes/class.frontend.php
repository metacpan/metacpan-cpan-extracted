<?
#########################################################
#         SNMPTraps-Frontend for Nagios & ASNMTAP       #
#                                                       #
#                    by Michael Lübben                  #
#                   --- Lizenz GPL ---                  #
#########################################################

/**
* This Class creates the Web-Frontend for the SNMP-Trap Frontend
*/

class frontend {
  	var $site;
	
	/**
	* Constructor
	*
	* @param config $configINI
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/  
    function frontend(&$configINI) {
		$this->configINI = &$configINI;
	}

	// ==================================== Functions to create the page ====================================
	
	/**
	* Open a Web-Site in a Array site[].
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
	function openSite() {
		$this->site[] = '<HTML>';
		$this->site[] = '<HEAD>';
		$this->site[] = '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; CHARSET=UTF-8"/>';
		$this->site[] = '<TITLE>'.$this->configINI['internal']['title'].' '.$this->configINI['internal']['version'].'</TITLE>';
		$this->site[] = '<SCRIPT TYPE="text/javascript" SRC="./include/js/nagtrap.js"></SCRIPT>';
		$this->site[] = '<SCRIPT TYPE="text/javascript" SRC="./include/js/overlib.js"></SCRIPT>';
		$this->site[] = '<LINK HREF="'.$this->configINI['nagios']['prefix'].'/include/css/nagtrap.css" REL="stylesheet" TYPE="text/css">';
		$this->site[] = '<LINK HREF="'.$this->configINI['nagios']['prefix'].'/include/css/status.css" REL="stylesheet" TYPE="text/css">';
		$this->site[] = '<LINK HREF="'.$this->configINI['nagios']['prefix'].'/include/css/showlog.css" REL="stylesheet" TYPE="text/css">';
		$this->site[] = '<LINK HREF="'.$this->configINI['nagios']['prefix'].'/include/css/common.css" REL="stylesheet" TYPE="text/css">';
		$this->site[] = '</HEAD>';
		$this->site[] = '<BODY CLASS="status">';
	}
	
	/**
	* Closed a Web-Site in the Array site[]
	*
	* @author Michael Luebben <michael_luebben@web.de>
    */
	function closeSite() {
		$this->site[] = '</BODY>';
		$this->site[] = '</HTML>';
	}
	
	/**
	* Create a Web-Side from the Array site[].
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function printSite() {
		foreach ($this->site as $row) {
			echo $row."\n";
		}
	}
	
	// ======================= Contructor and functions for the header of the frontend ======================
	
	/**
	* Constructor for the header
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function constructorHeader() {
	    global $table;
		$this->site[] = '<TABLE BORDER="0" WIDTH="100%" CELLPADDING="0" CELLSPACING="0">';
		$this->site[] = '   <TR>';
		$this->site[] = '      <TD ALIGN="left" VALIGN="top" WIDTH="33%">';
		$this->createInfoBox();
		$this->site[] = '         <BR>';
		$this->createFilter();
		$this->site[] = '      </TD>';
		$this->site[] = '      <TD ALIGN="center" VALIGN="top" WIDTH="33%">';
		$this->createNavBox();
		$this->site[] = '         <BR>';
		$this->createDBInfo($table);
		$this->site[] = '      </TD>';
		$this->site[] = '      <TD ALIGN="right" VALIGN="top" WIDTH="33%">';
		$this->createOptBox();
		$this->site[] = '      </TD>';
		$this->site[] = '   </TR>';
		$this->site[] = '</TABLE>';
		$this->site[] = '<BR><BR>';
	}
	
	/**
	* Create a Info-Box
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function createInfoBox() {
	    global $languageXML;
		$this->site[] = '         <TABLE CLASS="infoBox" BORDER="1" CELLPADDING="0" CELLSPACING="0">';
		$this->site[] = '            <TR>';
        $this->site[] = '               <TD CLASS="infoBox">';
        $this->site[] = '                  <DIV CLASS="infoBoxTitle">'.$languageXML['LANG']['HEADER']['INFOBOX']['CURRENTTRAPLOG'].'</DIV>';
        $trapInfo = common::readTrapInfo();
        // FIXME: View function.php --> Class common!
        $this->site[] = '                  '.$languageXML['LANG']['HEADER']['INFOBOX']['LASTUPDATE'].': '.$trapInfo['last'].'<BR>';
        $this->site[] = '                  Nagios&reg; - <A HREF="http://www.nagios.org" TARGET="_blank" CLASS="homepageURL">www.nagios.org</A><BR>';
        $this->site[] = '                  ASNMTAP&copy; - <A HREF="http://asnmtap.citap.be" TARGET="_blank" CLASS="homepageURL">asnmtap.citap.be</A><BR>';
        $this->site[] = '                  NagTrap&copy; by Michael L&#252;bben &amp; Alex Peeters<BR>';
        $this->site[] = '                  '.$languageXML['LANG']['HEADER']['INFOBOX']['LOGGEDINAS'].' <I>'.$_SERVER['PHP_AUTH_USER'].'</I><BR>';
        $this->site[] = '               </TD>';
        $this->site[] = '            </TR>';
		$this->site[] = '         </TABLE>';
	}
	
	/**
	* Create a Filter-Box
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function createFilter() {
	  	global $languageXML, $configINI;
		$this->site[] = '         <TABLE BORDER="1" CLASS="filter" CELLSPACING="0" CELLPADDING="0">';
		$this->site[] = '            <TR>';
        $this->site[] = '               <TD CLASS="filter">';
        $this->site[] = '                  <TABLE BORDER="0" CELLSPACING="2" CELLPADDING="0">';
        $this->site[] = '                     <TR>';
        $this->site[] = '                        <TD COLSPAN="2" VALIGN="top" ALIGN="left" CLASS="filterTitle">'.$languageXML['LANG']['HEADER']['FILTER']['DISPLAYFILTERS'].':</TD>';
        $this->site[] = '                        <TD></TD>';
        $this->site[] = '                     </TR>';
        $this->site[] = '                     <TR>';
        $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">'.$languageXML['LANG']['HEADER']['FILTER']['HOST'].':</TD>';
        $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">';
		$this->site[] = '                            '.common::checkRequest($_REQUEST['hostname']);
		$this->site[] = '                        </TD>';
        $this->site[] = '                     </TR>';

  	    // @author Alex Peeters [alex.peeters@citap.be]
	    $this->site[] = '                     <TR>';
        $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">'.$languageXML['LANG']['HEADER']['FILTER']['TRAPOID'].':</TD>';
        $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">';
		$this->site[] = '                            '.common::checkRequest($_REQUEST['trapOID']);
		$this->site[] = '                        </TD>';
        $this->site[] = '                     </TR>';

        $this->site[] = '                     <TR>';
        $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">'.$languageXML['LANG']['HEADER']['FILTER']['SEVERITYLEVEL'].':</TD>';
        $this->site[] = '                        <TD VALIGN="top" ALIGN="left" CLASS="filterName">';
        $this->site[] = '                            '.common::checkRequest($_REQUEST['severity']);
        $this->site[] = '                        </TD>';
        $this->site[] = '                     </TR>';
        $this->site[] = '                            '.common::createCategoryEntry();
        $this->site[] = '                     <TR>';
        $this->site[] = '                        <TD COLSPAN="2" VALIGN="top" ALIGN="center" CLASS="filterName"><A HREF="./index.php"><B><I>'.$languageXML['LANG']['HEADER']['FILTER']['RESET'].'</I></B></A></TD>';
		$this->site[] = '                     </TR>';
        $this->site[] = '                  </TABLE>';
        $this->site[] = '               </TD>';
        $this->site[] = '            </TR>';
		$this->site[] = '         </TABLE>';
	}  
	
	/**
	* Create a Navigation-Box
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function createNavBox() {
	    global $languageXML;
        $this->site[] = '         <TABLE CLASS="navBox" BORDER="0" CELLSPACING="0" CELLPADDING="0">';
        $this->site[] = '            <TR>';
        $this->site[] = '               <TD ALIGN="center" VALIGN="middle" CLASS="navBoxItem">';
        $this->site[] = '                  <IMG SRC="'.$this->configINI['nagios']['images'].'empty.gif" ALT="" BORDER="0" WIDTH="75" HEIGHT="1">';
        $this->site[] = '               </TD>';
        $this->site[] = '               <TD WIDTH=15></TD>';     
        $this->site[] = '               <TD ALIGN="center" CLASS="navBoxDate">';
        $this->site[] = '                  <DIV CLASS="navBoxTitle">'.$languageXML['LANG']['HEADER']['NAVBOX']['LOGFILENAV']['LINE1'].'<BR>'.$languageXML['LANG']['HEADER']['NAVBOX']['LOGFILENAV']['LINE2'].'</DIV><BR>';
        $trapInfo = common::readTrapInfo();
        $this->site[] = '                     '.$trapInfo['first'];
        $this->site[] = '                  <BR>'.$languageXML['LANG']['HEADER']['NAVBOX']['TO'].'<BR>';
        $this->site[] = '                     '.$trapInfo['last'];
        $this->site[] = '               </TD>';
        $this->site[] = '               <TD WIDTH=15></TD>';
        $this->site[] = '               <TD>';
        $this->site[] = '                  <IMG SRC="'.$this->configINI['nagios']['images'].'empty.gif" ALT="" BORDER="0" WIDTH="75" HEIGHT="1">';
        $this->site[] = '               </TD>';
        $this->site[] = '            </TR>';
        $this->site[] = '         </TABLE>';
	}
	
	/**
	* Create a Database-Information for the Nagigation
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function createDBInfo($table) {
	    global $languageXML;
	    $this->site[] = '         <DIV CLASS="navBoxFile">';
		$this->site[] = '            '.$languageXML['LANG']['HEADER']['DBINFO']['DATABASE'].': '.$this->configINI['database']['name'].' '.$languageXML['LANG']['HEADER']['DBINFO']['TABLE'].': '.$table['name'];
		$this->site[] = '         </DIV>';
	}
	  
	/**
	* Create a Box for Options
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function createOptBox() {
	    global $languageXML;
        $this->site[] = '         <FORM METHOD="get" ACTION="./index.php">';
        $this->site[] = '            <TABLE BORDER="0" CLASS="optBox">';
        $this->site[] = '               <TR>';
        $this->site[] = '                  <TD ALIGN="left" COLSPAN="2" CLASS="optBoxItem">'.$languageXML['LANG']['HEADER']['OPTBOX']['SEVERITYDETAIL'].':</TD>';
        $this->site[] = '               </TR>';
        $this->site[] = '               <TR>';
        $this->site[] = '                  <TD ALIGN="left" COLSPAN="2" class="optBoxItem">';
        $this->site[] = '                     <SELECT NAME="severity">';
        $this->site[] = '                        <OPTION VALUE="" '.common::selected("",$_REQUEST['severity'],"selected").' >'.$languageXML['LANG']['HEADER']['OPTBOX']['OPTION']['VALUEALL'].'</OPTION>';
        $this->site[] = '                        <OPTION VALUE="OK" '.common::selected("OK",$_REQUEST['severity'],"selected").' >Traps ok</OPTION>';
        $this->site[] = '                        <OPTION VALUE="WARNING" '.common::selected("WARNING",$_REQUEST['severity'],"selected").' >Traps warning</OPTION>';
        $this->site[] = '                        <OPTION VALUE="CRITICAL" '.common::selected("CRITICAL",$_REQUEST['severity'],"selected").' >Traps critical</OPTION>';
        $this->site[] = common::checkIfEnableUnknownTraps($this->configINI['global']['useUnknownTraps']);
        $this->site[] = '                     </SELECT>';
        $this->site[] = '                  </TD>';
        $this->site[] = '               </TR>';
        $this->site[] = common::createCategoryFilter();
		$this->site[] = '               <TR>';
		$this->site[] = '                  <TD ALIGN="left" CLASS="optBoxItem">'.$languageXML['LANG']['HEADER']['OPTBOX']['OLDERENTRIESFIRST'].':</TD>';
		$this->site[] = '                  <TD></TD>';
		$this->site[] = '               </TR>';
		$this->site[] = '               <TR>';
        $this->site[] = '                  <TD ALIGN="left" VALIGN="bottom" CLASS="optBoxItem"><INPUT TYPE="checkbox" name="oldestfirst" '.common::selected("on",$_REQUEST['oldestfirst'],"checked").' ></TD>';
        $this->site[] = '                  <TD ALIGN="right" CLASS="optBoxItem"><INPUT TYPE="submit" VALUE="'.$languageXML['LANG']['HEADER']['OPTBOX']['UPDATEBUTTON'].'">';
	    $this->site[] = '                     <INPUT TYPE="hidden" NAME="hostname" VALUE="'.$_GET['hostname'].'">';
	    $this->site[] = '                     <INPUT TYPE="hidden" NAME="trapOID" VALUE="'.$_GET['trapOID'].'">';
	    $this->site[] = '                     <INPUT TYPE="hidden" NAME="FQDN" VALUE="'.$_GET['FQDN'].'">';
        $this->site[] = '                  </TD>';
        $this->site[] = '               </TR>';
        $this->site[] = '            </TABLE>';
        $this->site[] = '         </FORM>';
	}
	
	/**
	* Create a error-message
	*
	* @param string $error
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/ 
	function printError($error,$systemError) {
	   global $errorXML;
	   $this->site[] = '<HR>';
	   $this->site[] = '   <DIV CLASS="errorMessage">'.$errorXML['ERROR'][$error]['MESSAGE'].'</DIV>';
	   common::printErrorLines($errorXML['ERROR'][$error]['DESCRIPTION'],$systemError);
	   $this->site[] = '</HR>';
	}
	
	// ======================== Contructor and functions for the main of the frontend =======================
	
	/**
	* Constructor for the main
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	function constructorMain() {
	   global $languageXML, $traps, $MAIN;
	   // Check database connacetion and read traps from database
	   $traps = common::readTraps();
	   $this->site[] = '<FORM NAME="form1" ACTION="./index.php" METHOD="POST">';
	   $this->site[] = '<TABLE WIDTH="100%" BORDER="0">';
	   $this->site[] = '   <TR>';

  	   /**
	   * @author Alex Peeters [alex.peeters@citap.be]
       */
       if ($MAIN->checkAction() == "1") {
	     $this->site[] = '      <TH CLASS="status" WIDTH="30">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['OPTION'].'</TH>';
       }

       $this->site[] = '      <TH CLASS="status">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['HOST'].'</TH>';
       $this->site[] = '      <TH CLASS="status" WIDTH="30">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['TRAPOID'].'</TH>';
       $this->site[] = '      <TH CLASS="status">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['TRAPTIME'].'</TH>';
       common::showTrapFields("field",NULL,NULL,NULL);
       $this->site[] = '      <TH CLASS="status">'.$languageXML['LANG']['MAIN']['TRAPTABLEHEADER']['MESSAGE'].'</TH>';
	   $this->site[] = '   </TR>';
	   common::createTrapPage($traps);
	   $this->site[] = '</TABLE>';
	}
	
	/**
	* Create a Java Infobox
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/ 
	function javaInfoBox($formatline) {
	   $infoBox = 'onmouseover="return overlib(\'';
	   $infoBox .= $formatline;
	   $infoBox .= '\', CAPTION, \'Trap-Message\', VAUTO);" onmouseout="return nd();" ';
	   return($infoBox);
	}
	
    /**
	* Show traps
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/ 
	function showTrap($trap,$rowColor,$styleLine) {
	   global $configINI, $languageXML, $MAIN;
       $this->site[] = '   <TR>';

  	   /**
	   * @author Alex Peeters [alex.peeters@citap.be]
       */
       if ($MAIN->checkAction() == "1") {
   	      // Checkbox
	      $this->site[] = '      <TD CLASS="'.$rowColor.'"><INPUT TYPE="checkbox" NAME="trapIDs[]" VALUE="'.$trap['id'].'" '.$_GET['sel'].'>';
	      // Mark a trap
	      $this->site[] = '         <A HREF="./index.php?action=mark&amp;trapID='.$trap['id'].'&amp;severity='.$_REQUEST['severity'].'&amp;category='.rawurlencode($_REQUEST['category']).'&amp;hostname='.$_REQUEST['hostname'].'&amp;trapOID='.$_REQUEST['trapOID'].'&amp;FQDN=T"><IMG SRC="'.$configINI['global']['images'].$configINI['global']['iconStyle'].'/mark.png" ALT="" BORDER="0" TITLE="'.$languageXML['LANG']['MAIN']['TRAPTABLEENTRY']['OPTIONREAD'].'"></A>';
	      // Delete a trap
	      $this->site[] = '         <A HREF="./index.php?action=delete&amp;trapID='.$trap['id'].'&amp;severity='.$_REQUEST['severity'].'&amp;category='.rawurlencode($_REQUEST['category']).'&amp;hostname='.$_REQUEST['hostname'].'&amp;trapOID='.$_REQUEST['trapOID'].'&amp;FQDN=T"><IMG SRC="'.$configINI['global']['images'].$configINI['global']['iconStyle'].'/delete.png" ALT="" BORDER="0" TITLE="'.$languageXML['LANG']['MAIN']['TRAPTABLEENTRY']['OPTIONDELETE'].'"></A>';
	      $this->site[] = '      </TD>';
       }

	   // Select host
	   $this->site[] = '      <TD CLASS="'.$rowColor.'"><P '.$styleLine.'><A HREF="./index.php?severity='.$_REQUEST['severity'].'&amp;category='.rawurlencode($_REQUEST['category']).'&amp;hostname='.$trap['hostname'].'&amp;FQDN=T">'.$trap['hostname'].'</A></P></TD>';
	   // Select trapOID
	   $this->site[] = '      <TD CLASS="'.$rowColor.'"><P '.$styleLine.'><A HREF="./index.php?severity='.$_REQUEST['severity'].'&amp;category='.rawurlencode($_REQUEST['category']).'&amp;hostname='.$trap['hostname'].'&amp;trapOID='.$trap['trapoid'].'&amp;FQDN=T">'.$trap['trapoid'].'</A></P></TD>';
	   $this->site[] = '      <TD CLASS="'.$rowColor.'"><P '.$styleLine.'>'.$trap['traptime'].'</P></TD>';
	   common::showTrapFields("entry",$trap,$rowColor,$styleLine);
	   $this->site[] = '      <TD CLASS="'.$rowColor.'"><P '.$styleLine.' '.$this->javaInfoBox($trap['orgFormatline']).'CLASS="formatline">'.htmlentities($trap['formatline']).'</P></TD>';
	   $this->site[] = '   </TR>';
	}
	
	// ======================= Contructor and functions for the footer of the frontend ====================== 
	
	/**
	* Constructor for the main
	*
	* @author Michael Luebben <michael_luebben@web.de>
	*/
	//FIXME !!!
	function constructorFooter() {
	   global $configINI, $languageXML, $MAIN;
	   $this->site[] = '<TABLE WIDTH="100%" BORDER="0">';
	   $this->site[] = '   <TR>';
	   $this->site[] = '      <TD CLASS="linkBox">';

  	   /**
	   * @author Alex Peeters [alex.peeters@citap.be]
       */
       if ($MAIN->checkAction() == "1") {
	      $this->site[] = '         <IMG SRC="'.$configINI['global']['images'].$configINI['global']['iconStyle'].'/arrow.png" ALT="" BORDER="0">';
  	      $this->site[] = '         <INPUT TYPE="checkbox" NAME="checkbox" VALUE="checkbox" onClick="checkAll(\'yes\'); return true;">(Mark all)';
  	      $this->site[] = '         <INPUT TYPE="image" SRC="'.$configINI['global']['images'].$configINI['global']['iconStyle'].'/mark.png" NAME="markTraps[0]" TITLE="'.$languageXML['LANG']['MAIN']['TRAPTABLEENTRY']['OPTIONREAD'].'">';
	      $this->site[] = '         <INPUT TYPE="image" SRC="'.$configINI['global']['images'].$configINI['global']['iconStyle'].'/delete.png" NAME="deleteTraps[0]" TITLE="'.$languageXML['LANG']['MAIN']['TRAPTABLEENTRY']['OPTIONDELETE'].'">';
	   }

	   $this->site[] = '         <INPUT TYPE="hidden" NAME="oldestfirst" VALUE="'.$_REQUEST['oldestfirst'].'">';
       $this->site[] = '         <INPUT TYPE="hidden" NAME="severity" VALUE="'.$_REQUEST['severity'].'">';
	   $this->site[] = '         <INPUT TYPE="hidden" NAME="category" VALUE="'.$_REQUEST['category'].'">';
	   $this->site[] = '         <INPUT TYPE="hidden" NAME="hostname" VALUE="'.$_REQUEST['hostname'].'">';
	   $this->site[] = '         <INPUT TYPE="hidden" NAME="trapOID" VALUE="'.$_REQUEST['trapOID'].'">';
	   $this->site[] = '         <INPUT TYPE="hidden" NAME="FQDN" VALUE="'.$_REQUEST['FQDN'].'">';
	   $this->site[] = '      </TD>';	   
	   $this->site[] = '   </TR>';
	   $this->site[] = '</TABLE>';
	   $this->site[] = '</FORM>';
	}
	
}
?>
