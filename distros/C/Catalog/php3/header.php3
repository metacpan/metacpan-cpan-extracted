<?php
require("config.inc.php3");
require("view.inc.php3");
?>

<HTML>
  <HEAD>
  </HEAD>
  <BODY
    bgcolor="#ffffff" 
    alink="#000080" 
    vlink="#000080" 
    link="#000080">
    <CENTER>
      <CENTER>
        <IMG 
	  src="/images/grbus.gif" 
	  height="150" 
	  width="189" 
	  alt="grlogo"> 
        <HR width="90%" color="007BB7" noshade>
        <TABLE width="90%" border="0" cellpadding="5" summary="search form">
          <TR>
            <TD>
              <FORM 
		action="<?php echo $SCRIPT_NAME ?>" 
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
		    value="<?php echo $text ?>"> 
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
      </center>
    </center>
    
    <center>
      <br>
      
    </form>
    </center>
    
