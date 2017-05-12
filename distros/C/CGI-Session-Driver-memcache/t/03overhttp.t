# Run Perl HTTP::Server::Simple (port 8088) to test sessions with.
# Depends on:
# - Memcached running on 'localhost' or $ENV{'MEMCACHED_HOST'}
# - Module HTTP::Server::Simple being installed (In Debian Install: libhttp-server-simple-perl, or do: cpan HTTP::Server::Simple)
# Env variables supported for testing
# - ALLOW_HTTPD_RUN - allow HTTP::Server::Simple to run for extended period (secs.) for browser testing
# - MEMCACHED_HOST - Use Memcached on host other than localhost
# - HTTP_DEBUG - Produce extremely verbose (and dump-cluttered) output
use Test::More;
use lib '..';
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Sortkeys = 1;
#use Scalar::Util;

use memcache;
# Allow HTTP::Server::Simple to run longer for some browser testing
my $sleeptime = $ENV{'ALLOW_HTTPD_RUN'} || 1;
our $port = 8088;
#our $sesskey = 'CGISESSID'; # Parametrize, try another ?
our $memdhost = $ENV{'MEMCACHED_HOST'} || 'localhost';
# Check dependencies
eval("use HTTP::Server::Simple;");
if ($@) {plan('skip_all', "HTTP::Server::Simple not installed !");}
eval("use WWW::Mechanize;");
if ($@) {plan('skip_all', "WWW::Mechanize not installed !");}

#ok(1, "Hi");
# Trick CGI::Session / require() before module is installed into final Perl install location.
# (CGI::Session is picky about absolute module path)
if (!$INC{'CGI/Session/Driver/memcache.pm'}) {
   $INC{'CGI/Session/Driver/memcache.pm'} = $INC{'memcache.pm'};
}
eval("use HTTP::Server::Simple::CGI;");
if ($@) {plan('skip_all', "HTTP::Server::Simple::CGI not installed !");}
eval("use Cache::Memcached;");
if ($@) {plan('skip_all', "Cache::Memcached not installed !");}
eval("use CGI::Session;");
if ($@) {plan('skip_all', "CGI::Session not installed !");}
#######################
plan('tests', 27); # 9, 15,25
ok($HTTP::Server::Simple::VERSION, "Loaded HTTP::Server::Simple ($HTTP::Server::Simple::VERSION)");
ok($HTTP::Server::Simple::CGI::VERSION, "Loaded HTTP::Server::Simple::CGI ($HTTP::Server::Simple::CGI::VERSION)");
# Additionally (or earlier before plan)
#SEE eval above use_ok('Cache::Memcached');
use_ok('CGI');
# Web server PID
#our $cpid;

