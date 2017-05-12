package Test::AS::timedoutlock;

BEGIN
{
    use strict;
    use Test;
    plan tests => 8;
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

my $share1 = new Apache::SharedMem;
my $share2 = new Apache::SharedMem;

$share1->lock(LOCK_EX);
ok($share1->{_lock_status}, LOCK_EX);

# set
eval
{
    local $SIG{ALRM} = sub{die};
    alarm(10);
    $share2->set("test"=>"toto", WAIT => 1);
    alarm(0);
};
ok(!$@ && $share2->status, FAILURE);

# get
eval
{
    local $SIG{ALRM} = sub{die};
    alarm(10);
    $share2->get("test", WAIT => 1);
    alarm(0);
};
ok(!$@ && $share2->status, FAILURE);

# exists
eval
{
    local $SIG{ALRM} = sub{die};
    alarm(10);
    $share2->exists("test", WAIT => 1);
    alarm(0);
};
ok(!$@ && $share2->status, FAILURE);

# delete
eval
{
    local $SIG{ALRM} = sub{die};
    alarm(10);
    $share2->delete("test", WAIT => 1);
    alarm(0);
};
ok(!$@ && $share2->status, FAILURE);

# clear
eval
{
    local $SIG{ALRM} = sub{die};
    alarm(10);
    $share2->clear(WAIT => 1);
    alarm(0);
};
ok(!$@ && $share2->status, FAILURE);


$share1->unlock;
$share2->release;
ok($share2->status, SUCCESS);
