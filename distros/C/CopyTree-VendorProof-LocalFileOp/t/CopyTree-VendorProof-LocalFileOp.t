# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CopyTree-VendorProof-LocalFileOp.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests=>37;
#use Test::More qw/no_plan/;
BEGIN { use_ok('CopyTree::VendorProof::LocalFileOp') };
#BEGIN{
#my $isajoin = join (' ', @ISA);
#my $incjoin = join (' ', @INC);
#is ($isajoin, '','check isa usually gets nothing, though expecting VendorProof');
#like($incjoin, qr#/usr/local/share/perl/5\.10\.1#,'check inc');
#}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN { use_ok('CopyTree::VendorProof') };
my $cpobj = CopyTree::VendorProof->new;
isa_ok ($cpobj, "CopyTree::VendorProof", 'cpobj is a correct obj');

my $connector_inst=CopyTree::VendorProof::LocalFileOp->new;
isa_ok ($connector_inst, "CopyTree::VendorProof::LocalFileOp", 'connector_inst is a correct CopyTree::VendorProof::LocalFileOp obj');
open my $localFH, ">", "somepath";
print $localFH, "somefile content\n";
close $localFH;

my $path='somepath';

isa_ok (ref $cpobj ->src ($path,$connector_inst), 'CopyTree::VendorProof', 'src returns self');
is (ref $cpobj ->{'source'}{$path}, 'CopyTree::VendorProof::LocalFileOp', 'src stores connector_inst with path as key');
my @testpath= keys %{$cpobj ->{'source'}};
is ($testpath[0], $path, 'src stores actual path key');
#dst is getter and setter, does not return self
$path ='someotherpath';
$cpobj ->dst ($path,$connector_inst); #setter
is (ref $cpobj ->{'destination'}{$path}, 'CopyTree::VendorProof::LocalFileOp', 'dst stores path and connector_inst');
my ($returnpath, $returninst) = $cpobj ->dst ();
is ($returnpath, $path,'first part of dst() returns path');
is (ref $returninst,'CopyTree::VendorProof::LocalFileOp' ,'second part of dst() returns connector_inst');
my $newcpobj = CopyTree::VendorProof->new;
eval {$newcpobj ->cp;};
like ($@, qr"^dest file is not defined\.", 'no dst object/file');
$newcpobj = CopyTree::VendorProof->new;
$newcpobj -> dst ('', $connector_inst);
eval {$newcpobj ->cp;};
like ($@, qr"^dest file is not defined\.", 'dst obj, no fd_ls meth, no path. no path fails first');
$newcpobj = CopyTree::VendorProof->new;
$newcpobj -> dst ('someotherpath', $connector_inst);
eval {$newcpobj ->cp;};
like ($@, qr/you don't have a source/, 'copy local to local, somepath to someotherpath, no src declair');
$newcpobj ->src ('somepath', 'nobj');
eval {$newcpobj ->cp;};
like ($@, qr/Can't locate object method "is_fd"/, 'copy local to local, somepath to someotherpath, src inst no methods');
$newcpobj = CopyTree::VendorProof->new;
$newcpobj -> dst ('someotherpath', $connector_inst);
$newcpobj ->src ('somepath', $connector_inst);
eval {$newcpobj ->cp;};
is ($@, '', 'copy local to local, somepath to someotherpath');
is ($connector_inst -> is_fd ('somepath') , 'f', 'file test f on src');
is ($connector_inst -> is_fd ('someotherpath') , 'f', 'file test f on src');
#use base qw/CopyTree::VendorProof/;
my @files;
@files = $connector_inst ->fdls ('f', '.');
isnt ($files[0], '', 'fdls f, . shoudld get somepath and someotherpath');	
$connector_inst->cust_mkdir("testdir");
my @dirs = $connector_inst ->fdls ('d', 'testdir/../');
isnt ($dirs[0], '', 'fdls f, ../ use of .. and ending slash auto removed');	
is ($connector_inst -> is_fd ("testdir"), 'd', "is_fd returns 'd' on dir");
$newcpobj ->reset;
$newcpobj ->src ('someotherpath', $connector_inst);
$newcpobj ->dst ('testdir', $connector_inst);
$newcpobj ->cp;
is ($connector_inst->is_fd('testdir/someotherpath'), 'f','cp file to dir');

$newcpobj ->reset;
$newcpobj ->src ('someotherpath', $connector_inst);
$newcpobj ->dst ('testdir/diffname', $connector_inst);
$newcpobj ->cp;
is ($connector_inst->is_fd('testdir/diffname'), 'f','cp file to different file name');

$newcpobj ->reset;
$newcpobj ->src ('testdir', $connector_inst);
$newcpobj ->dst ('testdir2', $connector_inst);
eval {$newcpobj ->cp;};
like ($@, qr/you cannot copy a dir \[testdir] into a non \/ non-existing dir \[testdir2]/,'cp dir to dir copy, check non existing dest dir copy shoudl fail' );

$connector_inst ->cust_mkdir ('testdir2');
$newcpobj ->cp;
is ($connector_inst->is_fd('testdir2/testdir'), 'd','cp dir to dir copy, check source dir inside dest');
is ($connector_inst->is_fd('testdir2/testdir/diffname'), 'f','cp dir to dir copy, check source dir, file inside dest');
is ($connector_inst->is_fd('testdir2/testdir/someotherpath'), 'f','cp dir to dir copy, check source dir, file inside dest');
is ($connector_inst->is_fd('nonexist/bsfile'), 0,'cp dir to dir copy, check source dir, file inside dest');
$connector_inst ->write_from_memory($connector_inst->read_into_memory('testdir2/testdir/diffname'), 'testdir2/written');
$connector_inst ->copy_local_files('testdir2/testdir/diffname',  'testdir2/written_local');
is ($connector_inst->is_fd('testdir2/written'), 'f','write_from_memory, read_into_memory test');
is ($connector_inst->is_fd('testdir2/written_local'), 'f','copy_local_files test');
my ($arrf, $arrd) = $connector_inst ->fdls ('fdarrayrefs', '.');
is (ref $arrf, 'ARRAY', 'fdarrayrefs test');
is (ref $arrd, 'ARRAY', 'fdarrayrefs test');

eval{$connector_inst -> cust_rmdir ('non-existingdir');};
like ($@,qr/wait\. you told me to delete something that's not a dir\. I'll stop for your protection/, 'removing an non existing dir dies'); 
$connector_inst->cust_rmdir ("testdir");
$connector_inst->cust_rmdir ("testdir2");
eval {$connector_inst->cust_rmdir ("/");};
like ($@, qr'should not be rmdiring a root', 'do not rmdir / no matter what you say test');
eval {$connector_inst->cust_mkdir ("/");};
like ($@, qr'should not be mkdiring a root', 'do not mkdir / no matter what you say test');
is ($connector_inst -> is_fd ("testdir"), 'pd', "is_fd returns 'pd' on non-existing");
is ($connector_inst ->is_fd ("somepath"), 'f', "make sure that somepath exists as a file");
$connector_inst ->cust_rmfile ("somepath");
is ($connector_inst ->is_fd ("somepath"), 'pd', "cust_rmfile test removed somepath");

$connector_inst ->cust_rmfile ("someotherpath");