{
   $|=1;
   package MockServer;
   use Test::More;
   #use HTTP::Server::Simple::CGI;
   use Data::Dumper;
   our $cpid = 0;
   #ok($HTTP::Server::Simple::CGI::VERSION, "Loaded HTTP::Server::Simple::CGI v. $HTTP::Server::Simple::CGI::VERSION");
   # Load this late enough as "driver-loaded" %INC trick needs to be in place before this
   #use_ok('CGI::Session');
   ok($CGI::Session::VERSION, "Loaded CGI::Session v. $CGI::Session::VERSION");
   #use base ('HTTP::Server::Simple::CGI');
   our @ISA = ('HTTP::Server::Simple::CGI');
   use_ok('Cache::Memcached');
   my $verb = $ENV{'HTTP_DEBUG'};
   note("Connect HTTP::Server::Simple to memcached and test connection");
   my $memd = Cache::Memcached->new({
      'servers' => [ "$memdhost:11211" ], 'debug' => 0,
   });
   ok($memd, "Connected to Memcached server (on '$memdhost')");
   # Detect that Memcached is REALLY up and running !
   # (Valid $memd seems to be returned in any case)
   my $testval = "t8ime_is_".time();
   my $okset = $memd->set("testkey", $testval);
   ok($okset, "Memcached test: Set testkey");
   my $tval = $memd->get("testkey") || ''; # Avoid warnings
   my $okmemd = ok($tval eq $testval, "Memcached test: Compared testkey (between set/get)");
   if (!$okmemd) {die("Memcached NOT Accessible, no use going further with tests");}
   my $stats = $memd->stats();
   #if ($verb) {
     print(Dumper($stats));
   #}
   ok(ref($stats), "Double-check: got cache stats from memcached");
   ok($stats->{'total'}->{'total_connections'} > 0, "Double-check: connections > 0 ($stats->{'total'}->{'total_connections'})");
   # Note - do not run ok() tests here as they would be running in the OS sub-process (concurrently with both
   # concurrency and output redirection causing problems and Test::More book-keeping in main process ignoring them)
   sub handle_request {
     my ($self, $cgi) = @_;
     my $path = $cgi->path_info();
     print("HTTP/1.0 200 OK\r\n");
     # CGI::Session->name("MY_SID");
     #$CGI::Session::IP_MATCH = 1;
     # Note: extra 4th param (hashref) can contain 'name' for app specific
     # Session ID / Cookie key name label (i.e. not CGISESSID)
     my $sess = CGI::Session->new("driver:memcache;serializer:default", $cgi, {'Handle' => $memd}); # {'name' => 'MYCGISESSID',}
     $sess->expire("40h");
     my $exp = $sess->is_expired();
     my $emp = $sess->is_empty();
     #$sess->flush();
     my $cname = $sess->name();
     my $id = $sess->id(); # From: $sess->{'_DATA'}->{'_SESSION_ID'};
     
     # Rest of the code to complete outgoing HTTP headers
     my $cinfo = " Path=/; Expires=Wed, 13 Jan 2021 22:23:01 GMT; Secure; HttpOnly";
     #print("Content-type: text/html\r\n");
     #print("Set-Cookie: CGISESSID=$id; $cinfo\r\n");
     print $sess->header();
     print("\r\n");
     print("<style>p {font-size: 11px;} pre {font-size: 9px;}</style>");
     if ($verb) {print("<p>Got called w. '$path' ($memd / $sess / $cname=$id / EXP=$exp/EMP=$emp)</p>\n");} # 
     print($sess->param('lastURL') ? $sess->param('lastURL') : 'HAVE-NO-URL');
     #print("<p>Set CGISESSID to '$id'</p>\n");
     $sess->param('lastURL', $path);
     if ($verb) {
       print("\n\n<pre>".Dumper($sess)."</pre><hr>");
       #print("SESSKEY: $CGI::Session::NAME\n");
       print("\n\n<pre>".Dumper($cgi)."</pre>");
     }
     # FLUSH (is this too late ?)
     $sess->flush();
     0;
   }
   
   $cpid = MockServer->new($port)->background();
   #my $cpid = $server->background()
   #NA:$server->run();
   ok($cpid, "Started up HTTP Server for testing (PID: $cpid)");
   #isa_ok($server, 'HTTP::Server::Simple');
}

##### CLIENT ###########
my $url = "http://localhost:$port/foo";
note("Use WWW::Mechanize HTTP Client to test session creation");
use_ok('WWW::Mechanize');
my $mech = WWW::Mechanize->new('keep_alive' => 1, 'cookie_jar' => {});
ok($mech, "Launched HTTP User agent to test with (Mechanize: $WWW::Mechanize::VERSION)");
sub cont4url {
   my ($mech, $url) = @_;
   #note("Call URL: $url");
   my $resp = $mech->get($url);
   ok($resp, "Got resp: $resp");
   my $cont = $resp->content();
   my $len = length($cont);
   ok($cont, "Got Content ($len B)");
   # Detect presence of cookie
   my $c = $resp->header('set-cookie');
   #DEBUG:print($c);
   ok($c, "Server IS trying to set a cookie (by set-cookie)");
   ok($c =~ /\bCGISESSID\b/, "Cookie is about Session (matched session key)");
   return($cont);
}
my $cont;
$cont = cont4url($mech, $url);
$cont = cont4url($mech, $url.'bar');
$cont = cont4url($mech, $url.'bax');

if ($sleeptime > 2) {note("You have $sleeptime s. reserved for browser testing (by ALLOW_HTTPD_RUN)");}
sleep($sleeptime); # To allow testing the server
#### END #######
my $cpid = $MockServer::cpid;
ok($cpid, "HTTP Server PID Accessible: $cpid");
my $okk = kill(9, $cpid);
ok($okk, "Killed Temporary HTTP Server OK");
note("Set ALLOW_HTTPD_RUN=numsecs to do Browser further testing.");
