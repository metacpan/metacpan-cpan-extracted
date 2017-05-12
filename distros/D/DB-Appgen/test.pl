# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

sub tprint
{ my $name=shift;
  print $name,('.' x ((30-length($name))>0 ? 30-length($name) : 0));
  my $value=shift;
  print $value ? 'ok' : 'not ok';
  print "\n";
}

#################################################################################

BEGIN { $| = 1; }
END { tprint("loading", 0) unless $loaded;}
use DB::Appgen;
$loaded = 1;
tprint "loading",1;

#################################################################################

unlink('test.db');

my $db=new DB::Appgen(file => 'test.db', create => 1);

tprint "new(create => 1)", $db;

tprint "close", $db->close;

$db=new DB::Appgen(file => 'test.db');

tprint "new", $db;

tprint "unlock", $db->unlock($db);

tprint "lock", $db->lock($db);

tprint "seek(create => 1)", $db->seek(key => 'Test', create => 1);

tprint "insert", $db->insert(attribute => 1, value => 2, text => 'Test Data 1-2');
tprint "insert", $db->insert(attribute => 2, value => 3, text => 'Test Data 2-3');

tprint "commit", $db->commit;

tprint "release", $db->release;

tprint "seek(QQ)", ! $db->seek(key => 'QQQ');

tprint "seek(Test)", $db->seek(key => 'Test', lock => 1);

my $str=$db->extract(attribute => 1, value => 2, size => 8);
tprint "extract(1,2,8)", $str eq 'Test Dat';

$str=$db->extract(attribute => 2, value => 3);
tprint "extract(2,3)", $str eq 'Test Data 2-3';

$str=$db->extract(attribute => 22, value => 33);
tprint "extract(22,33)", ! defined($str);

tprint "insert", $db->insert(attribute => 3, value => 4, text => 'Test Data 3-4');

$str=$db->extract(attribute => 3, value => 4);
tprint "extract(3,4)", $str eq 'Test Data 3-4';

tprint "release", $db->release;

$str=$db->extract(attribute => 3, value => 4);
tprint "extract(3,4)", ! defined($str);

tprint "insert(ZZZ)", $db->insert(attribute => 3, value => 4, text => 'ZZZ');

tprint "rewind", $db->rewind;

tprint "next", $db->next eq 'Test';

tprint "attribute", join('|',$db->attribute(attribute => 2)) eq '||Test Data 2-3';

my @rec=$db->record;
tprint "record.size", @rec == 3;
tprint "record.attr(1)", @{$rec[1]} == 2;
tprint "record.value", join("|",@{$rec[1]}) eq '|Test Data 1-2';

tprint "next=undef", ! defined($db->next);

tprint "close", $db->close;
