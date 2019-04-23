BEGIN { $| = 1; print "1..29\n"; }

use common::sense;
use Convert::BER::XS qw(:encode :decode :const);

our $test;
sub ok($) {
   print $_[0] ? "" : "not ", "ok ", ++$test, "\n";
}

ok (ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_UNIVERSAL, ASN_INTEGER,     0,     5);
ok (ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], undef        , ASN_INTEGER,     0,     5);
ok (ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_UNIVERSAL, undef      ,     0,     5);
ok (ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_UNIVERSAL, ASN_INTEGER, undef,     5);
ok (ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_UNIVERSAL, ASN_INTEGER,     0, undef);

ok (!ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_UNIVERSAL, ASN_INTEGER,     0, 4);
ok (!ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_UNIVERSAL, ASN_INTEGER,     1, 5);
ok (!ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], ASN_APPLICATION, ASN_INTEGER);
ok (!ber_is [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], undef, ASN_BOOLEAN);

ok (ber_is [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, 5], undef, undef, undef, 5);
ok (!ber_is [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "5 "], undef, undef, undef, 5);
ok (ber_is [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "5 "], undef, undef, undef, "5 ");

ok (ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], 5);
ok (5 == ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 0, 5], 5);
ok (ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 0, 0], 0);
ok (0 == ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 0, 0], 0);
ok (ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 0, 0]);
ok (!ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 1, 3], 3);
ok (!ber_is_int [ASN_UNIVERSAL, ASN_INTEGER, 1, 0]);
ok (!ber_is_int [ASN_PRIVATE, ASN_INTEGER, 0, 0]);

ok (ref ber_is_seq [ASN_UNIVERSAL, ASN_SEQUENCE, 1, []]);
ok (!ref ber_is_seq [ASN_UNIVERSAL, ASN_SEQUENCE, 0, []]);
ok (!ref ber_is_seq [ASN_APPLICATION, ASN_SEQUENCE, 1, []]);
ok (ber_is_oid [ASN_UNIVERSAL, ASN_OID, 0, "1.2.3"]);
ok (ber_is_oid [ASN_UNIVERSAL, ASN_OID, 0, "1.2.3"], "1.2.3");
ok (!ber_is_oid [ASN_CONTEXT, ASN_OID, 0, "1.2.3"], "1.2.3");
ok (!ber_is_oid [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "1.2.3"], "1.2.3");

ok (ber_is_int +(ber_int 5), 5);
ok (ber_is_int +(ber_int 0), 0);

