#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The modules load, share one version, resolved HAMT's table, and the
# provider config that ExtUtils::Depends writes for consumers is in the built
# tree.

use_ok('Context::Vars') or BAIL_OUT('Context::Vars does not load');

ok(defined $Context::Vars::VERSION, 'Context::Vars has a version');
like($Context::Vars::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

for my $class (qw(Context::Vars::Context)) {
    use_ok($class) or next;
    no strict 'refs';
    is(${"${class}::VERSION"}, $Context::Vars::VERSION, "$class carries the dist's version");
}

# The XS bundle is loaded, which a pure-Perl stub would pass without.
can_ok('Context::Vars', '_abi_ptr');

my $p = Context::Vars::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, Context::Vars::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer');
is(Context::Vars::_abi_version(), 1, 'the table is version 1');
is((Context::Vars::_abi_selftest())[0], 0, 'and its selftest passes')
    or diag('the number is the check that failed in include/context_vars/context_vars_abi_impl.h');

# Loading Context::Vars loaded HAMT, and the table it holds is HAMT's own:
# the version it read through the pointer is the one HAMT reports.
ok($INC{'HAMT.pm'}, 'loading Context::Vars loaded HAMT');
is(Context::Vars::_hamt_abi_version(), HAMT::_abi_version(),
   'the HAMT table it resolved reports the version HAMT reports');
cmp_ok(Context::Vars::_hamt_abi_version(), '>=', Context::Vars::_hamt_abi_needed(),
   'which is at least the version it was compiled against');

ok(eval { require Context::Vars::Install::Files; 1 },
   'Context::Vars::Install::Files exists (the provider config)')
    or diag $@;
{
    no warnings 'once';

    # Assert what a CONSUMER needs. A provider must record inc => '', because
    # its own build-tree paths are meaningless once installed. What a consumer
    # needs is $CORE, which is where install() put the header.
    is($Context::Vars::Install::Files::inc, '',
       'it records no include path of its own, so nothing leaks to a consumer');

    my $core = $Context::Vars::Install::Files::CORE;
    ok(defined $core && length $core, 'it records a CORE directory');
    ok(defined $core && -f "$core/context_vars_abi.h",
       'and context_vars_abi.h is in it, so a consumer finds the header')
        or diag "CORE: " . (defined $core ? $core : 'undef');
}

diag("Testing Context::Vars $Context::Vars::VERSION, HAMT $HAMT::VERSION, Perl $], $^X");

done_testing;
