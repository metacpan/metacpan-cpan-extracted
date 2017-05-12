#! perl -w
use strict;

use Test::More;
use Test::Exception;

use Business::IBAN::Validator;

{
    my $v = Business::IBAN::Validator->new();
    isa_ok($v, 'Business::IBAN::Validator');

    my $iban = 'XX';
    throws_ok(
        sub { $v->validate($iban) },
        qr/^'XX' is not an IBAN country code.\n\z/,
        "Not an IBAN country code"
    );

    $iban = 'NL00ABNA123456789';
    throws_ok(
        sub { $v->validate($iban) },
        qr/^'$iban' has incorrect length 17 \(expected 18 for The Netherlands\).\n\z/,
        "invalid length"
    );

    $iban = 'NL00ABNA123456789x';
    throws_ok(
        sub { $v->validate($iban) },
        qr/^'NL00ABNA123456789x' does not match the pattern 'NL2!n4!a10!n'for The Netherlands./,
        "Pattern check"
    );

    $iban = 'NL00ABNA0123456789';
    throws_ok(
        sub { $v->validate($iban) },
        qr/^'NL00ABNA0123456789' does not comply with the 97-check./,
        "97-check"
    );

    # AUTOLOAD
    lives_ok(
        sub { $v->NL->{is_sepa} },
        "AUTOLOAD() works."
    );
    throws_ok(
        sub { $v->XX->{is_sepa} },
        qr/^'XX' is not a valid IBAN country code./,
        "(AUTOLOAD) Unknown country code."
    );

    # Restricted hash
    throws_ok(
        sub { $v->{XX} = {} },
        qr/^Attempt to access disallowed key 'XX' in a restricted hash/,
        "Cannot modify the validator"
    );

    $v = undef;
}

done_testing();
