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
    ok(elfproef($bsn, 1), "generate_bsn ($bsn) is BSN elfproef") if $elfproef;
    is(length($bsn), 9, "$bsn is 9 chars long");

    my $start = int(rand(10));
    $bsn = generate_bsn($start);
    ok(elfproef($bsn, 1), "generate_bsn ($bsn) is BSN elfproef") if $elfproef;
    like($bsn, qr/^$start/, "$bsn starts with a $start");
}

{
    note("generate_rsin");
    my $rsin = generate_rsin();
    ok(elfproef($rsin), "generate_rsin ($rsin) is elfproef") if $elfproef;
    is(length($rsin), 9, "$rsin is 9 chars long");

    my $start = int(rand(10));
    $rsin = generate_rsin($start);
    ok(elfproef($rsin), "generate_rsin ($rsin) is elfproef") if $elfproef;
    like($rsin, qr/^$start/, "$rsin starts with a $start");
}

{
    note("generate_kvk");
    my $kvk = generate_kvk();
    ok(elfproef($kvk), "generate_kvk ($kvk) is elfproef") if $elfproef;
    is(length($kvk), 8, "$kvk is 9 chars long");

    my $start = int(rand(10));
    $kvk = generate_kvk($start);
    ok(elfproef($kvk), "generate_kvk ($kvk) is elfproef") if $elfproef;
    like($kvk, qr/^$start/, "$kvk starts with a $start");
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
