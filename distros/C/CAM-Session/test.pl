#!/usr/bin/perl -w

use warnings;
use strict;

BEGIN
{ 
   use Test::More tests => 42;
   use_ok("CAM::Session");
}

use DBI;

my %config = (
              dsn    => $ENV{DBI_DSN}   || "DBI:mysql:database=test",
              user   => $ENV{DBI_USER}  || "",
              pass   => $ENV{DBI_PASS}  || "",
              table  => $ENV{DBI_TABLE} || "test__session",
              cookie => "test_session",
              data   => {
                 name => "Chris",
                 lname => "Dolan",
                 1     => 2,
              },
              );

{
   my $warning = "";
   local $SIG{__WARN__} = sub {$warning = join("", @_)};

   is(CAM::Session->new(), undef, "Constructor failure");
   ok($warning =~ /database/i, "Test constructor failure: no dbh");

   is(CAM::Session->new("bogus dbh"), undef, "Constructor failure");
   ok($warning =~ /scalar/i, "Test constructor failure: bad dbh");

   is(CAM::Session->new(bless(["bogus dbh"],"BOGUS")), undef, "Constructor failure");
   ok($warning =~ /BOGUS/i, "Test constructor failure: bad dbh");
}

my $dbh = DBI->connect($config{dsn}, $config{user}, $config{pass},
                       {
                          RaiseError => 0,
                          PrintError => 0,
                          AutoCommit => 1,
                       });
SKIP: {
   if (!$dbh)
   {
      diag("Use the following settings to permit connections\n" .
           "  setenv DBI_DSN  DBI:mysql:database=test\n" .
           "  setenv DBI_USER testuser\n" .
           "  setenv DBI_PASS testpass\n");

      skip("Failed to connect to database. See advice above.",
           # Hack: get the number of tests we expect, skip all but one
           # This hack relies on the soliton nature of Test::Builder
           Test::Builder->new()->expected_tests() - 
           Test::Builder->new()->current_test());
   }

   $dbh->do("drop table $config{table}"); # don't care if it fails

   ok(CAM::Session->setDBH($dbh), "setDBH");
   ok(CAM::Session->setTableName($config{table}), "setTableName");
   ok(CAM::Session->setCookieName($config{cookie}), "setCookieName");
   ok(CAM::Session->setup(), "setup");
   ok(CAM::Session->clean(), "clean");

   my %data;
   my $session;
   my $newsession;
   my $cookie;
   my $cookiedata;

   $session = CAM::Session->new();
   ok($session, "new");
   ok($session->isNewSession(), "isNewSession");

   $cookie = $session->getCookie();
   ok($cookie, "getCookie");
   ok($cookie =~ /^$config{cookie}/, "getCookie");

   ($cookiedata = $cookie) =~ s/;.*//;
   ok($cookiedata, "extract data from cookie");

   {
      local *FILE;
      my $filename = "test.tmp$$";
      open(FILE, ">$filename") or die "Failed to write temp file $filename";
      local *STDOUT = *FILE;
      $session->printCookie();
      close FILE;
      open(FILE, "<$filename") or die "Failed to read temp file $filename";
      my $out = join("", <FILE>);
      close FILE;
      unlink($filename) or die "Failed to delete temp file $filename";

      is($out, "Set-Cookie: $cookie\n", "printCookie");
   }

   %data = $session->getAll();
   is(scalar keys %data, 0, "empty cookie");

   #warn $cookie,"\n";
   #warn $cookiedata,"\n";

   # Hack: pretend we just got this cookie
   $ENV{HTTP_COOKIE} = $cookiedata;

   $session = undef;
   $session = CAM::Session->new();
   ok($session, "restore");
   ok(!$session->isNewSession(), "not isNewSession");

   is_deeply({$session->getAll}, \%data, "still empty cookie");

   is($session->get(), undef, "bad get");
   is($session->set(undef, undef), undef, "bad get");

   ok($session->set(%{$config{data}}), "set");
   is($session->get("name"), $config{data}->{name}, "get");
   %data = $session->getAll();
   is_deeply(\%data, $config{data}, "getAll");

   $session = undef;
   $session = CAM::Session->new();
   ok($session, "restore filled cookie");
   %data = $session->getAll();
   is_deeply(\%data, $config{data}, "getAll");

   is_deeply(scalar($session->getAll()), scalar(keys %{$config{data}}), "getAll, scalar");

   ok($session->delete("lname"), "delete");
   delete $data{lname};
   is_deeply({$session->getAll}, \%data, "check deleted state");

   $session = undef;
   $session = CAM::Session->new();
   ok($session, "restore filled cookie");
   is_deeply({$session->getAll}, \%data, "getAll");
   ok($session->clear(), "clear");

   $session = undef;
   $session = CAM::Session->new();
   ok($session, "restore cleared cookie");
   ok(!$session->isNewSession(), "not isNewSession");
   is_deeply({$session->getAll}, {}, "getAll");

   ok(CAM::Session->setExpiration(1), "setExpiration (then pause for 2 seconds)");

   sleep(2);
   ok(CAM::Session->clean(), "clean");

   $session = undef;
   $session = CAM::Session->new();
   ok($session, "restore cleaned cookie");
   ok($session->isNewSession(), "isNewSession");

   $dbh->do("drop table $config{table}"); # don't care if it fails
}
