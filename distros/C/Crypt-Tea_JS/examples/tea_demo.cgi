#! /usr/bin/perl
#########################################################################
#        This Perl script is Copyright (c) 2004, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################
use Crypt::Tea_JS;

my %username2key = (james => 'bond');
my $title        = "Crypt::Tea_JS Demo...";
my $security_reminder = <<'EOT';
<P>Security reminder : When you have finished, to prevent other people 
using <I>Back</I> and <I>javascript:alert(key)</I>, you should <INPUT
TYPE="button" VALUE="Clear the Screen" onClick="return clearScreen();">
and, to be safe, <I>quit the browser</I>.</P>
EOT

# This simple cgi script doesn't actually athenticate the user;
# anyone claiming to be james but not knowing the password will
# just get a screenful of random binary data. Unfortunately, this
# allows an attacker to see the same text encrypted with many
# different keys of his own choosing, which is a vulnerability.
# Better: browser and server could challenge each other with short
# random strings and check the results of each other's encryptions
# before proceeding.  This will probably feature in a future version...

my %DAT; {   # extract the FORM data ...
	my ($RM, $QS); $RM = $ENV{REQUEST_METHOD};
	if ($RM eq 'POST') { read (STDIN, $QS, $ENV{CONTENT_LENGTH});
	} elsif ($RM eq 'GET') { $QS = $ENV{QUERY_STRING};
	} else { die "Unknown request method $RM";
	}
	foreach (split (/&/, $QS)) {
		my ($k, $v) = split (/=/, $_); $v =~ tr/+/ /;
		$v =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
		if (! defined($DAT{$k})) { $DAT{$k}=$v; } else { $DAT{$k}.="\0$v"; }
	}
}
# open (T, ">>/tmp/tea");   # debug stuff
# foreach (sort keys %DAT) { print T "$_=$DAT{$_}\n"; }

#------------------- initial login screen ------------------------
if (! $DAT{username}) {
	print "Content-type: text/html\n\n<HTML><HEAD><TITLE>$title</TITLE>\n";
	print tea_in_javascript();
	print ajax_utils();
	print <<EOT;
<SCRIPT LANGUAGE="JavaScript"> <!--
function clearScreen() {
	username = '';  key = ''; 
	document.getElementById('mainbody').innerHTML = '';
}
// -->
</SCRIPT>
</HEAD><BODY BGCOLOR="#FFFFFF">
<P ALIGN="center"><FONT SIZE="+2"><B><I>$title</I></B></FONT></P>
<HR><DIV ID="mainbody">
<P>Welcome <I>james</I> . . . (Hint: your password is <I>bond</I>)
<SCRIPT LANGUAGE="JavaScript"> <!--
function loginForm_onClick() {
	// var loginForm = document.getElementById('loginForm');
	username = document.getElementById('username').value;
	key = document.getElementById('password').value;
	request  = createXMLHttpRequest();
	var URL  = '$ENV{SCRIPT_NAME}';
	requestData(request, URL, 'username='+username);
	return false;
}
// -->
</SCRIPT>
<FORM id="loginForm" action="null" method="post"> <TABLE ALIGN="center">
<TR><TH>Username :</TH><TD>
<INPUT ID="username" TYPE="text" NAME="username">
</TD></TR><TR><TH>Password :</TH><TD>
<INPUT ID="password" TYPE="password" NAME="password">
</TD></TR><TR><TD></TD><TD>
<INPUT TYPE="button" VALUE="Log In" onClick="return loginForm_onClick();">
</TD></TR>
</TABLE> </FORM>
<P>Security reminder: you can audit the code that you are about to run
if you <I>View</I> the <I>Source</I> of this page&nbsp;.&nbsp;.&nbsp;.</P>
</DIV><HR><CENTER><P>
See also <A HREF="http://search.cpan.org/~pjb">search.cpan.org/~pjb</A>
</P></CENTER></BODY></HTML>
EOT
	exit 0;
}
my $username = $DAT{username};
my $key      = $username2key{$username};
# print T "username=$username key=$key\n";
# print T "DAT{cyphertext}=$DAT{cyphertext}\n";

#------------------- greeting after login ------------------------
if (! $DAT{cyphertext}) {
	my $greeting_cyphertext = &encrypt ( <<EOT , $key );
<P>Greetings $username.</P>
<P>Latest gossip: the young Miss Briss seems OK, but don't trust her
brother Hugh; we don't know who he's working for, could be unwitting.
Also, AH may have been sprung - be circumspect.
C will discuss this with you.</P>
<P>Anything to report ?</P>
<FORM id="reportForm" action="null" method="post"> <TABLE ALIGN="center">
<TR><TH>Contact name</TH><TD><INPUT TYPE="text" NAME="contact"></TD></TR>
<TR><TH>Date   </TH><TD><INPUT TYPE="text" NAME="date">   </TD></TR>
<TR><TH>Comment</TH><TD><INPUT TYPE="text" NAME="comment" SIZE=72></TD></TR>
<TR><TD></TD><TD>
<INPUT TYPE="button" VALUE="File Report" onClick="return myForm_onClick();">
</TD></TR>
</TABLE> </FORM>
$security_reminder
EOT
	print "Content-type: text/plain\n\n$greeting_cyphertext";
	exit 0;
}

