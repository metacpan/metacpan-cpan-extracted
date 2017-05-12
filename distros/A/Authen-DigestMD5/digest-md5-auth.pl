#!/usr/local/bin/perl

use warnings;
use strict;

use OpenLDAP;
use Authen::DigestMD5;

use Getopt::Std;
our ($opt_h, $opt_U, $opt_R, $opt_w, $opt_d);
getopts("h:U:R:w:d");

my $host=$opt_h || 'localhost';
my $realm=$opt_R || 'demo';
my $user=$opt_U || 'test';
my $passwd=$opt_w or die "password missing\n";

sub dbg { $opt_d and print STDERR @_, "\n" };

my ($ld, $rc, $id, $msg, $req);
$ld=OpenLDAP::Client->new($host);
($rc, $id)=$ld->sasl_bind(undef, 'DIGEST-MD5');
dbg "sasl_bind: $rc $id";

($rc, $msg)=$ld->result($id);
dbg "result: $rc $msg";

($rc, $req)=$ld->parse_sasl_bind_result($msg);
dbg "parse_sasl_bind_result: $rc";

dbg "IN: |$req|";
my $request=Authen::DigestMD5::Request->new($req);

my $response=Authen::DigestMD5::Response->new;
$response->got_request($request);
$response->set(username => $user,
	       realm => $realm,
	       'digest-uri' => "ldap/$host");
$response->add_digest(password=>$passwd);

my $res=$response->output;


dbg "OUT: |$res|";

($rc, $id)=$ld->sasl_bind(undef, 'DIGEST-MD5', $res);
dbg "sasl_bind: $rc $id";

($rc, $msg)=$ld->result($id);
dbg "result: $rc $msg";

($rc, $req)=$ld->parse_sasl_bind_result($msg);
dbg "parse_sasl_bind_result: $rc, $req";

$request->input($req);


print $request->auth_ok ? "AUTH OK\n" : "AUTH FAILED\n"
