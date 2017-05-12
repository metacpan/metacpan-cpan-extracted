package CGI::FileManager::Templates;
use strict;
use warnings;


=head1 CONTENT

css file and HTML::Template files hard coded in the application

=cut

our %tmpl;

our $css = <<CSS;
<style type="text/css">
BODY
{
    FONT-SIZE: 14px;
    COLOR: #a5a5a5;
    FONT-FAMILY: Verdana;
    BACKGROUND-COLOR: lightblue;
    TEXT-DECORATION: none
}
.error {
	color: red;
}

.mybutton {
    color: #4a4d4a;
	background-color:#8080FF;
	font-size:12px;
	font-weight:bold;
    /*
	FONT-FAMILY: Verdana,arial;
    TEXT-DECORATION: none
	*/
}
.choosebutton {
    color: #4a4d4a;
	font-size:12px;
	font-weight:bold;
    /*
	FONT-FAMILY: Verdana,arial;
    TEXT-DECORATION: none
	*/
}


A:link
{
    FONT-SIZE: 12px;
    COLOR: #339900;
    FONT-FAMILY: verdana;
    TEXT-DECORATION: none
}
A:visited
{
    FONT-SIZE: 12px;
    COLOR: #996600;
    FONT-FAMILY: Verdana;
    TEXT-DECORATION: none
}
A:hover
{
    FONT-SIZE: 12px;
    COLOR: #cc9900;
    FONT-FAMILY: Verdana;
    TEXT-DECORATION: none
}
A:active
{
    FONT-SIZE: 12px;
    COLOR: #000033;
    FONT-FAMILY: Verdana;
    TEXT-DECORATION: none
}

.files TABLE
{
	cell-spacing:   1;
	cell-padding:   0;
	border:         1;
	align:          middle;
}

.files TH
{
	background-color: #8080FF;
}

TD
{
    FONT-SIZE: 13px;
    COLOR: #4a4d4a;
    FONT-FAMILY: Verdana,arial;
    TEXT-DECORATION: none
}

TH
{
	FONT-SIZE: 13px;
    COLOR: #4a4d4a;
    FONT-FAMILY: Verdana,arial;
    TEXT-DECORATION: none
}

.even TD {
	FONT-SIZE: 13px;
    COLOR: #4a4d4a;
    FONT-FAMILY: Verdana,arial;
    TEXT-DECORATION: none;
	background-color: #CCFF99;
}

.odd TD {
	FONT-SIZE: 13px;
    COLOR: #4a4d4a;
    FONT-FAMILY: Verdana,arial;
    TEXT-DECORATION: none;
	background-color: #AAFF99;
}



</style>
CSS


$tmpl{message} = <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML> 
<HEAD>
	<TITLE>CGI::FileManager</TITLE>  
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    CSS_STYLE_SHEET
</HEAD> 
<body>
<p>Message</p>
<TMPL_VAR message>
</body>
<HTML>
ENDHTML


$tmpl{login} = <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML> 
<HEAD>
	<TITLE>CGI::FileManager</TITLE>  
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    CSS_STYLE_SHEET
</HEAD> 
<body>
<form method="POST"><br><br><br><br><br><br><br><br>
<center>
<TMPL_IF login_failed><div class="error">Login failed</div></TMPL_IF>
<table bgcolor="#006666" cellspacing="1" cellpadding="0" border="0" align="middle">
<tr><td bgcolor="#8080FF" colspan=2 align="middle"><B>Login form</B><input type="hidden" name="rm" value="login_process"></td></tr>
<tr><td bgcolor="#CCFF99">Username:</td> <td><input name="username" value="<TMPL_VAR username>"></td></tr>
<tr><td bgcolor="#CCFF99">Password:</td> <td> <input name="password" type="password"></td></tr>
<tr><td bgcolor="#CCFF99" colspan=2 align="middle"><input type="submit" value="Login"></td></tr>
</table></center>
</body>
<HTML>
ENDHTML

$tmpl{list_dir} = <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML> 
<HEAD>
	<TITLE>CGI::FileManager - Directory Listing</TITLE>  
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    CSS_STYLE_SHEET
</HEAD> 
<body><br><br>
<center>

