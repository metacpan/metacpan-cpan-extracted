use ExtUtils::testlib;
use Test::More tests => 1;
BEGIN { 
    use_ok('Crypt::SMimeEngine', qw(&init &sign &verify &getFingerprint &getCertInfo &getErrStr &ossl_version));
};

