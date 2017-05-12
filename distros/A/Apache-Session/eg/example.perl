######################################################################
#
# Consult the documentation before trying to run this file.
# You need a /tmp directory or you need to change the Directory option!
# This file also assumes PerlSendHeader Off.
#
######################################################################

use strict;
use Apache;
use CGI;
use Apache::Session::File;

my $r = Apache->request();

$r->status(200);
$r->content_type("text/html");
$r->send_http_header;

my $session_id = $r->path_info();
$session_id =~ s/^\///;

$session_id = $session_id ? $session_id : undef;

my %session;
my $opts = { Directory => '/tmp', LockDirectory => 'tmp', Transaction => 1 };

tie %session, 'Apache::Session::File', $session_id, $opts;

my $input = CGI::param('input');
$session{name} = $input if $input;

print<<__EOS__;

Hello<br>
Session ID number is: $session{_session_id}<br>
The Session ID is embedded in the URL<br>
<br>
Your input to the form was: $input<br>
Your name is $session{name}<br>

<br>
<a href="http://localhost/example.perl/$session{_session_id}">Reload this session</a><br>
<a href="http://localhost/example.perl">New session</a>

<form action="http://localhost/example.perl/$session{_session_id}" method="post">
  Type in your name here:
  <input name="input">
  <input type="submit" value="Go!">
</form>
__EOS__
