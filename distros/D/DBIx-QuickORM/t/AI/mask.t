use Test2::V0 '!meta', '!pass';
use Data::Dumper;

use DBIx::QuickORM::Util qw/mask unmask masked/;
use DBIx::QuickORM::Util::Mask;

# A lightweight wrapped object so tests never need a database or DateTime.
{
    package Masked::Test::Obj;

    sub new   { bless {a => 1, b => 2}, shift }
    sub greet { "hello" }
    sub val   { 42 }
    sub args  { my $self = shift; "got:@_" }
}

# mask_class is expected to be a subclass of the Mask base, exactly as the
# DateTime type uses it (use parent 'DBIx::QuickORM::Util::Mask'). A subclass
# inherits the overloads and AUTOLOAD delegation, and isa() reports both the
# subclass and the base Mask class.
{
    package Masked::Test::Subclass;
    use parent -norequire, 'DBIx::QuickORM::Util::Mask';
}

# ---- new(): argument validation ----
subtest new_validation => sub {
    ok(
        !eval { DBIx::QuickORM::Util::Mask->new(string => "x"); 1 },
        "missing generator croaks"
    );
    like($@, qr/'generator' is required/, "generator-required message");

    ok(
        !eval { DBIx::QuickORM::Util::Mask->new(string => "x", generator => "nope"); 1 },
        "non-coderef generator croaks"
    );
    like($@, qr/must be a coderef/, "generator-coderef message");

    ok(
        !eval { DBIx::QuickORM::Util::Mask->new(generator => sub { 1 }); 1 },
        "missing string croaks"
    );
    like($@, qr/'string' is required/, "string-required message");

    # string is validated with defined(), so a defined-but-falsy "0" is allowed.
    my $m;
    ok(
        lives { $m = DBIx::QuickORM::Util::Mask->new(string => 0, generator => sub { 1 }) },
        "string => 0 (defined but falsy) is accepted"
    );
    is("$m", "0", "the falsy string is preserved");
};

# ---- lazy build + memoization ----
subtest lazy_build => sub {
    my $built = 0;
    my $m = mask(
        string    => "display-only",
        generator => sub { $built++; Masked::Test::Obj->new },
    );

    is($built, 0, "generator NOT run at construction");
    ok(!$m->qorm_mask_inflated, "qorm_mask_inflated is false before first use");

    my $obj = $m->qorm_unmask;
    is($built, 1, "generator ran once on first real use (qorm_unmask)");
    is(ref($obj), 'Masked::Test::Obj', "qorm_unmask returns the wrapped object");
    ok($m->qorm_mask_inflated, "qorm_mask_inflated is true after build");

    is($m->qorm_unmask, $obj, "qorm_unmask returns the same memoized object");
    is($built, 1, "generator is not run again (memoized)");
};

# ---- stringify never builds ----
subtest stringify_no_build => sub {
    my $built = 0;
    my $m = mask(
        string    => "the-display-string",
        generator => sub { $built++; Masked::Test::Obj->new },
    );

    is("$m", "the-display-string", "stringifies to the display string");
    is($m->qorm_mask_string, "the-display-string", "qorm_mask_string returns the display string");
    is($built, 0, "stringification did NOT run the generator");
    ok(!$m->qorm_mask_inflated, "still not inflated after stringify");

    # Force a build, then confirm stringify still returns the display string
    # and does not change.
    $m->qorm_unmask;
    is("$m", "the-display-string", "stringify is still the display string after inflation");
};

# ---- Util helpers: mask / unmask / masked ----
subtest util_helpers => sub {
    my $built = 0;
    my $m = mask(string => "d", generator => sub { $built++; Masked::Test::Obj->new });

    ok(masked($m), "masked() true for a mask");
    ok(!masked("plain"), "masked() false for a plain string");
    ok(!masked({}), "masked() false for an unblessed ref");
    ok(!masked(bless({}, 'Masked::Test::Obj')), "masked() false for an unrelated blessed object");

    is($built, 0, "masked() does not build the object");

    my $obj = unmask($m);
    is(ref($obj), 'Masked::Test::Obj', "unmask() returns the wrapped object");
    is($built, 1, "unmask() built the object");

    is(unmask("plain"), "plain", "unmask() passes a non-mask through unchanged");
    my $ref = {x => 1};
    is(unmask($ref), $ref, "unmask() passes a non-mask ref through unchanged");
};

