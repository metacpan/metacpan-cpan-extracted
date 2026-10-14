#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util ();
use Context::Vars qw($hd);

# Every method refuses what is not a context it made, by name.

my $real = Context::Vars->capture;
my @fakes = (
    [ 'an unblessed hash reference' => {} ],
    [ 'a hash blessed into the class' => bless({}, 'Context::Vars::Context') ],
    [ 'a scalar blessed into the class' => bless(\(my $x = 5), 'Context::Vars::Context') ],
    [ 'an object of another class' => bless({}, 'Other::Class') ],
    [ 'a plain string' => 'Context::Vars::Context' ],
    [ 'a number' => 42 ],
    [ 'undef' => undef ],
);
for my $f (@fakes) {
    my ($what, $obj) = @$f;
    for my $m ([run => sub { Context::Vars::Context::run($_[0], sub { 1 }) }],
               [names => sub { Context::Vars::Context::names($_[0]) }],
               [get => sub { Context::Vars::Context::get($_[0], 'hd') }]) {
        my ($name, $call) = @$m;
        no warnings 'uninitialized';
        ok(!eval { $call->($obj); 1 }, "$name refuses $what");
        like($@, qr/^Context::Vars::Context::$name: not a Context::Vars::Context/, "$name: and says so by name");
    }
}
ok(eval { $real->run(sub { 1 }); 1 }, 'the real one is accepted') or diag $@;

# A context outlives the scope that captured it, and lets go of its values.
{
    my $destroyed = 0;
    { package H::Probe; sub DESTROY { $destroyed++ } }
    my $kept;
    sub capture_object { $hd = bless {}, 'H::Probe'; $kept = Context::Vars->capture }
    capture_object();
    is($destroyed, 0, 'a captured value outlives the sub that set it');
    is(ref $kept->get('hd'), 'H::Probe', 'and is there to read');
    undef $kept;
    is($destroyed, 1, 'and goes, once, with the last object holding it');
}

# Copies of the object are the same context.
{
    sub set_and_take { $hd = 'v'; Context::Vars->capture }
    my $a = set_and_take();
    my $b = $a;
    undef $a;
    is($b->get('hd'), 'v', 'a copy of the reference keeps the context when the first goes');
}

# A new thread does not get the object.
SKIP: {
    require Config;
    skip 'this perl has no ithreads', 3 unless $Config::Config{useithreads} && eval { require threads; 1 };
    sub set_for_thread { $hd = 'parent'; Context::Vars->capture }
    my $obj = set_for_thread();
    my @got = threads->create({ context => 'list' }, sub {
        (Scalar::Util::blessed($obj) // 'not an object', Context::Vars->capture->get('hd') // 'nothing')
    })->join;
    is($got[0], 'not an object', 'a context object is not cloned into a new thread');
    is($got[1], 'nothing', 'and the thread captures only its own values');
    is($obj->get('hd'), 'parent', 'the parent\'s object still works');
}

undef $real;
is(Context::Vars::_live_holders(), 0, 'no holder is out once the objects are gone');

done_testing;
