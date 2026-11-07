use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use Apophis;

# ap_abi.h publishes the content-addressing primitives so a consumer's XS can
# identify, shard and write a blob without a Perl frame between the two.
#
# The assertion worth having is not that the table exists - it is that the C
# path and the Perl path AGREE. Two implementations of one algorithm agreeing
# is something to check, not something to assume, and the failure mode if they
# ever disagree is that blobs written one way become unreachable the other.

my $dir = tempdir(CLEANUP => 1);
open my $null, "<", File::Spec->devnull or die "devnull: $!";

# ---------------------------------------------------------------- the table

my $ptr = Apophis::_abi_ptr();

# `!= 0`, never `> 0`: the address is returned as a UV because PTR2IV hands
# back a negative integer wherever the .so maps with the top bit set, and a
# `> 0` check would then fail on a perfectly usable pointer.
ok(defined $ptr && $ptr != 0,
    '_abi_ptr gives back the address of the process-wide table');

is(Apophis::_abi_ptr(), $ptr,
    '...the same address every time - one table for the process, not a copy '
  . 'per caller');

# ------------------------------------------------- the C path and the Perl path

my $store = Apophis->new(namespace => 'abi-test', store_dir => $dir);

my $content = "the quick brown fox jumps over the lazy dog\n" x 40;

my $copy = File::Spec->catfile($dir, 'a-copy-of-the-content');
open my $out, '>', $copy or die "$copy: $!";
print $out $content;
close $out;
open my $in, '<', $copy or die "$copy: $!";

my ($c_id, $c_path, $c_ns, $fh_id, $short_rc, $probe_rc, $probe_dirlen, $null_rc) = Apophis::_abi_selftest($store, \$content, 'abi-test', $in);

is($c_ns, $store->namespace,
    'derive_ns on the namespace string gives the namespace new() derived, so a '
  . 'consumer with only the string reaches the same store');
is($fh_id, $c_id,
    'identify_fh over a handle on the same bytes gives the same id as identify '
  . 'over the scalar, chunking and namespace prefix included');
is($short_rc, -1, 'build_path reports a short id as -1 rather than croaking, so a consumer can refuse it');
is($probe_rc, 3, 'store_of asked for the namespace alone, the directory alone or its length alone says it is a store each time');
is($probe_dirlen, length $dir, 'and asked for the directory length alone gives it');
is($null_rc, 0, 'store_of on a NULL pointer says it is no store, so a consumer need not check first');
close $in;

like($c_id, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    'the table produces a well-formed v5 UUID');

my $p_id = $store->store(\$content);

is($c_id, $p_id,
    'THE GATE: the id through the C table is the id through store() - if '
  . 'these ever diverge, every blob written by one path is invisible to the '
  . 'other while staying perfectly findable by its own');

is($c_path, $store->path_for($p_id),
    '...and it shards to the same path, because the consumer calls '
  . 'build_path rather than reimplementing the layout');

ok(-e $c_path, 'the table actually wrote the blob');

is(${ $store->fetch($p_id) }, $content,
    'and fetch reads back exactly what write_atomic wrote - the bytes agree, '
  . 'not just the name');

# The other direction: a blob the Perl API wrote must be found by the C path.
my $other = "written by the Perl API\n";
my $o_id  = $store->store(\$other);
my ($o_c_id, $o_c_path) = Apophis::_abi_selftest($store, \$other, "abi-test", $null);

is($o_c_id, $o_id, 'a blob stored through Perl is identified identically in C');
is($o_c_path, $store->path_for($o_id), '...and resolves to the one file');

# ----------------------------------------------------------- the namespace

# A different namespace must give a different id for identical bytes - that is
# the property Punk::Plugin::Blob's per-tenant namespacing rests on, and it
# has to hold on the C path too or the tenancy story is only true in Perl.
my $other_ns = Apophis->new(namespace => 'abi-test-2', store_dir => $dir);
my ($n_id) = Apophis::_abi_selftest($other_ns, \$content, "abi-test-2", $null);

isnt($n_id, $c_id,
    'the same bytes under a different namespace get a different id through '
  . 'the table, which is what per-tenant namespacing depends on');

# ------------------------------------------------------------- store_of

# store_of has to be safe to call on anything, because a consumer probes with
# it before deciding whether it can use the C path at all. A croak there would
# turn a fall-back into a fatal error.
my $undef_dir = Apophis->new(namespace => 'abi-test');
$undef_dir->{store_dir} = undef;
for my $not_a_store ([], {}, \"scalar", undef, 'Apophis', 42, bless([], 'Apophis'), bless({}, 'Apophis'),
                     bless({ _ns_bytes => 'short', store_dir => $dir }, 'Apophis'),
                     bless({ _ns_bytes => undef, store_dir => $dir }, 'Apophis'), $undef_dir) {
    my $ok = eval { Apophis::_abi_selftest($not_a_store, \"x", "x", $null); 1 };
    ok(!$ok, 'a non-store is refused rather than crashed on');
    like($@, qr/not a store/, '...with an error saying so');
}

# An object with no store_dir is not a usable store either, and store_of says
# so by returning false rather than by croaking somewhere further in.
my $dirless = Apophis->new(namespace => 'abi-test');
my $ok = eval { Apophis::_abi_selftest($dirless, \"x", "x", $null); 1 };
ok(!$ok, 'a store with no store_dir is refused - there is nowhere to write');

$ok = eval { Apophis::_abi_selftest($store, 'not a reference', 'x', $null); 1 };
ok(!$ok, 'the content must come as a reference');
like($@, qr/^Apophis::_abi_selftest: content must be a scalar reference/, '...and the complaint says so');

my $far = Apophis->new(namespace => 'abi-test', store_dir => File::Spec->catdir($dir, 'z' x 4200));
$ok = eval { Apophis::_abi_selftest($far, \"x", 'x', $null); 1 };
ok(!$ok, 'a store whose paths cannot fit the buffer is refused by the length build_path reports');
like($@, qr/^Apophis::_abi_selftest: path too long/, '...which is the check a consumer must make too');

# ------------------------------------------------------------- idempotence

# Content addressing is idempotent, so running the C path twice must be a
# no-op rather than a second write. This is what makes the whole scheme safe
# to retry.
my ($again_id, $again_path) = Apophis::_abi_selftest($store, \$content, "abi-test", $null);
is($again_id, $c_id, 'storing the same content again gives the same id');
is($again_path, $c_path, '...to the same path');
is(${ $store->fetch($c_id) }, $content, '...and has not corrupted the blob');

done_testing;
