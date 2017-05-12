# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BDB-Wrapper.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 58 };
use BDB::Wrapper;
use File::Spec;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %bdbs=();
my $bdbw;
ok($bdbw=new BDB::Wrapper({'cache'=>10000000}));

my $bdb='test.bdb';
$bdbs{$bdb}=1;
unlink $bdb if -f $bdb;
my $bdb_home='';
$bdb_home=$bdbw->get_bdb_home($bdb);
ok($bdb_home=~ m!^/tmp/bdb_home!);

my $bdbh;
my $sort_code_ref=sub {lc $_[1] cmp lc $_[0]};
ok($bdbh=$bdbw->create_write_dbh({'bdb'=>$bdb, 'reverse'=>1 }));

ok($bdbh->db_put(1, 1)==0);
my $test_value;
ok($bdbh->db_get(1, $test_value)==0);
ok($test_value==1);

ok($bdbh->db_put(2, 2)==0);
ok($bdbh->db_get(2, $test_value)==0);
ok($test_value==2);

ok($bdbh->db_put(3, 3)==0);
ok($bdbh->db_get(3, $test_value)==0);
ok($test_value==3);

ok($bdbh->db_put(4, 4)==0);
ok($bdbh->db_get(4, $test_value)==0);
ok($test_value==4);

my $key=0;
my $value;
my @values=();
if(my $cursor=$bdbh->db_cursor()){
  while($cursor->c_get($key, $value, DB_NEXT)==0){
	push(@values, $key);
  }
  $cursor->c_close();
}
ok($values[0]==4 && $values[1]==3 && $values[2]==2 && $values[3]==1);
ok($bdbh->db_close()==0);

ok($bdbh=$bdbw->create_read_dbh($bdb, { 'reverse'=>1 }));

my $value2;
$bdbh->db_get(4, $value2);
ok($value2==4);

my $bdb2='test2.bdb';
$bdbs{$bdb2}=1;
$write_hash_ref=$bdbw->create_write_hash_ref({'bdb'=>$bdb2});
$write_hash_ref->{'write'}=1;
undef $write_hash_ref;

my $hash_ref=$bdbw->create_read_hash_ref({'bdb'=>$bdb2});
ok($hash_ref->{'write'}==1);

my $new_bdbw=new BDB::Wrapper({'ram'=>1});
my $new_dbh;
my $test_bdb='test3.bdb';
$bdbs{$test_bdb}=1;
ok($new_dbh=$new_bdbw->create_write_dbh($test_bdb));
ok($new_dbh->db_put('name', $value)==0);
$new_dbh->db_close();

my $bdbw3;
my $no_lock_bdb='no_lock.bdb';
$bdbs{$no_lock_bdb}=1;
ok($bdbw3=new BDB::Wrapper({'no_lock'=>1}));
ok($bdbh3=$bdbw3->create_write_dbh($no_lock_bdb));
ok(!(-f '__db.001'));

ok((-f $bdbw3->get_bdb_home($no_lock_bdb).'/__db.001'));
$bdbh3->db_close();

unlink $bdb;
ok($bdbh=$bdbw->create_write_dbh($bdb, {'sort_num'=>1 }));

$bdbh->db_put(1, 1);
$bdbh->db_put(9, 1);
$bdbh->db_put(10, 1);

$key=0;
$value='';
@values=();
if(my $cursor=$bdbh->db_cursor()){
  while($cursor->c_get($key, $value, DB_NEXT)==0){
	push(@values, $key);
  }
  $cursor->c_close();
}
ok($values[0]==1 && $values[1]==9 && $values[2]==10);
ok($bdbh->db_close()==0);

my $bdb_dir=File::Spec->rel2abs($bdb);
$bdb_dir=~ s!\.bdb$!!;
$bdb_dir='/tmp/bdb_home'.$bdb_dir;
ok($bdbw->get_bdb_home($bdb) eq $bdb_dir);


