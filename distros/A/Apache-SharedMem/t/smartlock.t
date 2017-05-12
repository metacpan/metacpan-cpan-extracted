package Test::AS::smartlock;

BEGIN
{
    use strict;
    use Test;
    plan tests => 16;
}

# under some configuration, PWD isn't defined
unless(defined $ENV{PWD} || $ENV{PWD} ne '')
{
    print STDERR "Your \$PWD environment variable is unset, I fix this.\n";
    my $pwd = `pwd`;
    chomp($pwd);
    $ENV{PWD} = $pwd;
}

use Apache::SharedMem qw(:all);
ok(1);

my $share = new Apache::SharedMem;

$share->lock(LOCK_SH);
ok($share->{_lock_status}, LOCK_SH);
$share->set("test"=>"toto");
ok($share->{_lock_status}, LOCK_SH);
$share->unlock;

$share->lock(LOCK_EX);
ok($share->{_lock_status}, LOCK_EX);
$share->get("test");
ok($share->{_lock_status}, LOCK_EX);
$share->unlock;

$share->lock(LOCK_EX);
ok($share->{_lock_status}, LOCK_EX);
$share->exists("test");
ok($share->{_lock_status}, LOCK_EX);
$share->unlock;

$share->lock(LOCK_EX);
ok($share->{_lock_status}, LOCK_EX);
$share->firstkey;
ok($share->{_lock_status}, LOCK_EX);
$share->unlock;

$share->lock(LOCK_EX);
ok($share->{_lock_status}, LOCK_EX);
$share->nextkey("test");
ok($share->{_lock_status}, LOCK_EX);
$share->unlock;

$share->lock(LOCK_SH);
ok($share->{_lock_status}, LOCK_SH);
$share->delete("test");
ok($share->{_lock_status}, LOCK_SH);
$share->unlock;

$share->lock(LOCK_SH);
ok($share->{_lock_status}, LOCK_SH);
$share->clear;
ok($share->{_lock_status}, LOCK_SH);
$share->unlock;

$share->release;
ok($share->status, SUCCESS);
