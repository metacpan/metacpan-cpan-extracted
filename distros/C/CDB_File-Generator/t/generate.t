#!/usr/bin/perl -w

BEGIN {print "1..12\n"}
END {print "not ok 1\n" unless $loaded;}

use Carp;
use CDB_File::Generator;
$loaded=1;

sub ok ($) {my $t=shift; print "ok $t\n";}
sub nogo () {print "not "}

#unlink any existing my.cdb
(! (-e "my.cdb") or unlink "my.cdb")
   or die "Couldn't get rid of the existing database";
$gen = new CDB_File::Generator "my.cdb" or nogo;
ok(1);
@keyval = 
  ( en => "Hello",
    us => "hi",
    us => "howdy",
    us => "yo",
    oz => "g'day",
  );

@checkval = 
  ( en => "Hello",
    oz => "g'day",
    us => "hi",
    us => "howdy",
    us => "yo",
  );


while (@keyval) {
  my ($key, $value) = splice (@keyval, 0 , 2);
  $gen->add($key,$value);
}

ok(2);
$gen->finish;
undef $gen;
-e 'my.cdb' or nogo;
ok(3);

use CDB_File 0.86;
use vars qw($tst);

$tst = tie %test_hash, "CDB_File", "my.cdb" or nogo;
ok(4);

$test_hash{"en"} eq "Hello" or nogo;
ok(5);

$test_hash{"us"} eq "hi" or nogo;
ok(6);

# this assumes a version of CDB_File which handles multiple keys by
# iterating to the next one.  On version 0.5 this test WILL FAIL.

use vars qw($a);
$a = scalar keys %test_hash;
my ($key, $value);
while ( ($key, $value) = each %test_hash ){
  my ($ckey, $cvalue) = splice (@checkval, 0, 2);
  unless ($key eq $ckey and $value eq $cvalue) {
    print "not ";
    last;
  }
}
ok(7);

#unlink any existing my.cdb
(! (-e "your.cdb") or unlink "your.cdb")
   or die "Couldn't get rid of the existing database your.cdb";
$gen2 = new CDB_File::Generator "your.cdb" or nogo;

ok(8);

@keyval2 =
  ( "aa" => "second",
    "a." => "first",
  );

@checkval2 =
  ( "a." => "first",
    "aa" => "second",
  );

while (@keyval2) {
  my ($key, $value) = splice (@keyval2, 0 , 2);
  $gen2->add($key,$value);
}

ok(9);
$gen2->finish;
undef $gen2;
-e 'my.cdb' or nogo;
ok(10);

use vars qw($tst2);

$tst2 = tie %test_hash2, "CDB_File", "your.cdb" or nogo;
ok(11);

while ( my ($key, $value) = each %test_hash2 ){
  my ($ckey, $cvalue) = splice (@checkval2, 0, 2);
  unless ($key eq $ckey and $value eq $cvalue) {
    print "not ";
    last;
  }
}
ok(12);
