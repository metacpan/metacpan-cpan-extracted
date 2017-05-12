use Test::More;

use_ok Catalyst::Authentication::Credential::GSSAPI;

my $v;

eval {
    $v = Catalyst::Authentication::Credential::GSSAPI::perform_negotiation();
};
ok($@, "die: $@");

eval {
    $v = Catalyst::Authentication::Credential::GSSAPI::perform_negotiation({});
    ok(!defined $v, 'should return undef with no token');
};
ok(!$@, "did not die: $@");


eval {
    $v = Catalyst::Authentication::Credential::GSSAPI::perform_negotiation
      ({ token => 'YIICoQYGKwYBBQUCoIIClTCCApGgJzAlBgkqhkiG9xIBAgIGBSsFAQUCBgkqhkiC9xIBAgIGBisGAQUCBaKCAmQEggJgYIICXAYJKoZIhvcSAQICAQBuggJLMIICR6ADAgEFoQMCAQ6iBwMFACAAAACjggFWYYIBUjCCAU6gAwIBBaEVGxNBRERFVi5CTE9PTUJFUkcuQ09Noj0wO6ADAgEDoTQwMhsESFRUUBsqcHVibGljLTEwMC03MC0xOC0zLmRvYjEuYmNwYy5ibG9vbWJlcmcuY29to4HwMIHtoAMCARKhAwIBA6KB4ASB3YSM+zt1d/TcIBM9l4Kfy9dYkilriZV9aP3IO96zvuhYf+5wxGfJV6CyMh799ILcJEfre9RR1MNujOBp4xzMNlECR+XGRgMhs8g6GkLrlG9spoRsP4CP4OovXDf3Rc8y0VHZWBZU+smq6JjPRISEEPbOUQmV/tHvO5VB6rO5XV5tO1e5vqgg7QMgg6H4pvkEmmldn4NerA9O5xq/sxySzMFnc9iHR7yb7mN7xFM67F/erzr6gOak2TscS1c4s4NcWVZz/p+BndGMeGESNUCwtZ/TxuZia+FhMsdyTFTNpIHXMIHUoAMCARKigcwEgcl9GqTSPbsn38q0CJZknALZA86UiAMuGudXLZoy/o/LploYJfHaAWC4/JU+uaqqjsdN55b6vAlEHX/1QleJTzn1Fl2+Ks0R3IhbeKBbDhykqykdJ+Sx27cKp37oDqXVR2NRuHkQe11GMUmhmJNVsM8Ecwd7tanSqLKaDAUmv5GFByFug+wRUa14AcCwEmgAmyEoM6WpQxbxu39DdavPa7TkO/4wE/2TgtC5Xflr84olD1Y+BgzobvHV/dNErSwoht/tfdlEhxWm1OQ=' });
    is(ref $v, 'HASH', 'should return a hash');
    ok(exists $v->{status}, "contains a status value");
};
ok(!$@, "did not die: $@");

done_testing();
