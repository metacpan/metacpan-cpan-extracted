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

sub ok {
    my ($id, $ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..30\n");   ### Number of tests that will be run ###
};

use omnithreads;

if ($omnithreads::VERSION && ! exists($ENV{'PERL_CORE'})) {
    print(STDERR "# Testing omnithreads $omnithreads::VERSION\n");
}

ok(1, 1, 'Loaded');

### Start of Testing ###

ok(2, 1 == $omnithreads::threads, "Check that omnithreads::threads is true");

sub test1 {
    ok(3,'bar' eq $_[0], "Test that argument passing works");
}
omnithreads->create('test1', 'bar')->join();

sub test2 {
    ok(4,'bar' eq $_[0]->[0]->{'foo'}, "Test that passing arguments as references work");
}
omnithreads->create(\&test2, [{'foo' => 'bar'}])->join();

sub test3 {
    ok(5, shift() == 1, "Test a normal sub");
}
omnithreads->create(\&test3, 1)->join();


# sub test4 {
#     ok(6, 1, "Detach test");
# }
# {
#     my $thread1 = omnithreads->create('test4');
#     $thread1->detach();
#     while ($thread1->is_running()) {
#         omnithreads->yield();
#         sleep 1;
#     }
# }
# ok(7, 1, "Detach test");
ok(6, 1, "Dummy test");
omnithreads->create(sub { ok(7, 1, "Dummy test") })->join;


sub test5 {
    omnithreads->create('test6')->join();
    ok(9, 1, "Nested thread test");
}

sub test6 {
    ok(8, 1, "Nested thread test");
}

omnithreads->create('test5')->join();


sub test7 {
    my $self = omnithreads->self();
    ok(10, $self->tid == 7, "Wanted 7, got ".$self->tid);
    ok(11, omnithreads->tid() == 7, "Wanted 7, got ".omnithreads->tid());
}
omnithreads->create('test7')->join;

sub test8 {
    my $self = omnithreads->self();
    ok(12, $self->tid == 8, "Wanted 8, got ".$self->tid);
    ok(13, omnithreads->tid() == 8, "Wanted 8, got ".omnithreads->tid());
}
omnithreads->create('test8')->join;


ok(14, 0 == omnithreads->self->tid(), "Check so that tid for threads work for main thread");
ok(15, 0 == omnithreads->tid(), "Check so that tid for threads work for main thread");

{
    no warnings;
    local *CLONE = sub {
        ok(16, omnithreads->tid() == 9, "Tid should be correct in the clone");
    };
    omnithreads->create(sub {
        ok(17, omnithreads->tid() == 9, "And tid be 9 here too");
    })->join();
}

{
    sub Foo::DESTROY {
        ok(19, omnithreads->tid() == 10, "In destroy it should be correct too" )
    }
    my $foo;
    omnithreads->create(sub {
        ok(18, omnithreads->tid() == 10, "And tid be 10 here");
        $foo = bless {}, 'Foo';
        return undef;
    })->join();
}


my $thr1 = omnithreads->create(sub {});
my $thr2 = omnithreads->create(sub {});
my $thr3 = omnithreads->object($thr1->tid());

# Make sure both overloaded '==' and '!=' are working correctly
ok(20,   $thr1 != $thr2,  'Treads not equal');
ok(21, !($thr1 == $thr2), 'Treads not equal');
ok(22,   $thr1 == $thr3,  'Threads equal');
ok(23, !($thr1 != $thr3), 'Threads equal');

ok(24, omnithreads->object($thr1->tid())->tid() == 11, 'Object method');
ok(25, omnithreads->object($thr2->tid())->tid() == 12, 'Object method');

$thr1->join();
$thr2->join();

my $sub = sub { ok(26, shift() == 1, "Test code ref"); };
omnithreads->create($sub, 1)->join();

my $thrx = omnithreads->object(99);
ok(27, ! defined($thrx), 'No object');
$thrx = omnithreads->object();
ok(28, ! defined($thrx), 'No object');
$thrx = omnithreads->object(undef);
ok(29, ! defined($thrx), 'No object');
$thrx = omnithreads->object(0);
ok(30, ! defined($thrx), 'No object');

# EOF
