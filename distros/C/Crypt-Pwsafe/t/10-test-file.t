#!perl -T

use Test::More tests => 1;
use Crypt::Pwsafe;

my $key = "p3rlCryptPwsafe";
my $file = $0;
$file =~ s/[^\/]+$/test.psafe3/;
my $pwsafe = new Crypt::Pwsafe $file, $key;
ok(defined $pwsafe, "Constructor ok");
diag( "Testing Crypt::Pwsafe on test file $file" );
