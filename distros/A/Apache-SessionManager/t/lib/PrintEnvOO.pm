package PrintEnvOO;

require 5.005;
use strict;
use Data::Dumper;

use vars qw($VERSION);
$VERSION = '0.2';

use mod_perl;
use constant MP2 => ($mod_perl::VERSION >= 1.99);

BEGIN {
	# Test mod_perl version and use the appropriate components
	if (MP2) {
		require Apache::Const;
		Apache::Const->import(-compile => qw(OK));
		require Apache::RequestRec;
		require Apache::RequestIO;
		require CGI;
		CGI->import(qw(:cgi-lib));
	}
	else {
		require Apache::Constants;
		Apache::Constants->import(qw(OK));
	}
}

sub handler {
	my $r = new Apache::SessionManager(shift);
	my $session = $r->get_session;
	my $str;

	# Main output
   $str = <<EOM;
<HTML>
<HEAD><TITLE>mod_perl Apache::SessionManager test module</TITLE></HEAD>
<BODY BGCOLOR="#FFFFFF">
<CENTER><H1>mod_perl Apache::SessionManager test module</H1></CENTER>
<TABLE>
	<TR>
		<TD>
<FORM METHOD="GET">
	<INPUT TYPE="text" NAME="delete_session_param">
	<INPUT TYPE="submit" VALUE="Reload">
</FORM>
		</TD>
		<TD>
<FORM METHOD="GET">
	<INPUT TYPE="hidden" NAME="delete_session" VALUE="1">
	<INPUT TYPE="submit" VALUE="Delete session next time">
</FORM>
		</TR>
	</TD>
</TABLE>
EOM

	# Get CGI params
	my $form = (MP2) ? { Vars } : { $r->args() };
	
	# Delete session value (if any) OO interface
	$r->delete_session_param($form->{delete_session_param});

	# Get session values
	$str .= '<PRE>' . Data::Dumper::Dumper($session) . '</PRE>';

	# Get session values, OO interface I
	$str .= '<PRE>' . Data::Dumper::Dumper($r->{'session'}) . '</PRE>';

	# Get session values, OO interface II
	$str .= '<PRE>' . "@{ [ $r->get_session_param ] }" . '</PRE>';
	$str .= '<PRE>' . join(', ',$r->get_session_param) . '</PRE>';

	# Get session values, OO interface II
	my $param = $r->get_session_param('_session_id');
	$str .= '<PRE>' . $param . '</PRE>';
	
#	$str .= HashVariables($session,'<H2>Session Dump</H2>');
	$str .= HashVariables(\%INC,'<H2>%INC</H2>');
	$str .= HashVariables($r->subprocess_env,'<H2>Environment variables</H2>');
	$str .= HashVariables(MP2 ? $r->headers_in() : { $r->headers_in() },'<H2>HTTP request headers</H2>');
	$str .= "</BODY>\n</HTML>";
	
	# set session value
	$session->{rand()} = rand;

	# set session values, OO interface
	$r->set_session_param( param1 => rand(), param2 => rand() );

	# Destroy session, OO interface
	$r->destroy_session if $form->{delete_session} eq '1';

   # Output code to client
   $r->content_type('text/html');
   MP2 ? 1 : $r->send_http_header;
   $r->print($str);
   return MP2 ? Apache::OK : Apache::Constants::OK;
}

sub HashVariables {
	my($hash,$topic) = @_;
   my $str = $topic;
   foreach(sort keys %$hash) {
      $str .= "<B>$_</B> = $$hash{$_}<BR>\n";
   }
   return $str;
}