my $bdbw4;
my $bdb4='/tmp/abs_path.bdb';
$bdbs{$bdb4}=1;
my $no_env_bdb='no_env.bdb';
$bdbs{$no_env_bdb}=1;
unlink $no_env_bdb if -f $no_env_bdb;
$bdbw4=new BDB::Wrapper();
unlink $bdb4 if -f $bdb4;
ok($bdbh4=$bdbw4->create_write_dbh($bdb4));
ok($bdbh4=$bdbw->create_write_dbh($bdb4));
ok($bdbh4->db_put(1, 1)==0);
ok($bdbh4->db_close()==0);
ok(-d $bdbw4->get_bdb_home($bdb4));
unlink $bdb4;

if(-d $bdbw4->get_bdb_home($no_env_bdb)){
	my $path=$bdbw4->get_bdb_home($no_env_bdb);
	if($path=~ m!^/tmp!){
		system('rm -rf '.$path);
	}
}
my $no_env_bdbh=$bdbw4->create_write_dbh({'bdb'=>$no_env_bdb, 'no_env'=>1});
ok($no_env_bdbh->db_put(1,2)==0);
ok(!(-d $bdbw4->get_bdb_home($no_env_bdb)));
ok($no_env_bdbh->db_close()==0);

$no_env_bdbh=$bdbw4->create_read_dbh({'bdb'=>$no_env_bdb});
my $v4;
ok($no_env_bdbh->db_get(1, $v4)==0);
ok($v4==2);
ok($no_env_bdbh->db_close()==0);
unlink $no_env_bdb;

$bdbh4=$bdbw4->create_write_dbh({'bdb'=>$no_env_bdb, 'cache'=>16000, 'no_lock'=>1});
ok($bdbh4->db_put(1, 2)==0);
ok($bdbh4->db_close()==0);

my $no_lock_write_bdb='/tmp/no_lock_write.bdb';
$bdbs{$no_lock_write_bdb}=1;
$bdbh=$bdbw->create_write_dbh({'bdb'=>$no_lock_write_bdb, 'cache'=>16000, 'no_lock'=>1});
ok($bdbh->db_put(1, 2)==0);
ok($bdbh->db_close()==0);
ok(-d $bdbw->get_bdb_home($no_lock_write_bdb));

$bdbh=$bdbw->create_read_dbh({'bdb'=>$no_lock_write_bdb, 'cache'=>16000, 'no_lock'=>1});
my $tv='';
ok($bdbh->db_get(1, $tv)==0);
ok($tv==2);
ok($bdbh->db_close()==0);

foreach my $bdb (keys %bdbs){
	my $home_dir=$bdbw->get_bdb_home($bdb);
	if($home_dir=~ m!^(?:/tmp/|/dev/shm)!){
		system('rm -rf '.$home_dir);
	}
	unlink $bdb;
}

my $transaction_root_dir='/tmp/txn';
my $txn1;
my $trbdbw1=new BDB::Wrapper;
my $trbdb1='/tmp/transaction_test.bdb';
my ($trdbh1, $trenv1)=$trbdbw1->create_write_dbh({'bdb'=>$trbdb1, 'transaction'=>$transaction_root_dir});
ok($txn1 = $trenv1->txn_begin(undef, DB_TXN_NOWAIT));
ok($trdbh1->db_put('key', 'value')==0);
$txn1->txn_commit();
$trenv1->txn_checkpoint(1,1,0);
$trdbh1->db_close();

($trdbh1, $trenv1)=$trbdbw1->create_read_dbh({'bdb'=>$trbdb1, 'transaction'=>$transaction_root_dir});
my $trvalue='';
ok($trdbh1->db_get('key', $trvalue)==0);
ok($trvalue eq 'value');
$trdbh1->db_close();
my $trbdbh='';
my $trbdb_home='';
ok($trbdb_home=$trbdbw1->get_bdb_home({'bdb'=>$trbdb1, 'transaction'=>$transaction_root_dir}));
ok($trbdb_home=~ m!^$transaction_root_dir!);
ok(-d $trbdb_home);
$trbdbw1->clear_bdb_home({'bdb'=>$trbdb1, 'transaction'=>$transaction_root_dir});
ok(!(-d $trbdb_home));
