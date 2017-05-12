use Test::More tests => 37;
BEGIN { use_ok('DateTime::Format::Duration::XSD') };

ok (new DateTime::Format::Duration::XSD);

my $dfdx = new DateTime::Format::Duration::XSD;
my ($d, $d2);

sub test_reparse {
    my $d2 = $dfdx->parse_duration($dfdx->format_duration($_[0]));
    is (DateTime::Duration->compare($d2, $_[0]), 0);
}

ok ($d = $dfdx->parse_duration('P1Y1M1DT1H1M1S'));
is ($d->years(), 1);
is ($d->months(), 1);
is ($d->days(), 1);
is ($d->hours(), 1);
is ($d->minutes(), 1);
is ($d->seconds(), 1);
test_reparse($d);

ok ($d = $dfdx->parse_duration('-P1Y20M1D'));
is ($d->years(), 2);
is ($d->months(), 8);
is ($d->days(), 1);
is ($d->hours(), 0);
is ($d->minutes(), 0);
is ($d->seconds(), 0);
ok ($d->is_negative());
test_reparse($d);

ok ($d = $dfdx->parse_duration('PT1M1.1S'));
is ($d->years(), 0);
is ($d->months(), 0);
is ($d->days(), 0);
is ($d->hours(), 0);
is ($d->minutes(), 1);
is ($d->seconds(), 1);
is ($d->nanoseconds(), 1E8);
test_reparse($d);

ok ($d = $dfdx->parse_duration('-P1Y20M1DT62M0.33S'));
is ($d->years(), 2);
is ($d->months(), 8);
is ($d->days(), 1);
is ($d->hours(), 1);
is ($d->minutes(), 2);
is ($d->seconds(), 0);
is ($d->nanoseconds(), 3.3E8);
test_reparse($d);
