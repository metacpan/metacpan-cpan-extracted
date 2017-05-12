#!perl -T
# $Id: 55-authsimple.t,v 1.1 2008/05/01 22:37:09 pauldoom Exp $

use Test::More tests => 5;

my $testpwf = "t/conf/junk.passwd";

SKIP: {
    eval { require Authen::Simple; require Authen::Simple::Passwd };

    skip "Authen::Simple and/or Authen::Simple::Passwd not installed", 5 if $@;
    
    use_ok ( 'Apache::AppSamurai::AuthSimple' );

    diag( "Testing Apache::AppSamurai::AuthSimple $Apache::AppSamurai::AuthSimple::VERSION, Perl $], $^X" );

    my $conf = {SubModule => "Passwd", path=>$testpwf};

    my $a;

    ok($a = Apache::AppSamurai::AuthSimple->new(%{$conf}), "Create new AuthSimple object");

    ok($a->Authenticate("moron", "moron"), "Login with correct username and password suceeded");

    ok(!$a->Authenticate("dufus", "notit"), "Login with valid username but wrong password failed");

    ok(!$a->Authenticate("noguy", "wha?"), "Login with nonexistent username failed");

}
