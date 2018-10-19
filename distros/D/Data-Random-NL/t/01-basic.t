use strict;
use warnings;

use Test::More;
use Test::Exception;

use Data::Random::NL qw(:all);

#
# BTTW::Tools is a Mintlab specific piece of code that needs to be
# publised on CPAN. I'm looking into getting elfproef merged into:
# https://metacpan.org/release/Algorithm-CheckDigits
# Mailed the author to check how to apply patches.
#
# If we are on a installing this module on something where BTTW::Tools
# is installed we use BTTW::Tools elfproef and do actual elfproef
# checks. These checks will work on the authors machine. Trust me CPAN
# ;)
#

eval "use BTTW::Tools qw(elfproef)";
my $elfproef = 1;
if ($@) {
    $elfproef = 0;
}


{
    note("generate_bsn");
    my $bsn = generate_bsn();
    is(length($bsn), 9, "$bsn is 9 chars long");
    ok(elfproef($bsn, 1), ".. and is elfproef") if $elfproef;

    my $start = int(rand(10));
    $bsn = generate_bsn($start);
    ok(elfproef($bsn, 1), "generate_bsn ($bsn) is BSN elfproef") if $elfproef;
    like($bsn, qr/^$start/, ".. and starts with '$start'");
    ok(elfproef($bsn, 1), ".. and is elfproef") if $elfproef;
}

{
    note("generate_rsin");
    my $rsin = generate_rsin();
    is(length($rsin), 9, "$rsin is 9 chars long");
    ok(elfproef($rsin), ".. and is elfproef") if $elfproef;

    my $start = int(rand(10));
    $rsin = generate_rsin($start);
    is(length($rsin), 9, "$rsin is 9 chars long");
    ok(elfproef($rsin), ".. and is elfproef") if $elfproef;
    like($rsin, qr/^$start/, ".. and starts with '$start'");
}

{
    note("generate_kvk");
    my $kvk = generate_kvk();
    is(length($kvk), 8, "$kvk is 8 chars long");
    ok(elfproef($kvk), "and is elfproef") if $elfproef;

    my $start = int(rand(10));
    $kvk = generate_kvk($start);
    is(length($kvk), 8, "$kvk is 8 chars long");
    ok(elfproef($kvk), "and is elfproef") if $elfproef;
    like($kvk, qr/^$start/, ".. and starts with '$start'");
}

{
    note("generate_vestigingsnummer");
    my $vestigingsnummer = generate_vestigingsnummer();
    is(length($vestigingsnummer), 12, "$vestigingsnummer is 12 chars long");

    my $start = int(rand(10));
    $vestigingsnummer = generate_vestigingsnummer($start);
    like($vestigingsnummer, qr/^$start/,
        "$vestigingsnummer starts with a $start");
    is(length($vestigingsnummer), 12, ".. and is 12 chars long");
}

{
    note("starts_with");
    lives_ok(
        sub {
            my @arr = ();
            Data::Random::NL::_starts_with(\@arr, 2);
            is_deeply(\@arr, [2], "Array starts with 2");
        },
        "Must start with a number: 2"
    );

    throws_ok(
        sub {
            Data::Random::NL::_starts_with([], 'xxxfarb');
        },
        qr/You did not provide a number/,
        "Must start with a number: string"
    );

    throws_ok(
        sub {
            Data::Random::NL::_starts_with([], '20');
        },
        qr/You did not provide a number/,
        "Must start with a number: 20"
    );
}

done_testing;
