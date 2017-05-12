# $Id: test.pl,v 1.3 1997/09/19 16:40:03 carrigad Exp $

# Copyright (C), 1997, Interprovincial Pipe Line Inc.

END {print "not ok 1\n" unless $loaded;}

use Authen::ACE;
$loaded = 1;
$| = 1;

my $readkey = 0;
eval "use Term::ReadKey";
if ($@) {
  print "\n";
  print "WARNING!!! Could not find the Term::ReadKey module.\n";
  print "WARNING!!! You will have to enter some passwords in the clear.\n";
  print "WARNING!!! Use caution when running these tests!!\n";
  print "\nPress return to get started: ";
  <>;
  eval "sub ReadMode {}";
} else {
  $readkey = 1;
}

$testpin = "123456";
$myshell = "/bin/ksh";
eval 'require ".testparms"';
getparms();

print "ok 1\n"; $npass++;

eval {$ace = new Authen::ACE("config" => "/var/ace")};
if ($@) {
  print "not ok 2\n";
  die $@;
}
print "ok 2\n"; $npass++;

$testno=3;

print "Enter the PIN+token for your SecurID card. ";
($result, $shell) = $ace->Auth();
printok($testno++, $result == ACM_OK, "failed Authen::ACE::Auth");
printok($testno++, $shell eq $myshell, "unexpected shell $shell");

print "Enter an invalid PIN/token for your SecurID card. ";
($result,$shell) = $ace->Auth();
printok($testno++, $result == ACM_ACCESS_DENIED, 
	"expected `access denied' from Authen::ACE::Auth");

print "Enter the PIN+token for ${testuser}'s SecurID card. ";
($result, $shell) = $ace->Auth($testuser);
printok($testno++, $result == ACM_OK, "failed Authen::ACE::Auth for $testuser");

$username = (getpwuid($<))[0];
print "Wait for your SecurID card's token to change; press Enter to continue "; <>;
print "Re-enter the PIN+token for your SecurID card: ";
ReadMode(2);
$pass = <>;
ReadMode(0);
print "\n";
chomp $pass;
($result,$shell) = $ace->Check($pass, $username);
printok($testno++, $result == ACM_OK, "failed Authen::ACE::Check");
printok($testno++, $shell == $myshell, "unexpected shell $shell");

($result,$shell) = $ace->Check("invalid", $username);
printok($testno++, $result == ACM_ACCESS_DENIED, 
	"expected `access denied' for Authen::ACE::Check");

if ($pinuser ne "") {
  print "Wait for the ${pinuser}'s token to change; press Enter to continue "; <>;
  print "Clear ${pinuser}'s PIN on the ACE server, then enter the token from his card: ";
  $pass = <>;
  chomp $pass;
  ($result,$np) = $ace->Check($pass, $pinuser);

  printok($testno++, $result == ACM_NEW_PIN_REQUIRED,
	 "expected `new pin required' result");
  die "Can't continue tests.\n" unless $result == ACM_NEW_PIN_REQUIRED;

  printok($testno++, $np->{"system_pin"} ne "",
	 "system PIN didn't get set");
  printok($testno++, $np->{"min_pin_len"} > 0,
	 "min pin length was <= 0");
  printok($testno++, $np->{"max_pin_len"} > $np->{"min_pin_len"} &&
	  $np->{"max_pin_len"} <= 8,
	 "max pin length was < min pin length or > 8");

  if ($np->{"user_selectable"} eq CANNOT_CHOOSE_PIN) {
    $testpin = $np->{"system_pin"};
  } else {
    if ($np->{"min_pin_len"} > length($testpin)) {
      $missing = $np->{"min_pin_len"} - length($testpin);
      $testpin .= ("0" x $missing);
    }
    if ($np->{"max_pin_len"} < length($testpin)) {
      $testpin = substr($testpin, 0, $np->{"max_pin_len"});
    }
  }
  $result = $ace->PIN($testpin);
  printok($testno++, $result == ACM_NEW_PIN_ACCEPTED,
	 "expected `new PIN accepted' result");
  die "Can't continue tests.\n" unless $result == ACM_NEW_PIN_ACCEPTED;

  print "${pinuser}'s new PIN is ``$testpin''\n";
  print "Wait for the ${pinuser}'s token to change; press Enter to continue "; <>;
  print "Re-enter ${pinuser}'s PIN+token. ";
  ($result,$shell) = $ace->Auth($pinuser);
  printok($testno++, $result == ACE_OK,
	 "Authen::ACE::Auth failed with new PIN+token");
}

# Make sure DESTROY works
eval {undef $ace};
printok($testno++, $@ eq "", "Authen::ACE destructor failed");
die $@ if $@; 

$testno--;
if ($npass == $testno) {
  print "All tests successful.\n";
} else {
  printf "Passed $npass/$testno tests, %.2f%% okay\n", $npass/$testno * 100;
  print "Failed tests may have been due to mis-entered tokens or PINs.\n";
}

sub printok {
  my ($n, $ok, $message) = @_;
  print($ok? "ok $n\n" : "not ok $n ($message)\n");
  $npass++ if $ok;
}

sub getparms {
  my $ans;

  print "\nI need some information before I can run the tests\n";
  print "Enter the shell defined for your SecurID account";
  print " [$myshell]" if $myshell ne "";
  print ": ";
  $ans = <>; chomp $ans;
  $myshell = $ans unless $ans eq "";

  print "Enter the username of user to use for the PIN setting tests";
  print " [$pinuser] (NONE to disable)" if $pinuser ne "";
  print ": ";
  $ans = <>; chomp $ans;
  $pinuser = $ans unless $ans eq "";
  $pinuser = "" if $ans eq "NONE";

  $testuser = ($pinuser eq "")? (getpwuid($>))[0] : $pinuser;
  print "Enter the username to use for the named user tests";
  print " [$testuser]" if $testuser ne "";
  print ": ";
  $ans = <>; chomp $ans;
  $testuser = $ans unless $ans eq "";

  if (open(TP, ">.testparms")) {
    print TP "\$myshell = \"$myshell\";\n";
    print TP "\$testuser = \"$testuser\";\n";
    print TP "\$pinuser = \"$pinuser\";\n";
    close TP;
  } else {
    warn "Counldn't save test parameters to .testparms: $!\n";
  }
  print "Thankyou.\n\n";
}
