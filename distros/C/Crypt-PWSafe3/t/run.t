#!perl -T
#
# testscript for Crypt::PWSafe3 Classes by T.v.Dein
#
# needs to be invoked using the command "make test" from
# the Crypt::PWSafe3 source directory.
#
# Under normal circumstances every test should succeed.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#

use Data::Dumper;
use Test::More tests => 13;
#use Test::More qw(no_plan);


my %params = (create => 0, password => 'tom');

my %record = (
	      user   => 'u3',
	      passwd => 'p3',
	      group  => 'g3',
	      title  => 't3',
	      notes  => 'n3'
	     );



sub rdpw {
  my $file = shift;
  my $vault = Crypt::PWSafe3->new(file => $file, %params) or die "$!";
  return $vault;
}

### 1
# load module
BEGIN { use_ok "Crypt::PWSafe3"};
require_ok( 'Crypt::PWSafe3' );

{
  # I'm going to replace the secure random number generator
  # backends with this very primitive and insecure one, because
  # these are only unit tests and because we use external modules
  # for the purpose anyway (which are not to be tested with these
  # unit tests).
  # This has to be done so that unit tests running on cpantesters
  # don't block if we use a real (and exhausted) random source,
  # which has reportedly happened in the past.
  # ***** CAUTION: DO NOT USE THIS CODE IN PRODUCTION. EVER. ****
  no warnings 'redefine';
  *Crypt::PWSafe3::random  = sub { return join'',map{chr(int(rand(255)))}(1..$_[1]); };
};

### 2
# open vault and read in all records
eval {
  my $vault = &rdpw('t/tom.psafe3');
  my @r = $vault->getrecords;
  my $got = 0;
  foreach my $rec (@r) {
    if ($rec->uuid) {
      $got++;
    }
  }
  if (! $got) {
    die "No records found in test database";
  }
};
ok(!$@, "open a pwsafe3 database ($@)");


### 1a
# create a new vault
my %rdata1a;
my $fd = File::Temp->new(TEMPLATE => '.myvaultXXXXXXXX', TMPDIR => 1, EXLOCK => 0) or die "Could not open tmpfile: $!\n";
my $tmpfile = "$fd";
close($fd);

eval {
  my $vault = Crypt::PWSafe3->new(file => $tmpfile, password => 'tom') or die "$!";
  $vault->newrecord(%record);
  $vault->save();
};
ok(!$@, "create a new pwsafe3 database ($@)");

eval {
  my $rvault1a = &rdpw($tmpfile);
  my $rec1a = ($rvault1a->getrecords())[0];
  foreach my $name (keys %record) {
    $rdata1a{$name} = $rec1a->$name();
  }
};
ok(!$@, "read created new pwsafe3 database ($@)");
is_deeply(\%record, \%rdata1a, "Write record to a new pwsafe3 database");
unlink($tmpfile);

### 3
# modify an existing record
my $uuid3;
my %rdata3;
my $rec3;

eval {
  my $vault3 = &rdpw('t/tom.psafe3');
  foreach my $uuid ($vault3->looprecord) {
    $uuid3 = $uuid;
    $vault3->modifyrecord($uuid3, %record);
    last;
  }
  $vault3->save(file=>'t/3.out');

  my $rvault3 = &rdpw('t/3.out');
  $rec3       = $rvault3->getrecord($uuid3);

  foreach my $name (keys %record) {
    $rdata3{$name} = $rec3->$name();
  }
};
ok(!$@, "read a pwsafe3 database and change a record, traditional method ($@)");
is_deeply(\%record, \%rdata3, "Change a record an check if changes persist after saving, traditional method");
diag("3 done\n");

### 3a
# modify an existing record, new method
my $uuid3a;
my %rdata3a;
my $rec3a;

eval {
  my $vault3a = &rdpw('t/tom.psafe3');
  foreach my $rec ($vault3a->getrecords) {
    $rec->notes('n3a');
    $uuid3a = $rec->uuid;
    last;
  }
  $vault3a->save(file=>'t/3a.out');

  my $rvault3a = &rdpw('t/3a.out');
  $rec3a       = $rvault3a->getrecord($uuid3a);
};
ok(!$@, "read a pwsafe3 database and change a record, new method ($@)");
is_deeply($rec3a->notes, 'n3a', "Change a record an check if changes persist after saving, new method");


### 4
# re-use $rec3 and change it the oop way
my $rec4;
eval {
  my $vault4 = &rdpw('t/tom.psafe3');
  $rec4      = $vault4->getrecord($uuid3);

  $rec4->user("u4");
  $rec4->passwd("p4");

  $vault4->addrecord($rec4);
  $vault4->markmodified();
  $vault4->save(file=>'t/4.out');

  my $rvault4 = &rdpw('t/4.out');
  $rec4 = $rvault4->getrecord($uuid3);
  if ($rec4->user ne 'u4') {
    die "oop way record change failed";
  }
};
ok(!$@, "re-use record and change it the oop way\n" . $@ . "\n");


### 5 modify some header fields
eval {
  my $vault5 = &rdpw('t/tom.psafe3');

  my $h3 = new Crypt::PWSafe3::HeaderField(name => 'savedonhost', value => 'localhost');

  $vault5->addheader($h3);
  $vault5->markmodified();
  $vault5->save(file=>'t/5.out');

  my $rvault5 = &rdpw('t/5.out');

  if ($rvault5->getheader('savedonhost')->value() ne 'localhost') {
    die "header savedonhost not correct";
  }
};
ok(!$@, "modify some header fields ($@)");

### 6 delete
eval {
  my $vault6 = &rdpw('t/3.out');
  my $uuid      = $vault6->newrecord(user => 'xxx', passwd => 'y');
  $vault6->save(file=>'t/6.out');

  my $rvault6 = &rdpw('t/6.out');
  my $rec = $rvault6->getrecord($uuid);
  if ($rec->user ne 'xxx') {
    die "oop way record change failed";
  }
  $rvault6->deleterecord($uuid);
  if ($rvault6->getrecord($uuid)) {
      die "deleted record still present in open vault";
  }
  $vault6->save(file=>'t/6a.out');

  my $rvault6a = &rdpw('t/6a.out');
  if ($rvault6->getrecord($uuid)) {
      die "deleted record reappears after save and reload";
  }
};
ok(!$@, "delete record\n" . $@ . "\n");


### clean temporary files
unlink('t/3.out');
unlink('t/4.out');
unlink('t/5.out');
unlink('t/6.out');
unlink('t/6a.out');
