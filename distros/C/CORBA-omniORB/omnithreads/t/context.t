use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

use omnithreads;

BEGIN {
    eval {
        require omnithreads::shared;
        import omnithreads::shared;
    };
    if ($@ || ! $omnithreads::shared::threads_shared) {
        print("1..0 # Skip: omnithreads::shared not available\n");
        exit(0);
    }

    $| = 1;
    print("1..31\n");   ### Number of tests that will be run ###
};

my $TEST;
BEGIN {
    share($TEST);
    $TEST = 1;
}

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}


### Start of Testing ###

sub foo
{
    my $context = shift;
    my $wantarray = wantarray();

    if ($wantarray) {
        ok($context eq 'array', 'Array context');
        return ('array');
    } elsif (defined($wantarray)) {
        ok($context eq 'scalar', 'Scalar context');
        return 'scalar';
    } else {
        ok($context eq 'void', 'Void context');
        return;
    }
}

my ($thr) = omnithreads->create('foo', 'array');
my ($res) = $thr->join();
ok($res eq 'array', 'Implicit array context');

$thr = omnithreads->create('foo', 'scalar');
$res = $thr->join();
ok($res eq 'scalar', 'Implicit scalar context');

omnithreads->create('foo', 'void');
($thr) = omnithreads->list();
$res = $thr->join();
ok(! defined($res), 'Implicit void context');

$thr = omnithreads->create({'context' => 'array'}, 'foo', 'array');
($res) = $thr->join();
ok($res eq 'array', 'Explicit array context');

($thr) = omnithreads->create({'scalar' => 'scalar'}, 'foo', 'scalar');
$res = $thr->join();
ok($res eq 'scalar', 'Explicit scalar context');

$thr = omnithreads->create({'void' => 1}, 'foo', 'void');
$res = $thr->join();
ok(! defined($res), 'Explicit void context');


sub bar
{
    my $context = shift;
    my $wantarray = omnithreads->wantarray();

    if ($wantarray) {
        ok($context eq 'array', 'Array context');
        return ('array');
    } elsif (defined($wantarray)) {
        ok($context eq 'scalar', 'Scalar context');
        return 'scalar';
    } else {
        ok($context eq 'void', 'Void context');
        return;
    }
}

($thr) = omnithreads->create('bar', 'array');
my $ctx = $thr->wantarray();
ok($ctx, 'Implicit array context');
($res) = $thr->join();
ok($res eq 'array', 'Implicit array context');

$thr = omnithreads->create('bar', 'scalar');
$ctx = $thr->wantarray();
ok(defined($ctx) && !$ctx, 'Implicit scalar context');
$res = $thr->join();
ok($res eq 'scalar', 'Implicit scalar context');

omnithreads->create('bar', 'void');
($thr) = omnithreads->list();
$ctx = $thr->wantarray();
ok(! defined($ctx), 'Implicit void context');
$res = $thr->join();
ok(! defined($res), 'Implicit void context');

$thr = omnithreads->create({'context' => 'array'}, 'bar', 'array');
$ctx = $thr->wantarray();
ok($ctx, 'Explicit array context');
($res) = $thr->join();
ok($res eq 'array', 'Explicit array context');

($thr) = omnithreads->create({'scalar' => 'scalar'}, 'bar', 'scalar');
$ctx = $thr->wantarray();
ok(defined($ctx) && !$ctx, 'Explicit scalar context');
$res = $thr->join();
ok($res eq 'scalar', 'Explicit scalar context');

$thr = omnithreads->create({'void' => 1}, 'bar', 'void');
$ctx = $thr->wantarray();
ok(! defined($ctx), 'Explicit void context');
$res = $thr->join();
ok(! defined($res), 'Explicit void context');

# EOF
