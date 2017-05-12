# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { 
	use_ok('Config::Frontend');
	use_ok('Config::Backend::INIREG');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### Regular tests

my $conf=new Config::Frontend(new Config::Backend::INIREG("ConfigBackendIniReg"));

$conf->set("test","HI=Yes");
$conf->set("test1","NO!\n\nYES?");
$conf->set("test2","Here's a problem");

ok($conf->get("test") eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
ok($conf->get("test1") eq "NO!\n\nYES?", "initial conf in \$string -> test1=NO!");
ok($conf->get("test2") eq "Here's a problem", "initial conf in \$string -> test2=Here's a problem");

$conf->set("section.oesterhol","account\naccount yes\nno?");
ok($conf->get("section.oesterhol") eq "account\naccount yes\nno?", "initial conf in \$string -> oesterhol=account");


### Look up all variables

{
  my %e;
  $e{"test"}=0;
  $e{"test1"}=0;
  $e{"test2"}=0;
  $e{"section.oesterhol"}=0;

  my @vars=$conf->variables();
  for my $var (@vars) {
    $e{$var}+=1;
  }

  my $all=1;
  for my $k (keys %e) {
    if ($e{$k}==0) {
      $all=0;
    }
  }

  ok($all==1,"variables: --> all variables are there");

  ### Reset conf item

  $conf->set("section.oesterhol","HI!");
  ok($conf->get("section.oesterhol") eq "HI!", "initial conf in \$string -> oesterhol=HI!");

  ### Delete a couple of keys

  $conf->del("section.oesterhol");
  $conf->del("test");
}

{
  my %e;
  $e{"test1"}=0;
  $e{"test2"}=0;

  my @vars=$conf->variables();
  for my $var (@vars) {
    $e{$var}+=1;
  }

  my $all=1;
  for my $k (keys %e) {
    if ($e{$k}==0) {
      $all=0;
    }
  }

  ok($all==1,"variables: --> all variables are there");
  ok((not defined $conf->get("test")),"deleted var not there");
  ok((not defined $conf->get("section.oesterhol")),"deleted var not there");
}