<TMPL_IF files>
<div class="files">
<table>
 <tr>
   <th>name</th>
   <th>type</th>
   <th>date</th>
   <th>size</th>
   <th></th>
   <th></th>
 </tr>
 <TMPL_LOOP files>
  <tr class="<TMPL_IF NAME="__odd__">odd<TMPL_ELSE>even</TMPL_IF>">
  	<TMPL_IF subdir>
	  <td>
	    <a href="?rm=change_dir;workdir=<TMPL_VAR workdir>;dir=<TMPL_VAR filename>">
		<TMPL_VAR filename>
		</a>
	  </td>
	<TMPL_ELSE>
	  <TMPL_IF zipfile>
	    <td>
	    <a href="?rm=unzip;workdir=<TMPL_VAR workdir>;filename=<TMPL_VAR filename>">
		<TMPL_VAR filename>
		</a>
		</td>
	  <TMPL_ELSE>
	    <td><TMPL_VAR filename></td>
	  </TMPL_IF>
	</TMPL_IF>
	<td><TMPL_VAR filetype></td>
	<td><TMPL_VAR filedate></td>
	<td><TMPL_VAR size></td>
	<td><TMPL_IF delete_link><a href="?workdir=<TMPL_VAR workdir>;<TMPL_VAR delete_link><TMPL_VAR filename>">delete</a></TMPL_IF></td>
	<td><TMPL_IF rename_link><a href="?workdir=<TMPL_VAR workdir>;<TMPL_VAR rename_link><TMPL_VAR filename>">rename</a></TMPL_IF></td>
  </tr>
 </TMPL_LOOP>
</table>
</div>
</TMPL_IF>

<br><br>
<table  cellspacing="0" cellpadding="0" border="0" align="middle">
<TR><TD align="middle" colspan=2><hr></TD></TR>

 <tr><td align="right" valign="top">
<form method="GET">
<input type="hidden"  name="rm" value="create_directory">
<input type="hidden"  name="workdir" value="<TMPL_VAR workdir>">
<input name="dir" size="15"></TD><TD>
<input type="submit"  class="mybutton" value="Create Directory">
</form>
</TD></TR>
<TR><TD align="middle" colspan=2><hr></TD></TR>
<TR><TD colspan=2 align="left">

  <form method="POST" enctype="multipart/form-data">
  <input type="hidden" name="workdir" value="<TMPL_VAR workdir>">
  <input type="hidden" name="rm" value="upload_file">
  <input type="file" size="16" name="filename" class="choosebutton">
  <input type="submit" class="mybutton" value="Upload">
  </form>

</TD></TR>
<TR><TD align="middle" colspan=2><hr></TD></TR>
<TR><TD align="right"></TD>
    <TD align="left">
     <table>
       <tr>
	   <td>
        <form method="GET">
        <input type="hidden" name="rm" value="list_dir">
        <input type="hidden" name="workdir" value="<TMPL_VAR workdir>">
        <input type="submit" class="mybutton" value="Refresh">
        </form>
       </td>
       <td>
        <form method="GET">
        <input type="hidden" name="rm" value="logout">
        <input type="submit" class="mybutton" value="Logout">
        </form>
       </td>
	   </tr>
	 </table>
   </TD>
</TR></table>

<table  cellspacing="0" cellpadding="0" border="0" align="middle">

<TR><TD colspan=2 align="middle">
You are using CGI::FileManager Version: <TMPL_VAR version>
<br>
For help contact <a href="mailto:gabor\@pti.co.il">Gabor Szabo</a>
</TD></TR></table>

</center>
</body>
</html>
ENDHTML




$tmpl{logout} = <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML> 
<HEAD>
	<TITLE>CGI::FileManager - Good bye</TITLE>  
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    CSS_STYLE_SHEET
</HEAD> 
<body>
<p>
You were successfully logged out.
</p>
<form method="POST">
<input type="submit" value="Login again">
</form>
</body>
<HTML>
ENDHTML

$tmpl{rename_form} = <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML> 
<HEAD>
	<TITLE>CGI::FileManager - Rename <TMPL_VAR filename></TITLE>  
	<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    CSS_STYLE_SHEET
</HEAD> 
<body>
<center>
<form method="POST" action="?">
<input type="hidden" name="rm" value="rename">
<input type="hidden" name="workdir" value="<TMPL_VAR workdir>">
<input type="hidden" name="filename" value="<TMPL_VAR filename>">
Rename <TMPL_VAR filename>  to
<input name="newname" value="<TMPL_VAR newname>">
<input type="submit" value="Rename">
</form>
</center>
</body>
<HTML>
ENDHTML


our $cgi = 
q(#!/usr/bin/perl -wT
use strict;

$ENV{PATH}= "";
use lib "../lib";
use CGI::FileManager;
my $fm = CGI::FileManager->new(
			PARAMS => {
				AUTH => {
					PASSWD_FILE => "../data/authpasswd",
				},
				TMPL_PATH => "../templates",
			}
		);
$fm->run;
);




sub _get_template {
	my $name = shift;
	$tmpl{$name} =~ s/CSS_STYLE_SHEET/$css/;
	return $tmpl{$name};
}


1;


