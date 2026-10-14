#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($a1 $b2);

# A reference count off by one in the table shows as a warning from perl,
# not as a failure, so every warning here is collected and must be none.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

# The C table: its address, its version, its selftest, and a context built
# through it read back through the Perl surface, which cannot be wrong in the
# same direction as the table.

my $p = Context::Vars::_abi_ptr();
ok($p, 'the table has an address');
is($p, Context::Vars::_abi_ptr(), 'the same one every call');
like($p, qr/^\d+$/, 'given as an unsigned integer');
is(Context::Vars::_abi_version(), 1, 'the table is version 1');

my ($step, $ctx) = Context::Vars::_abi_selftest();
is($step, 0, 'every entry answered as its declaration says')
    or diag 'the number is the check that failed in include/context_vars/context_vars_abi_impl.h';
isa_ok($ctx, 'Context::Vars::Context', 'the context the selftest built, through ctx_to_sv');
is_deeply([$ctx->names], [qw(a c)], 'it holds the names C stored in it, and not the one C unset');
is($ctx->get('a'), 1, 'with the value C stored before capturing it');
is($ctx->get('c'), 3, 'and the one C stored while it was entered');

# Read with an imported variable, inside the context C built.
{
    package ABI::Reader;
    use Context::Vars qw($a $c);
    sub look { "$a/$c" }
}
is($ctx->run(\&ABI::Reader::look), '1/3', 'an imported variable reads what C stored');

ok(!defined $a1, 'the top level is untouched');
is(Context::Vars::_depth(), 0, 'no context is left entered');
undef $ctx;
is(Context::Vars::_live_holders(), 0, 'and once the object goes, no holder is out');

# The selftest again: nothing it did the first time is in the way.
($step) = Context::Vars::_abi_selftest();
is($step, 0, 'the selftest passes a second time');

ok(eval { require Context::Vars::Install::Files; 1 }, 'the provider config for consumers exists')
    or diag $@;
{
    no warnings 'once';
    my $core = $Context::Vars::Install::Files::CORE;
    ok(defined $core && -f "$core/context_vars_abi.h", 'and names the installed header');
}

is_deeply(\@warnings, [], 'and perl warned of nothing on the way');

done_testing;
