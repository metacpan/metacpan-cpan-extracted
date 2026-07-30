use strict; use warnings; use Test::More; use File::Temp 'tempdir';
use Data::PerfectHash::Shared;

# F7 + F9a: builder-side input validation.
#   F7  -- build_str croaks on a wide-character key (SvPVbyte fails mid-collect).
#          The fix registers the transient builder on the save stack so this
#          croak-unwind frees it (leak-freedom is proven under LeakSanitizer;
#          here we just pin the croak + message so a regression is visible).
#   F9a -- unknown / odd-count options croak instead of being silently ignored
#          (a `tipe => 'str'` typo used to yield a default int builder).

my $dir = tempdir(CLEANUP => 1);
my $p   = "$dir/x.phs";

# --- F7: wide char in build_str ---
{
    my $ok = eval { Data::PerfectHash::Shared->build_str($p, ["ok", "wide-\x{100}", "ok2"]); 1 };
    ok !$ok, 'build_str dies on a wide-char key';
    like $@, qr/Wide char/i, 'build_str croaks on wide char (SvPVbyte)';
}

# --- F9a: new_builder rejects unknown / malformed options ---
{
    my $ok = eval { Data::PerfectHash::Shared->new_builder(tipe => 'str'); 1 };
    ok !$ok, 'new_builder dies on an unknown option';
    like $@, qr/unknown option/, 'new_builder croaks on an unknown option (tipe typo)';
}
{
    my $ok = eval { Data::PerfectHash::Shared->new_builder('type'); 1 };   # odd count
    ok !$ok, 'new_builder dies on an odd option count';
    like $@, qr/odd number of options/, 'new_builder croaks on an odd option count';
}

# --- F9a: build rejects unknown / malformed options ---
{
    my $b  = Data::PerfectHash::Shared->new_builder;   # default int
    my $ok = eval { $b->build($p, bogus => 1); 1 };
    ok !$ok, 'build dies on an unknown option';
    like $@, qr/unknown option/, 'build croaks on an unknown option (bogus)';
}
{
    my $b  = Data::PerfectHash::Shared->new_builder;
    my $ok = eval { $b->build($p, 'mode'); 1 };        # odd count
    ok !$ok, 'build dies on an odd option count';
    like $@, qr/odd number of options/, 'build croaks on an odd option count';
}

# --- sanity: valid options still work (no F9a false positive) ---
{
    my $b = Data::PerfectHash::Shared->new_builder(type => 'int');
    $b->add_many([1 .. 10]);
    my $ok = eval { $b->build($p, mode => 0600); 1 };
    ok $ok, 'build still accepts the valid mode option' or diag $@;
    my $set = Data::PerfectHash::Shared->load($p);
    ok $set->has(5), 'built set works after a valid-option build';
    is $set->type, 'int', 'valid new_builder(type=>int) really produced an int set';
}

# --- sanity: valid new_builder(type=>str) still selects a str builder ---
{
    my $b = Data::PerfectHash::Shared->new_builder(type => 'str');
    $b->add_many(['apple', 'banana']);
    $b->build($p);
    my $set = Data::PerfectHash::Shared->load($p);
    is $set->type, 'str', 'valid new_builder(type=>str) really produced a str set';
    ok $set->has('banana'), 'str set works';
}

done_testing;
