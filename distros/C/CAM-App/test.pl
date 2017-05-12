BEGIN
{ 
   use Test::More tests => 15;

   use lib qw(example);  # Be sure to include SampleConfig properly
   use_ok(CAM::App);
   use_ok(SampleConfig); # Just to make sure there aren't any syntax errors
}

use strict;

package junk1;
use vars qw($VERSION);
$VERSION = 1.00;

package junk2;
use vars qw(@ISA);
@ISA = qw(CAM::App);

package main;


my $app = CAM::App->new(cgi => undef);
ok($app, "new");

ok($app->loadModule("junk1"), "loadModule");
ok($app->loadModule("junk2"), "loadModule");
ok(!$app->loadModule("no::such::module"), "loadModule");

ok(!$app->getCGI(), "getCGI (none)");
ok(!$app->getDBH(), "getDBH (none)");
is($app->header(), "Content-Type: text/html\n\n", "header (no cgi)");
is($app->header(), "", "header repeat (no cgi)");

local *FILE;
open(FILE, "<$0");
my $script = join('', <FILE>);
close FILE;
ok($script, "read in test file");

my $tmpl;
ok($tmpl = $app->getTemplate(), "getTemplate (no file)");
ok($tmpl = $app->getTemplate("test.pl"), "getTemplate (test file)");
$tmpl->setParams(such => "::such::"); # fix for accidental substitution
is($tmpl->toString(), $script, "template toString");

SKIP: {
   if (!$app->loadModule("CAM::EmailTemplate"))
   {
      skip("CAM::EmailTemplate not installed", 1);
   }
   ok($tmpl = $app->getEmailTemplate(), "getEmailTemplate (no file)");
}
