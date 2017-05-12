BEGIN { $| = 1; print "1..1\n"; }

use utf8;
use strict;

use Database::Sophia;

my $env = Database::Sophia->sp_env();

my $err = $env->sp_ctl(SPDIR, SPO_CREAT|SPO_RDWR, "./db");
die $env->sp_error() if $err == -1;

my $db = $env->sp_open();
die $env->sp_error() unless $db;

$err = $db->sp_set("login", "lastmac");
print $db->sp_error(), "\n" if $err == -1;

my $value = $db->sp_get("login", $err);

if($err == -1) {
	print $db->sp_error(), "\n";
}
elsif($err == 0) {
	print "Key not found", "\n";
}
elsif($err == 1) {
	print "Key found", "\n";
	print "login: ", $value, "\n";
}

$db->sp_destroy();
$env->sp_destroy();

print "ok 1\n";
