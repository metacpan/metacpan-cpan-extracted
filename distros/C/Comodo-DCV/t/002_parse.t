
use strict;
use warnings;

use Test::More;
plan tests => 4;

use MIME::Base64;

use Comodo::DCV ();

{
    local $@;
    eval { my $v = Comodo::DCV::get_filename_and_contents('blahblah') };
    like( $@, qr<list>, 'complains about scalar context' );

    eval { Comodo::DCV::get_filename_and_contents('blahblah') };
    like( $@, qr<list>, 'complains about void context' );
}

my $csr1 = <<END;
MIICZDCCAUwCAQAwHzEdMBsGA1UEAxMUaGlsZGVnYXJkY29uc29ydC5vcmcwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDaZfjPl2Q7oFs1bX98FmAmKmjM
9WX23YydHvH4421Jeneuecj0u84Rv4hNNEnBlL/6wsg9z1V6eHPPfZ99h/uZlsAV
K/O1uHWVDpA7pLUCn68jT+FnX7kMtLxXZRcHHaZziWTX+MPd88XXhI+Xbe/r0l40
ul0uDeS0jzGkhsooygNBVZUw4njTSvWpMU1qyH236EQCwRSUAFHFJBjWgswSltgg
aqOjJduPcJFc/Irf0mfLfxrYAx3O4iLkEUHJutpSo3JQDWsc8dxFPa2ZsqlOtVTC
1pOwivRFM76d8JHrCnk4zDxgAsWfdxuTxTHlq7ur9TYoHOnPtndg3RPDFL1BAgMB
AAGgADANBgkqhkiG9w0BAQUFAAOCAQEASWmgC4IDZodTZehlN1VmdoV6wskNXJVx
ea8HCDMzgGesgb7IrRRYQGErXTXzvz4uRmicOqqrV9heR27WvlF9pDfvjvPR2dMD
I66CrLmPYZlwvFsZM34tEUH0upwMduO24bZmEd1A2Elwq2Eptpw9+BBAFo26AC9c
jJlH8fF7I8YqYmlwrtXFHonMMmOcAR0VmD9LZ417cgyX8IJ8xiPGYbRRQkowJZod
wYTSj+q11ZU0Tc0GcikYPEJPah5K+fL+lxJrEurnqBolZbR0Zk6B4CtFNOELhI+2
7I54DyluCoLWDzweC97dDi9JFCl1afV9y8p4GCuq8aD2/TQQWyUjaw==
END

my $csr1_der = MIME::Base64::decode($csr1);

my ( $filename, $contents ) = Comodo::DCV::get_filename_and_contents($csr1_der);
is( $filename, '4547FDDC7118AC1B676C964534F2DB10.txt', 'filename of sample CSR' );

is(
    $contents,
    "917e8c29d9695f4663635df925f2b528ffa7bd67$/comodoca.com",
    'contents',
);
