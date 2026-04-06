use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

# Test all integer and float variants briefly
my @int_variants = qw(I8 U8 I16 U16 I32 U32 I64 U64);
my @float_variants = qw(F32 F64);

for my $v (@int_variants) {
    my $mod = "Data::Buffer::Shared::$v";
    eval "use $mod";
    is($@, '', "load $mod");

    my $path = tmpnam();
    my $buf = $mod->new($path, 10);
    isa_ok($buf, $mod);

    $buf->set(0, 5);
    is($buf->get(0), 5, "$v set/get");

    is($buf->incr(0), 6, "$v incr");
    is($buf->decr(0), 5, "$v decr");
    is($buf->add(0, 3), 8, "$v add");
    ok($buf->cas(0, 8, 42), "$v cas");
    is($buf->get(0), 42, "$v cas result");

    unlink $path;
}

for my $v (@float_variants) {
    my $mod = "Data::Buffer::Shared::$v";
    eval "use $mod";
    is($@, '', "load $mod");

    my $path = tmpnam();
    my $buf = $mod->new($path, 10);
    isa_ok($buf, $mod);

    $buf->set(0, 3.14);
    ok(abs($buf->get(0) - 3.14) < 0.01, "$v set/get");

    unlink $path;
}

done_testing;