# ------------------ we have some cyphertext -------------------
my $plaintext = decrypt($DAT{cyphertext}, $key);
my @contents = split ("&|=", $plaintext);
# print T "plaintext=$plaintext\ncontents=@contents\n";

my $new_plaintext = "<P>$username, you submitted the following report:</P>\n";
while (1) {
	my $k = shift @contents; my $v = shift @contents; last unless $k;
	$new_plaintext .= "<B>$k</B> : $v<BR>\n";
}
$new_plaintext .= $security_reminder;

my $new_cyphertext = &encrypt ($new_plaintext, $key);
# print T "key=$key\nnew_plaintext=$new_plaintext\nnew_cyphertext=$new_cyphertext\n";
print "Content-type: text/plain\n\n$new_cyphertext";

close T;
exit 0;

#--------------------- infrastructure -----------------------------
sub ajax_utils {
	my $unquoted =  <<'EOT';

<SCRIPT LANGUAGE="JavaScript"> <!--
// ----- some Ajax stuff, from the O'Reilly book, with Tea_JS added -----
username = '';  key = '';  // global JS variables
function createXMLHttpRequest() {
	var request = false;
	if (window.XMLHttpRequest) {
		if (typeof XMLHttpRequest != 'undefined')
			try { request = new XMLHttpRequest();
			} catch (e) { request = false;
			}
	} else if (window.ActiveXObject) {
		try { request = new ActiveXObject('Msxml2.XMLHTTP');
		} catch (e) {
			try { request = new ActiveXObject('Microsoft.XMLHTTP');
			} catch (e) { request = false;
			}
		}
	} else {
		alert('createXMLHttpRequest: neither XMLHttpRequest'
		+ ' nor ActiveXObject exist');
	}
	return request;
}
function requestData(p_request, p_URL, p_data) {
	if (p_request) {
		p_request.open('POST', p_URL, true);
		p_request.onreadystatechange = parseResponse;
		p_request.send(p_data);
	} else {
		alert('requestData: p_request did not exist');
	}
}
function parseResponse () { // p. 76, 90, 100
	if (request.readyState != 4) { return; }
	if (!request.status || request.status != 200) {
		alert('There was a problem with the data: \n' + request.statusText);
		request = null;
		return;
	}
	document.getElementById('mainbody').innerHTML
	= decrypt(request.responseText, key);  // Crypt::Tea_JS
}
function get_params(p_formId) {  // p. 522
	var params = '';
	var form = document.getElementById(p_formId);
	var selects = form.getElementsByTagName('select');
	for (var i = 0, il = selects.length; i < il; i++) {
		params += ((params.length > 0) ? '&' : '')
		 + selects[i].id + '=' + select[i].value;
	}
	var inputs = form.getElementsByTagName('input');
	for (var i = 0, il = inputs.length; i < il; i++) {
		var type = inputs[i].getAttribute('type');
		if (type == 'text' || type == 'password' || type == 'hidden'
		 || (type == 'checkbox' && inputs[i].checked)) {
			params += ((params.length > 0) ? '&' : '')
			 + inputs[i].name + '=' + inputs[i].value;  // name or id
		} else if (type == 'radio' && inputs[i].checked) {
			params += ((params.length > 0) ? '&' : '')
			 + inputs[i].name + '=' + inputs[i].value;
		}
	}
	var textareas = form.getElementsByTagName('textarea');
	for (var i = 0, il = textareas.length; i < il; i++) {
		params += ((params.length > 0) ? '&' : '')
		 + textareas[i].id + '=' + textareas[i].innerHTML;
	}
	// Crypt::Tea_JS ...
	return "username="+username+"&cyphertext="+encrypt(params, key);
}
function myForm_onClick() {
	request  = createXMLHttpRequest();
EOT
	my $quoted = <<EOT;
	var URL  = '$ENV{SCRIPT_NAME}';
	requestData(request, URL, get_params('reportForm'))
	return false;
}
// -->
</SCRIPT>
EOT
	return $unquoted.$quoted;
}

__END__

=pod

=head1 NAME

tea_demo.cgi - CGI script to submit an encrypted form using Crypt::Tea_JS

=head1 SYNOPSIS

Move this script into a cgi-bin directory, make it executable,
and point a JavaScript-capable browser at it.

=head1 DESCRIPTION

This script should get you started in using Crypt::Tea_JS.
It demonstrates viewing encrypted page content,
and submitting encrypted form content.

Consult the source code, the Crypt::Tea_JS documentation,
and the View-Source button in your browser.

=head1 AUTHOR

Peter J Billam  www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

perldoc Crypt::Tea_JS,
http://www.pjb.com.au/comp/tea.html, perl(1).

=cut

