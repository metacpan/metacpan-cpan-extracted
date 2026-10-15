#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;

use FindBin;
use IPC::Cmd qw/can_run/;
use Scalar::Util qw/reftype/;

use BioX::Tax::Kraken;

my $has_xz = can_run('xz');
chdir $FindBin::Bin;

my $test_db         = 'test_data/taxDB.sub';
my $test_db_xz      = 'test_data/taxDB.sub.xz';
my $test_db_trunc   = 'test_data/taxDB.trunc';
my $test_db_loop    = 'test_data/taxDB.loop';

# Test database loading
my $tax = BioX::Tax::Kraken->new($test_db);

isa_ok(
    $tax => ['BioX::Tax::Kraken'],
    "returned BioX::Tax::Kraken object"
);

# Test name() method
is(
    $tax->name(9031) => 'Gallus gallus',
    'name() returns correct species name'
);
is(
    $tax->name(9030) => 'Gallus',
    'name() returns correct genus name'
);
is(
    $tax->name(99999) => undef,
    'name() returns undef for invalid ID'
);

# Test rank() method
is(
    $tax->rank(9031) => 'species',
    'rank() returns correct rank for species'
);
is(
    $tax->rank(9030) => 'genus',
    'rank() returns correct rank for genus'
);
is(
    $tax->rank(99999) => undef,
    'rank() returns undef for invalid ID'
);

# Test parent() method
is(
    $tax->parent(9031) => '9030',
    'parent() returns correct parent ID'
);
is(
    $tax->parent(9030) => '9072',
    'parent() returns correct parent for genus'
);
is(
    $tax->parent(99999) => undef,
    'parent() returns undef for invalid ID'
);

# Test is_ancestor() method
ok(
    $tax->is_ancestor(9031, 9030),
    'is_ancestor() detects direct parent'
);
ok(
    $tax->is_ancestor(9031, 9005),
    'is_ancestor() detects distant ancestor'
);
ok(
    $tax->is_ancestor(9031, 7742),
    'is_ancestor() detects Vertebrata ancestor'
);
ok(
    !$tax->is_ancestor(9031, 3880),
    'is_ancestor() returns false for non-ancestor'
);
ok(
    !$tax->is_ancestor(9031, 9031),
    'is_ancestor() returns false for self-compare'
);
is(
    $tax->is_ancestor(99999, 9030) => undef,
    'is_ancestor() returns undef for invalid child ID'
);
is(
    $tax->is_ancestor(9031, 99999) => undef,
    'is_ancestor() returns undef for invalid parent ID'
);
# quick checks of alias
ok(
    $tax->a_isa_b(9031, 7742),
    'a_isa_b() detects Vertebrata ancestor'
);
ok(
    !$tax->a_isa_b(9031, 3880),
    'a_isa_b() returns false for non-ancestor'
);

# Test lineage() method
my @lineage = $tax->lineage(9031);
ok(
    @lineage > 1,
    'lineage() returns multiple IDs'
);
is(
    $lineage[0] => '1',
    'lineage() starts with root'
);
is(
    $lineage[-1] => '9031',
    'lineage() ends with query ID'
);
ok(
    grep { $_ eq '9030' } @lineage,
    'lineage() contains parent'
);
is(
    $tax->lineage(99999) => undef,
    'lineage() returns undef for invalid ID'
);
@lineage = $tax->lineage(9031);
ok(
    @lineage > 1,
    'lineage() still returns multiple IDs'
);
is(
    $lineage[0] => '1',
    'lineage() still starts with root'
);
is(
    $lineage[-1] => '9031',
    'lineage() still ends with query ID'
);
ok(
    grep { $_ eq '9030' } @lineage,
    'lineage() still contains parent'
);
@lineage = $tax->lineage(1);
ok(
    @lineage == 1,
    'lineage(1) returns exactly one ID'
);

# Test children() method
my @children = $tax->children(9030);
ok(
    @children > 0,
    'children() returns at least one child'
);
ok(
    grep { $_ eq '9031' } @children,
    'children() includes expected child (9031)'
);
is(
    $tax->children(99999) => undef,
    'children() returns undef for invalid ID'
);

# Test lca() method with two IDs
my $lca = $tax->lca(9031, 3877);
ok(
    defined $lca,
    'lca() returns defined value for two valid IDs'
);
is(
    $tax->name($lca) => 'Eukaryota',
    'lca(9031, 3877) returns Eukaryota'
);

# Test lca() with same lineage
$lca = $tax->lca(9031, 9072);
is(
    $lca => '9072',
    'lca(9031, 9072) returns Phasianinae'
);

# Test lca() with multiple IDs
$lca = $tax->lca(9031, 3880, 129337);
is(
    $lca => '131567',
    'lca() with 3+ IDs returns common ancestor'
);

# Test lca() with non-intersecting multiple IDs
$lca = $tax->lca(9031, 3880, 44770);
is(
    $lca => '1',
    'lca() returns root if appropriate'
);

# Test lca() with invalid ID
is(
    $tax->lca(9031, 99999) => undef,
    'lca() returns undef if any ID is invalid'
);
is(
    $tax->lca() => undef,
    'lca() returns undef with no arguments'
);

SKIP: {
    skip("Skipping xz tests, xz not available")
        if (! $has_xz);
    my $tax_xz = BioX::Tax::Kraken->new($test_db_xz);

    isa_ok(
        $tax_xz,
        ['BioX::Tax::Kraken'],
        "returned BioX::Tax::Kraken object from xz file"
    );
    
    # Verify xz-loaded database works correctly
    is(
        $tax_xz->name(9031) => 'Gallus gallus',
        'name() works on xz-compressed database'
    );
    is(
        $tax_xz->rank(9031) => 'species',
        'rank() works on xz-compressed database'
    );
}

like(
    dies { BioX::Tax::Kraken->new($test_db_trunc) },
    qr/Invalid taxDB format/,
    'Constructor throws expected error on bad input'
);

$tax = BioX::Tax::Kraken->new($test_db_loop);
like(
    dies { $tax->is_ancestor(99992, 1) },
    qr/Cycle detected/,
    'is_ancestor() throws expected error on cylical path'
);
like(
    dies { $tax->lineage(99993) },
    qr/Cycle detected/,
    'lineage() throws expected error on cylical path'
);

done_testing;
exit;

