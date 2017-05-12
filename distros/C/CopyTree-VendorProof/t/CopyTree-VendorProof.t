# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CopyTree-VendorProof.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More  tests=>15;
#use Test::More  'no_plan';
BEGIN { use_ok('CopyTree::VendorProof') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $cpobj = CopyTree::VendorProof->new;
isa_ok ($cpobj, "CopyTree::VendorProof", 'cpobj is a correct obj');

my $connector_inst=bless {}, CopyTree::VendorProof;
my $path='somepath';


isa_ok (ref $cpobj ->src ($path,$connector_inst), 'CopyTree::VendorProof', 'src returns self');
is (ref $cpobj ->{'source'}{$path}, 'CopyTree::VendorProof', 'src stores inst with path as key');
my @testpath= keys %{$cpobj ->{'source'}};
is ($testpath[0], $path, 'src stores actual path key');
#dst is getter and setter, does not return self
$path ='someotherpath';
$cpobj ->dst ($path,$connector_inst); #setter
is (ref $cpobj ->{'destination'}{$path}, 'CopyTree::VendorProof', 'dst stores path and inst');
my ($returnpath, $returninst) = $cpobj ->dst ();
is ($returnpath, $path,'first part of dst() returns path');
is (ref $returninst,'CopyTree::VendorProof' ,'second part of dst() returns inst');
my $newcpobj = CopyTree::VendorProof->new;
eval {$newcpobj ->cp;};
like ($@, qr"^dest file is not defined\.", 'no dst object/file');
$newcpobj = CopyTree::VendorProof->new;
$newcpobj -> dst ('', $connector_inst);
eval {$newcpobj ->cp;};
like ($@, qr"^dest file is not defined\.", 'dst obj, no fd_ls meth, no path. no path fails first');
$newcpobj = CopyTree::VendorProof->new;
$newcpobj -> dst ('somepath', $connector_inst);
eval {$newcpobj ->cp;};
like ($@, qr/Can't locate object method "is_fd" via/, 'valid dst path, no methods for dst inst');
$newcpobj ->reset;
is (ref $newcpobj ->{'source'}, 'HASH', 'after reset, get empty hash');
is (keys %{ $newcpobj ->{'source'} }, 0, 'after reset, get empty hash');

is (ref $newcpobj ->{'destination'}, 'HASH', 'after reset, get empty hash');
is (keys %{ $newcpobj ->{'destination'} }, 0, 'after reset, get empty hash');
#cannot test src obj since test won't continue if dst object fails, and no dst objects can occur without
#helper modules