# ---- method delegation via AUTOLOAD ----
subtest autoload_delegation => sub {
    my $m = mask(string => "d", generator => sub { Masked::Test::Obj->new });

    is($m->greet, "hello", "delegates a no-arg method to the wrapped object");
    is($m->val, 42, "delegates another method");
    is($m->args(1, 2, 3), "got:1 2 3", "delegates with arguments preserved");
    ok($m->qorm_mask_inflated, "delegation built the object");

    my $m2 = mask(string => "d", generator => sub { Masked::Test::Obj->new });
    ok(
        !eval { $m2->no_such_method; 1 },
        "calling a method the wrapped object lacks croaks"
    );
    like($@, qr/Can't locate object method "no_such_method"/, "missing-method message");

    ok(
        !eval { DBIx::QuickORM::Util::Mask->some_method; 1 },
        "AUTOLOAD on the class (not an instance) croaks"
    );
};

# ---- isa delegation ----
subtest isa_delegation => sub {
    my $built = 0;
    my $m = mask(string => "d", generator => sub { $built++; Masked::Test::Obj->new });

    ok($m->isa('DBIx::QuickORM::Util::Mask'), "isa(Mask) true via UNIVERSAL (no build)");
    is($built, 0, "isa(Mask) did not build the object");

    ok($m->isa('Masked::Test::Obj'), "isa(wrapped class) true via delegation");
    ok(!$m->isa('Some::Other::Class'), "isa(unrelated class) false");

    # mask_class: a subclass of the Mask base. isa() reports both the subclass
    # and the base Mask class via UNIVERSAL (no build needed).
    my $tm = mask(
        string     => "d",
        generator  => sub { Masked::Test::Obj->new },
        mask_class => 'Masked::Test::Subclass',
    );
    is(ref($tm), 'Masked::Test::Subclass', "mask_class controls the blessed package");
    ok($tm->isa('Masked::Test::Subclass'), "isa(mask_class) true via UNIVERSAL");
    ok($tm->isa('DBIx::QuickORM::Util::Mask'), "isa(Mask base) true for a subclass");
};

# ---- can delegation ----
subtest can_delegation => sub {
    my $m = mask(string => "d", generator => sub { Masked::Test::Obj->new });

    my $own = $m->can('qorm_unmask');
    is(ref($own), 'CODE', "can() finds the mask's own method");

    my $delegated = $m->can('greet');
    is(ref($delegated), 'CODE', "can() returns a coderef for a delegated method");
    is($delegated->($m), "hello", "the can()-returned coderef delegates to the wrapped object");

    my $m2 = mask(string => "d", generator => sub { Masked::Test::Obj->new });
    is($m2->can('no_such_method'), undef, "can() returns undef for an unknown method");
};

# ---- overloads: 0+, bool, %{} ----
subtest overloads => sub {
    my $num = mask(string => "n", generator => sub { 99 });
    is(0 + $num, 99, "0+ overload numifies via the wrapped value");

    my $m = mask(string => "d", generator => sub { Masked::Test::Obj->new });
    ok($m, "bool overload is always true");
    ok(!!$m, "bool overload true even before build");

    my $built = 0;
    my $hm = mask(string => "d", generator => sub { $built++; Masked::Test::Obj->new });
    my %copy = %$hm;
    is($built, 1, "%{} hash-deref overload builds the wrapped object");
    is(\%copy, {a => 1, b => 2}, "%{} delegates to the wrapped hash object");
};

# ---- Data::Dumper stays compact (wrapped object hidden) ----
subtest dumper_compact => sub {
    my $m = mask(
        string    => "display-string",
        generator => sub { Masked::Test::Obj->new },
    );

    my $before = Dumper($m);
    unlike($before, qr/Masked::Test::Obj/, "wrapped class absent from dump before build");

    # Build it, then confirm the wrapped object is STILL hidden because it lives
    # in the generator closure, never in a visible slot.
    $m->qorm_unmask;
    ok($m->qorm_mask_inflated, "object is built");

    my $after = Dumper($m);
    unlike($after, qr/Masked::Test::Obj/, "wrapped class still absent from dump after build");
    unlike($after, qr/'a'|'b'/, "wrapped object's hash contents absent from dump");
    like($after, qr/display-string/, "the display string is what shows in the dump");
};

# ---- documented behavior from the Types manual ----
# The Types manual ("DATETIME" section) documents the mask contract: lazy build,
# stringify never builds, isa(type) needs no build, and the wrapped object stays
# out of Data::Dumper / Carp output. These are exercised type-agnostically here.
subtest documented_contract => sub {
    my $built = 0;
    my $m = mask(
        string     => "2026-05-24 12:00:00",
        generator  => sub { $built++; Masked::Test::Obj->new },
        mask_class => 'Masked::Test::Subclass',
    );

    is("$m", "2026-05-24 12:00:00", "stringify returns the original display string");
    is($built, 0, "manual: stringification builds nothing");

    ok($m->isa('Masked::Test::Subclass'), "manual: isa(reported type) without a build");
    is($built, 0, "manual: isa(reported type) builds nothing");

    is($m->greet, "hello", "manual: a method call builds and delegates");
    is($built, 1, "manual: the build happened exactly once, on first method use");

    is("$m", "2026-05-24 12:00:00", "manual: stringify unchanged after the object is built and used");
};

done_testing;
