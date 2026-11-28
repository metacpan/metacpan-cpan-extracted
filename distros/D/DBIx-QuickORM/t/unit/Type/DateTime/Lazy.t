# Test origin: AI
use Test2::V0;

use DateTime;
use Data::Dumper;
use Scalar::Util qw/refaddr/;
use DBIx::QuickORM::Type::DateTime::Lazy;

my $LAZY  = 'DBIx::QuickORM::Type::DateTime::Lazy';
my $built = 0;

sub lazy {
    my ($kind, %dt) = @_;
    return $LAZY->new(sub { $built++; DateTime->new(year => 2024, month => 2, day => 3, hour => 4, %dt) }, $kind);
}

my $lazy = lazy('timestamp');
ok($lazy, "is true");
is($built, 0, "without building the DateTime");
like(Dumper($lazy), qr/sub \{/, "A dump shows only a code reference");
unlike(Dumper($lazy), qr/2024/, "not the value");
ok(!$lazy->isa('DateTime'), "It is not a DateTime");
ok(!$lazy->can('year'),     "and has no DateTime methods");

my $ref = $lazy->datetime_ref;
isa_ok($ref, ['DateTime'], "datetime_ref gives the DateTime");
ref_is($lazy->datetime_ref, $ref, "the same one each time");
is($built, 1, "built once");

my $copy = $lazy->datetime;
isa_ok($copy, ['DateTime'], "datetime gives a DateTime");
ok(refaddr($copy) != refaddr($ref), "a copy");
$copy->add(days => 10);
is($lazy->datetime_ref->day, 3, "Changing the copy leaves the value alone");

subtest string => sub {
    is(lazy('timestamp')->string,                            '2024-02-03T04:00:00',       "A timestamp is ISO 8601 without an offset");
    is("" . lazy('timestamp'),                               '2024-02-03T04:00:00',       "and stringifies to it");
    is(lazy('timestamp', time_zone => '+0530')->string,      '2024-02-03T04:00:00',       "even when its DateTime has a zone");
    is(lazy('timestamp', nanosecond => 120_000_000)->string, '2024-02-03T04:00:00.12',    "Fractional seconds show when there are any");
    is(lazy('timestamptz', time_zone => 'UTC')->string,      '2024-02-03T04:00:00+00:00', "A timestamp with time zone always has its offset");
    is(lazy('timestamptz', time_zone => '-0700')->string,    '2024-02-03T04:00:00-07:00', "any offset");
    is(lazy('date')->string,                                 '2024-02-03',                "A date is only its date");

    my $bad = $LAZY->new(sub { die "Cannot parse 'soon'\n" }, 'timestamp');
    like(dies { "$bad" }, qr/^Cannot parse 'soon'/, "A value that does not parse croaks when stringified");
};

subtest compare => sub {
    my $early = lazy('timestamp', month => 1);
    my $late  = lazy('timestamp', month => 12);
    my $dt    = DateTime->new(year => 2024, month => 6, day => 1);

    is($early <=> $late,  -1, "<=> compares two lazy values");
    is($late  <=> $early,  1, "both ways");
    is($early <=> $dt,    -1, "and against a DateTime");
    is($early cmp $dt,    -1, "cmp compares the dates too");

    ok($early < $late,                          "< works");
    ok($late >= $dt,                            ">= works");
    ok($early == lazy('timestamp', month => 1), "== compares the dates");
    ok($early != $late,                         "!= too");
    ok($early eq lazy('timestamp', month => 1), "eq compares the dates");
    ok($early lt $dt,                           "lt too");
    is([map { $_->string } sort { $a <=> $b } $late, $early], ['2024-01-03T04:00:00', '2024-12-03T04:00:00'], "so they sort");
    like(dies { my $x = $dt <=> $early }, qr/compared to another DateTime/, "A DateTime on the left uses its own overload, which croaks");
    is($dt <=> $early->datetime_ref, 1, "so it takes datetime_ref");

    my $err;
    my $warned = warnings {
        $err = dies { my $x = $early eq '2024-01-03T04:00:00' }
    };    # DateTime warns that the string is not a number
    like($err,                         qr/compared to another DateTime/, "Comparing with a string croaks");
    like(dies { my $x = $early == 1 }, qr/compared to another DateTime/, "and with a number");
};

done_testing;
