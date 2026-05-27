#!/usr/bin/env perl
# Cross-check the three sources of truth for the public API:
#   1. POD: every public method is mentioned somewhere in the POD body.
#   2. Code: every public sub in lib/ + every public XSUB.
#   3. Tests: every public method is invoked by something under t/.
# Drift between any pair indicates a bug in docs, code, or tests.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run api-coverage tests'
    unless $ENV{RELEASE_TESTING};

my @pm_paths = ('lib/ClickHouse/Encoder.pm', 'lib/ClickHouse/Encoder/TCP.pm');
my $xs_path  = 'Encoder.xs';

# 1. POD: collect the entire POD body across both modules so methods
# documented in TCP.pm are counted as documented for the TCP subs.
my $pod_body = '';
for my $pm_path (@pm_paths) {
    open my $fh, '<', $pm_path or die $!;
    my $in_pod;
    while (<$fh>) {
        $in_pod = 1 if /^=head1 /;
        $in_pod = 0 if /^=cut/;
        $pod_body .= $_ if $in_pod;
    }
}

# 2. Code: scan both .pm files for `sub NAME`, and .xs for XSUBs.
my (%pm_subs, %xs_subs);
for my $pm_path (@pm_paths) {
    open my $fh, '<', $pm_path or die $!;
    while (<$fh>) {
        $pm_subs{$1} = 1 if /^sub ([A-Za-z][A-Za-z0-9_]*)\b/;
    }
}
{
    open my $fh, '<', $xs_path or die $!;
    my $in_xs = 0;
    my $prev_was_type;
    while (<$fh>) {
        $in_xs = 1 if /^MODULE = .*PACKAGE = ClickHouse::Encoder(?:::|$)/;
        next unless $in_xs;
        if ($prev_was_type && /^([A-Za-z][A-Za-z0-9_]*)\s*\(/) {
            $xs_subs{$1} = 1;
            $prev_was_type = 0;
        } else {
            $prev_was_type = (/^[A-Za-z_][A-Za-z0-9_ \*]*$/ && !/=cut/);
        }
    }
}

# 3. Tests: scan all .t files for `->NAME` invocations (followed by
# any non-identifier char so we don't match `->name_in_method_chain`).
my %tested;
for my $t (glob('t/*.t'), glob('t/lib/*.pm')) {
    open my $fh, '<', $t or next;
    while (<$fh>) {
        $tested{$1} = 1 while /->([A-Za-z_][A-Za-z0-9_]*)\b/g;
    }
}

# Public API surface = union of declared methods, minus Perl-built-ins.
my %all = map { $_ => 1 } keys %pm_subs, keys %xs_subs;
delete @all{ qw(DESTROY BOOT) };
delete @all{ grep { /^_/ } keys %all };
# The varint / length-string XS codecs in ClickHouse::Encoder::TCP are
# semi-public: callable (no underscore) and referenced in the TCP POD,
# but they are plain functions invoked as Pkg::name(...), not part of
# the ->method API surface this cross-check governs.
delete @all{ qw(pack_varint unpack_varint pack_string unpack_string) };

for my $m (sort keys %all) {
    my $defined    = $pm_subs{$m} || $xs_subs{$m};
    # POD documentation: looks for any literal mention of the method
    # name in POD text. Sub-object methods (push_row, reset, etc.)
    # documented inline under =head2 streamer satisfy this; top-level
    # methods documented via =head2 also satisfy it.
    my $documented = $pod_body =~ /\b\Q$m\E\b/;
    my $exercised  = $tested{$m};

    ok($defined,    "$m: defined in code (.pm or .xs)")
        or diag("no sub/XSUB named $m found");
    ok($documented, "$m: mentioned in POD")
        or diag("'$m' does not appear anywhere in @pm_paths POD body");
    ok($exercised,  "$m: exercised by tests")
        or diag("no '->$m' call found in any t/ file");
}

done_testing();
