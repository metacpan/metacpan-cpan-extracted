#!/usr/bin/perl
# Tiny CGI Testbed for seeing how memcache session storage works.
# Author: Olli Hollmen
# Runs from:
# - command line (testing memcache only, not CGI::Session for first tier
#   troubleshooting and seeing that memcached is up and running)
# - as CGI under (any?) web server to see whole CGI::Session stack at work
# Simulating CGI environment on command line for debugging:
# > export HTTP_HOST=localhost
# > perl -d memc_example.pl
# What to look for
# - Note the text "Hi from PID ...", where
#   - in CGI the PID should change
#   - in mod_perl PID is likely to stay same (on small request load)
# Dependencies:
# - Install Cache::Memcached or Cache::Memcached::Fast
# - Must install CGI::Session::Driver::memcache first !
use CGI;
use CGI::Session;
use Cache::Memcached;
# This Also works. Change also $memd constructor below
#use Cache::Memcached::Fast;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Sortkeys = 1;
use strict;
#use warnings;
use CGI::Carp qw(fatalsToBrowser);
# OLD:Pre-load memcache and TWEAK %INC to make CGI::Session and require think
# its loaded from proper location !!!
#use lib ('..');
#require('memcache.pm');
# %INC entry 'memcache.pm' => '../memcache.pm' is not enough
#$INC{'CGI/Session/Driver/memcache.pm'} = $INC{'memcache.pm'};
our $cgi;
our $sess;
our $memd;
#######################################################
# Detect web context, instantiate CGI request
if ($ENV{'HTTP_HOST'}) {$cgi = CGI->new();}
# Use pretty much any Perl memcache client API and connect to
# Memcached Server std. port: 11211
# See README for other perl clients (Such as Cache::Memcached::Fast)
$memd = $memd || new Cache::Memcached({
#$memd = $memd || new Cache::Memcached::Fast({
  servers => ['localhost:11211'],
  # 'serialize_methods' => [\&Storable::freeze, \&Storable::thaw],
});
if (!$memd) {die("No Connection to Memcached !");}


# NON-CGI Context (Command line)
if (!$cgi) {
  my $key = 'E1';
  #my $initval =  "Hello"; # {'foo' => 1}
  if (my ($val) = @ARGV) {my $ok = $memd->set($key, [$val]);} # $initval
  #if (!$ok) {die("Failed to set value !\n");}
  my $val = $memd->get($key);
  print("Value ('$key'): ".(ref($val) ? Dumper($val) : $val)."\n");
}
# CGI Running under Webserver
else {
  my $sid;
  #local 
  $CGI::Session::Driver::memcache::trace = 1;
  if (!$memd) {print("No memd connection\n");}
  # Execute store/retrieve/remove operations through memcached connection handle
  # passed at session construction (Never initiate memcache connections in driver).
  eval {
    $sess = CGI::Session->new("driver:memcache", $cgi, {'Handle' => $memd});
    
  };
  if (!$sess || $@) {
     #print CGI::header('text/html');
     die("Failed to create CGI::Session with memcache backend
     (CGI: $cgi, sess:$sess):\n$@");
  }
  my $mimeworkaround = 0;
  if ($mimeworkaround) {
    my ($name, $id, $time_s) = ($sess->name(), $sess->id(), $sess->expire(),);
    my $cookie = $cgi->cookie(
      -name=>$name, -value=>$id, -expires=> '+' . $time_s . 's',);
    print("Set-Cookie: ".$cookie->as_string()."\r\n");
    print("Content-type: text/html\r\n\r\n");
  }
  else {
    print $sess->header(); # Override for type: -type => 'text/plain'
  }
  $sid = $sess->id();
  #print CGI::header('text/html');
  
  my $runtime = $ENV{'MOD_PERL'} ? $ENV{'MOD_PERL'} : 'CGI';
  # Set
  $sess->param('K1', "Hi from PID $$ ($runtime) !");
  # Get
  my $v = $sess->param('K1');
  print("<p>Value of key K1 from Session: '$sid' is $v</p>");
  print("<p style=\"font-size: 11px;\">Enter ?debug=1 into URL to dump session,</p>");
  #DEBUG:print("Sample: $CGI::Session::Driver::memcache::memd_connerror\n\n");
  #DEBUG:print("<pre>".Dumper($sess)."</pre>");
  # MUST do flush(), the session is not persisted otherwise and a new session
  # is always created in absense of old session
  $sess->flush();
  # Dump all of $sess. Note only '_DATA' branch will be stored in
  # memcached backend side
  if ($cgi->param('debug')) {print("<pre>".Dumper($sess)."</pre>");}
}
