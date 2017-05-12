#!/use/bin/perl -w

use strict;
use diagnostics;

print "1..10\n";


eval 'require IPC::ShareLite';

unless ($@) {
	print "ok 1\n";
}else
{
	print "not ok 1 : you haven't installed IPC::ShareLite\n"
}

eval 'require IPC::Cache';

unless ($@) {
	print "ok 2\n";
}else
{
	print "not ok 2 : you haven't installed IPC::Cache\n"
}



use Apache::Session::SharedMem;


my $s = {};

tie %$s, 'Apache::Session::SharedMem', undef, {};

if (tied %$s) {
    print "ok 3\n";
}
else {
    print "not ok 3 : couldn't tie Apache::Session::SharedMem to hash\n";
}

if (exists $s->{_session_id}) {
    print "ok 4\n";
}
else {
    print "not ok 4 : sessionid not set;  session has not initialised properly\n";
}

my $id = $s->{_session_id};

$s->{foo} = 'bar';
$s->{baz} = ['tom', 'dick', 'harry'];

untie %$s;
undef $s;
$s = {};

tie %$s, 'Apache::Session::SharedMem', $id, {};

if (tied %$s) {
    print "ok 5\n";
}else
{
	print "not ok 5 : couldn't retie session\n";
}
 

if ($s->{_session_id} eq $id) {
    print "ok 6\n";
}
else {
    print "not ok 6 : session not retied properly (sessionids not the same)\n";
}

if ($s->{foo} eq 'bar' && $s->{baz}->[0] eq 'tom' && $s->{baz}->[2] eq 'harry'){
    print "ok 7\n";
}
else {
    print "not ok 7 : data not serialized into session properly\n";
}

tied(%$s)->delete();
untie %$s;
undef $s;


my $cache = new IPC::Cache { namespace => $id };

unless  (defined $cache->get($id)) {
	print "ok 8\n";
}
else{
	print "not ok 8 : session not deleted properly - you might want to use ipcs and ipcrm to delete the sharedmem segment\n";
}
	

use Apache::Session::Flex;

my $hash;

tie %$hash, 'Apache::Session::Flex', undef, { 
	Store	  => 'SharedMem',
	Lock      => 'Null',
    Generate  => 'MD5',
    Serialize => 'Base64'
};

if (tied %$hash) {
    print "ok 9\n";
}
else {
    print "not ok 9 : couldn't tie Apache::Session::Flex to hash\n";
}

if (exists $hash->{_session_id}) {
    print "ok 10\n";
}
else {
    print "not ok 10 : sessionid not set;  session has not initialised properly\n";
}

tied(%$hash)->delete;
untie %$hash;
undef $hash;
