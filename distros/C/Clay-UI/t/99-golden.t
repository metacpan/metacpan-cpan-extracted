use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use JSON::PP;
use File::Spec;
use File::Basename qw(dirname);
use FindBin;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Golden-fixture comparison tests.
#
# Each fixture script under t/fixtures/*.pl builds a deterministic
# layout and is expected to produce the render command array stored in
# the matching .json file. The two are compared with deep equality
# after a small normalisation pass (floats rounded to 4 decimal
# places to absorb harmless precision wobble between platforms).
#
# Set CLAY_UI_UPDATE_FIXTURES=1 to overwrite the .json files with
# the current render output. Useful when intentionally changing a
# layout; commit the regenerated file.
# -----------------------------------------------------------------------------

my $fixtures_dir = File::Spec->catdir($FindBin::Bin, 'fixtures');
my @scripts      = sort glob File::Spec->catfile($fixtures_dir, '*.pl');

ok( scalar(@scripts) > 0, 'at least one fixture is present' );

# JSON encoder configured for stable, canonical output (sorted keys, no
# pretty-printing variability). canonical => 1 sorts hash keys; we still
# pretty-print so diffs read sensibly.
my $json = JSON::PP->new->canonical(1)->pretty->indent(1)->space_after(0);

# Recursively round numeric leaf values to N decimal places. This stops
# tiny float wobble (e.g. 50.00000003 vs 50) from breaking the test on
# platforms with slightly different float behaviour.
sub canonicalise ($node) {
    my $ref = ref $node;
    if ($ref eq 'HASH') {
        return { map { $_ => canonicalise($node->{$_}) } keys %$node };
    } elsif ($ref eq 'ARRAY') {
        return [ map { canonicalise($_) } @$node ];
    } elsif (defined $node && $node =~ /\A-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/) {
        my $rounded = sprintf '%.4f', $node + 0;
        $rounded =~ s/0+\z//;
        $rounded =~ s/\.\z/.0/;
        return $rounded + 0;
    }
    return $node;
}

for my $script (@scripts) {
    my $base    = $script =~ s{\.pl\z}{}r;
    my $name    = (File::Spec->splitpath($base))[2];
    my $goldenf = "${base}.json";

    subtest $name => sub {
        my $builder = do $script;
        die "fixture $script did not return a coderef: $@" unless ref($builder) eq 'CODE';

        my $cmds = $builder->();
        my $got  = canonicalise($cmds);

        if ($ENV{CLAY_UI_UPDATE_FIXTURES}) {
            open my $fh, '>:encoding(UTF-8)', $goldenf
                or die "open $goldenf: $!";
            print $fh $json->encode($got);
            close $fh;
            note "wrote fixture $goldenf";
            ok 1, "fixture regenerated";
            return;
        }

        if (!-f $goldenf) {
            fail "missing golden file $goldenf - run with CLAY_UI_UPDATE_FIXTURES=1 to create it";
            return;
        }

        open my $fh, '<:encoding(UTF-8)', $goldenf or die "open $goldenf: $!";
        local $/;
        my $expected_json = <$fh>;
        close $fh;
        my $expected = canonicalise($json->decode($expected_json));

        is( $got, $expected, "render commands match $name.json" );
    };
}

done_testing;
