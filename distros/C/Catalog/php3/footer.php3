<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
  <HEAD>
    <TITLE>
      _CATEGORY_
    </TITLE>
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
	  height="132" 
	  width="240" 
	  alt="grlogo"> 
        <HR width="90%" color="007BB7" noshade>
        <TABLE width="90%" border="0" cellpadding="5" summary="search form">
          <TR>
            <TD>
              <FORM 
		action="/browse/Catalog" 
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
                </CENTER>
              </FORM>
            </TD>
            <TD>
              <IMG 
		alt="Banner Ad"
		align="RIGHT" 
		src="/images/infinitylogo1.gif"
		width="286" 
		height="76">
            </TD>
          </TR>
        </TABLE>
        <HR width="90%" color="007BB7" noshade>
      </center>
    </center>
    <H2>
      _PATH_
    </H2>
    </TABLE>
    <BR><BR>
    
    <!-- start categories -->
    <TABLE WIDTH="70%" ALIGN="LEFT">
      <!-- params 'style' => 'table', 'columns' => 2 -->
      <!-- start row --> 
      <tr>
	<!-- start entry -->
	<td> <b><a href='_URL_'>_NAME_</a></b> (_COUNT_) </td>
	<!-- end entry -->
      </tr>
      <!-- end row --> 
    </table>
    <!-- end categories -->
    
    <BR CLEAR>
    <BR>
    <HR width="90%" color="007BB7" noshade>
    <BR>
    
    <!-- params 'style' => 'table', 'columns' => 2 -->
    <TABLE CELLSPACING="0" CELLPADDING="1" WIDTH="100%">
      <!-- start row --> 
      <TR>
	<!-- start entry -->
	<TD ALIGN="LEFT">
	  <a href='_COMPANYURL-QUOTED_'>_COMPANYNAME_ </a>
	</TD>
	<TD ALIGN="LEFT">
	  _ADDRESS_
	</TD>
	<!-- end entry -->
      </tr>
      <!-- end row --> 
    </table>
  </ul>

    <center>
      <!-- start pager -->
      Number of pages _MAXPAGES_
      <p>
	_PAGES_
	<!-- end pager -->
    </center>