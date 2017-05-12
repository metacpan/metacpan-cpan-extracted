# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { 
  use_ok('Config::Frontend');
  use_ok('Config::Backend::SQL');
}
;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

### Regular tests

my $DSN=$ENV{"DSN"};
my $DBUSER=$ENV{"DBUSER"};
my $PASS=$ENV{"DBPASS"};
my $TABLE="test_conf";

SKIP: {

  skip "I cannot test this module properly without \$DSN, \$DBUSER and \$DBPASS".
       "environment variables. Set ".
       "these variables to proper values.", 9 unless ($DSN);

  my $conf=new Config::Frontend(new Config::Backend::SQL(DSN => $DSN,DBUSER => $DBUSER,DBPASS => $PASS, TABLE => $TABLE));

  $conf->set("test","HI=Yes");
  $conf->set("test1","NO!");
  $conf->set("test2","Here's a problem");

  ok($conf->get("test") eq "HI=Yes", "initial conf in \$string -> test=HI=Yes");
  ok($conf->get("test1") eq "NO!", "initial conf in \$string -> test1=NO!");
  ok($conf->get("test2") eq "Here's a problem", "initial conf in \$string -> test2=Here's a problem");

  $conf->set("oesterhol","account");
  ok($conf->get("oesterhol") eq "account", "initial conf in \$string -> oesterhol=account");


  ### Look up all variables

  my %e;
  $e{"test"}=0;
  $e{"test1"}=0;
  $e{"test2"}=0;
  $e{"oesterhol"}=0;

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

  $conf->set("oesterhol","HI!");
  ok($conf->get("oesterhol") eq "HI!", "initial conf in \$string -> oesterhol=HI!");

  ### Delete a couple of keys

  $conf->del("oesterhol");
  $conf->del("test1");

  undef %e;
  my %e;
  $e{"test"}=0;
  $e{"test2"}=0;

  undef @vars;
  my @vars=$conf->variables();
  for my $var (@vars) {
    $e{$var}+=1;
  }

  undef $all;
  my $all=1;
  for my $k (keys %e) {
    if ($e{$k}==0) {
      $all=0;
    }
  }

  ok($all==1,"variables: --> all variables are there");
  ok((not defined $conf->get("test1")),"deleted var not there");
  ok((not defined $conf->get("oesterhol")),"deleted var not there");


  ### Cleanup

  my $dbh=DBI->connect($DSN,$DBUSER,$PASS);
  my $driver=lc($dbh->{Driver}->{Name});

  print "driver:$driver\n";

  if ($driver eq "pg") {
    $dbh->do("DROP INDEX $TABLE"."_idx");
    $dbh->do("DROP TABLE $TABLE");
  } elsif ($driver eq "mysql") {
    $dbh->do("DROP INDEX $TABLE"."_idx ON $TABLE");
    $dbh->do("DROP TABLE $TABLE");
  } elsif ($driver eq "sqlite") {
    $dbh->do("DROP INDEX $TABLE"."_idx");
    $dbh->do("DROP TABLE $TABLE");
  } else {			# Hope for the best
    $self->{"dbh"}->{"PrintError"}=0;
    $dbh->do("DROP INDEX $TABLE"."_idx");
    $dbh->do("DROP TABLE $TABLE");
  }

  $dbh->disconnect();

}
