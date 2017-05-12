# Test fetching

use Test::More;
use DBI;
use strict;
$|=1;

my @len = (1, 10, 50, 100, 1000, 1467, 1468, 2000, 3000, 4000, 4466,
           4467, 5000, 10000, 20000, 30000, 40000);

# 1487 goes into an infinite loop; apparently, so does 1487 + (N * 1500) for
# integer N
my %bad_len = map { $_ => 1 } 1487, 2987, 4487;
push @len, sort keys %bad_len;

if (defined $ENV{DBI_DSN}) {
    plan tests => 22 + 3 * @len;
}
else {
    plan skip_all => 'Cannot run test unless DBI_DSN is defined. See the README file.';
}

my $db = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                       {RaiseError => 1, PrintError => 0, AutoCommit => 1});

ok(defined $db, "Connect to database for testing result fetches");

# XXX: This test only works on recent-enough versions of PostgreSQL, which
# give a warning for string literals that use backslashes
ok($db->do(q[SELECT '\\\\' AS a]),
   'Syntax warning is handled correctly');

{
    # This tests assembling parsed statements and query arguments into whole
    # statements
    my $data = $db->selectall_arrayref(q[
        SELECT ? AS a, ? AS b, ? AS c
    ], {Slice => {}}, 'a', 'b', undef);
    is_deeply($data, [{a => 'a', b => 'b', c => undef}],
              'Three-param statement returns correct data');
}

{
    my $data = $db->selectall_arrayref(
        q[SELECT /* ? */ '?' AS "a?", ? AS b], {Slice => {}}, 'b?');
    is_deeply($data, [{'a?' => '?', b => 'b?'}],
              'Literal and commented "?" parsed correctly');
}

{
    # This tests that argument values containing "?" don't affect parsing; see
    # https://rt.cpan.org/Ticket/Display.html?id=23900
    my $data = $db->selectall_arrayref(
        q[SELECT ? AS a, ? AS b], {Slice => {}}, 'a?', 'b');
    is_deeply($data, [{a => 'a?', b => 'b'}],
              'Arg with "?" returns correct data');
}

{
    my $st = $db->prepare(q[SELECT 1 AS a WHERE false]);
    ok($st->execute, 'Execute prepared statement');
    is_deeply($st->fetchall_arrayref, [], 'First fetch');
    # XXX: second fetch is likely to block on a non-forthcoming packet if
    # there's a bug.
    is_deeply($st->fetchall_arrayref, [], 'Second fetch');
}

{
    my $data = $db->selectall_arrayref(q[SELECT '\\\\000\\\\001'::bytea AS a]);
    is_deeply($data, [["\000\001"]], 'Bytea demangling works');
}

{
    my $st = $db->prepare(q[SELECT ? AS a]);

    $st->bind_param(1, 'foo');
    $st->execute;
    is_deeply($st->fetchall_arrayref, [['foo']], 'trivial bind_param');

    $st->bind_param(1, 'foo', 25); # type with OID 25 is text
    $st->execute;
    is_deeply($st->fetchall_arrayref, [['foo']], 'minimal typed bind_param');
}

{
    my $data = eval { $db->selectall_arrayref(q[SELECT ? AS a]) };
    my $err = $@;
    ok(!$data, 'Execute with too few params fails');
    like($err, qr/Wrong number /,
         'Execute with too few params dies well');
}

{
    my $data = eval {
        $db->selectall_arrayref(q[SELECT ? AS a], undef, 'a', 'b') };
    my $err = $@;
    ok(!$data, 'Execute with too many params fails');
    like($err, qr/Wrong number /,
         'Execute with too many params dies well');
}

{
    my $st = $db->prepare(q[SELECT ? AS a]);

    my $data = eval { $db->selectall_arrayref($st) };
    my $err = $@;
    ok(!$data, 'Execute with too few bound params fails');
    like($err, qr/Wrong number /,
         'Execute with too few bound params dies well');

    $st->bind_param(1, 'a');
    $st->bind_param(2, 'b');
    $data = eval { $db->selectall_arrayref($st) };
    $err = $@;
    ok(!$data, 'Execute with too many bound params fails');
    like($err, qr/Wrong number /,
         'Execute with too many bound params dies well');
}

{
    my $st = eval { $db->prepare(qq[SELECT ? AS a\0]) };
    my $err = $@;
    ok(!$st, 'Preparing a query containing \0 fails');
    like($err, qr/\\0 byte/, 'Preparing a query containing \0 dies well');
}

{
    my $data = $db->selectall_arrayref(q[SELECT ? AS a], undef, "a\0b");
    is_deeply($data, [['a']], 'Quoting \0 works as well as possible');
}

for (@len) {
    my $value = $db->selectrow_array(qq[SELECT Repeat('a', $_)]);
    ok(defined $value, "Long result row returned ($_)");

    # We avoid testing the fetched value against the expected one directly,
    # because in verbose mode we end up with ginormous strings being dumped
    # to your terminal as the "expected" value.  Instead, just check that
    # every value is "suitable" (contains nothing but 'a'), and that it has
    # the right length; those two together test that it's the expected value.
    like($value, qr/^a*\z/, "Long result row of $_ bytes has suitable value");
    is(length $value, $_, "Long result row has correct length ($_)");
}
