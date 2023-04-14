#! perl -I. -w
use t::Test::abeltje;

use Business::IBAN::Validator;

{
    my $v = Business::IBAN::Validator->new();
    isa_ok($v, 'Business::IBAN::Validator');

    my $iban = 'XX';
    my $e = exception { $v->validate($iban) };
    like(
        $e,
        qr/^'XX' is not an IBAN country code.\n\z/,
        "Not an IBAN country code"
    );

    $iban = 'NL00ABNA123456789';
    $e = exception { $v->validate($iban) };
    like(
        $e,
        qr/^'$iban' has incorrect length 17 \(expected 18 for Netherlands \(The\)\).\n\z/,
        "invalid length"
    );

    $iban = 'NL00ABNA123456789x';
    $e = exception { $v->validate($iban) };
    like(
        $e,
        qr/^'NL00ABNA123456789x' does not match the pattern 'NL2!n4!a10!n'for Netherlands/,
        "Pattern check"
    );

    $iban = 'NL00ABNA0123456789';
    $e = exception { $v->validate($iban) };
    like(
        $e,
        qr/^'NL00ABNA0123456789' does not comply with the 97-check./,
        "97-check"
    );

    # AUTOLOAD
    lives_ok(
        sub { $v->NL->{is_sepa} },
        "AUTOLOAD() works."
    );

    $e = exception { $v->XX->{is_sepa} };
    like(
        $e,
        qr/^'XX' is not a valid IBAN country code./,
        "(AUTOLOAD) Unknown country code."
    );

    # Restricted hash
    $e = exception { $v->{XX} = {} };
    like(
        $e,
        qr/^Attempt to access disallowed key 'XX' in a restricted hash/,
        "Cannot modify the validator"
    );

    $v = undef;
}

abeltje_done_testing();
