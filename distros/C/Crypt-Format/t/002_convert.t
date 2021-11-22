use strict;
use warnings;

use Test::More tests => 9;                      # last test to print
use Test::FailWarnings;
use Test::Exception;

use Crypt::Format;
use Digest::MD5;

my $csr = <<END;
-----BEGIN CERTIFICATE REQUEST-----
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
-----END CERTIFICATE REQUEST-----
END

my $csr_unix = $csr;
$csr_unix =~ s<\x0d?\x0a><\x0a>g;

my $csr_windows = $csr_unix;
$csr_windows =~ s<\x0a><\x0d\x0a>g;

my $der_hex = '308202643082014c020100301f311d301b0603550403131468696c646567617264636f6e736f72742e6f726730820122300d06092a864886f70d01010105000382010f003082010a0282010100da65f8cf97643ba05b356d7f7c1660262a68ccf565f6dd8c9d1ef1f8e36d497a77ae79c8f4bbce11bf884d3449c194bffac2c83dcf557a7873cf7d9f7d87fb9996c0152bf3b5b875950e903ba4b5029faf234fe1675fb90cb4bc576517071da6738964d7f8c3ddf3c5d7848f976defebd25e34ba5d2e0de4b48f31a486ca28ca0341559530e278d34af5a9314d6ac87db7e84402c114940051c52418d682cc1296d8206aa3a325db8f70915cfc8adfd267cb7f1ad8031dcee222e41141c9bada52a372500d6b1cf1dc453dad99b2a94eb554c2d693b08af44533be9df091eb0a7938cc3c6002c59f771b93c531e5abbbabf536281ce9cfb67760dd13c314bd410203010001a000300d06092a864886f70d010105050003820101004969a00b820366875365e86537556676857ac2c90d5c957179af070833338067ac81bec8ad145840612b5d35f3bf3e2e46689c3aaaab57d85e476ed6be517da437ef8ef3d1d9d30323ae82acb98f619970bc5b19337e2d1141f4ba9c0c76e3b6e1b66611dd40d84970ab6129b69c3df81040168dba002f5c8c9947f1f17b23c62a626970aed5c51e89cc32639c011d15983f4b678d7b720c97f0827cc623c661b451424a30259a1dc184d28feab5d595344dcd067229183c424f6a1e4af9f2fe97126b12eae7a81a2565b474664e81e02b4534e10b848fb6ec8e780f296e0a82d60f3c1e0bdedd0e2f4914297569f57dcbca78182baaf1a0f6fd34105b25236b';

sub _to_hex {
    return unpack 'H*', shift;
}

my $copy = $csr_unix;
is(
    _to_hex( Crypt::Format::pem2der($csr_unix) ),
    $der_hex,
    'pem2der() with unix line breaks',
);
is( $csr_unix, $copy, '… and it doesn’t modify the original string' );

is(
    _to_hex( Crypt::Format::pem2der($csr_windows) ),
    $der_hex,
    'pem2der() with windows line breaks',
);

#----------------------------------------------------------------------

my $der = Crypt::Format::pem2der($csr_unix);

my $pem2 = Crypt::Format::der2pem($der, 'SOMETHING');

like(
    $pem2,
    qr<\A-----BEGIN SOMETHING-----.+\s-----END SOMETHING-----\z>s,
    "PEM conversion looks as expected",
);

is(
    _to_hex( Crypt::Format::pem2der($pem2) ),
    _to_hex( $der ),
    '… and it round-trips as expected',
);

dies_ok(
    sub { Crypt::Format::der2pem($der) },
    'die() without a WHATSIT',
);

#----------------------------------------------------------------------

my $rsa1024 = "-----BEGIN RSA PRIVATE KEY-----\r\nMIICXAIBAAKBgQDp+UdhCANyOWzHYFFeONAzIvAG4MLLsjk2WuzU4gUUSkjlei/R\r\nWGC0HE2uyw1WpAau4DPD4As1b8NwGXgA2i7r5Fzn8kOqUoMbrMaamtMACVbGAqhE\r\n/5Tx1Hpg2169eyTtl5pV6vamn+zxZzcKmj3SKO4z1MrqUUnXudlMAXy9pwIDAQAB\r\nAoGAeEJFWu04gDxd2fh6uhgvgykhABgEZ5haacLAWgc2HyCzaSetbkejpM+raf06\r\nBN9YBAh+8t20RSoF5RdiI+YBGQho/IJZ8/9V6ke1LNrzN8YkkOne0FneQCncUO+H\r\nSENFz9tylBVJFORA4qn5IiQ9TJ4wWn4qPaVkKatzXDd6fukCQQD6DkClMYLa7J8t\r\nOoIb00tKVEG31miln1aCwMBAgLyTvXvwORPCzspnRHN44JrAyUOEeqv2fztNppa1\r\nUgDUnMFVAkEA74koVftj2mbBN/venWmsJeLTOH+ozeHsRY3cjbPhGh/tu/EUvcmP\r\ncBH2fuNGo+8a/A3972uJM0ZcYzjX3UqzCwJAPo4QOANB1Bi73Wm0oNdkD20yn5Xg\r\nygYpcz5bGgfapS8S8U6mFeb7lYf3RzcRH8d5v4uct2au5EcXjra8BHROnQJBAJuq\r\nSNpHusaODHczaaJmsAcW9yk6XRse/QrefDxib6Eoqrh+nXoQ6PRt2ADx9lBG7QRs\r\nm1/iRJFb4mJg6HfZOa0CQA6zENKU6dd2KrWWeZLGNK8psbbRDpWao664GzFjZVjV\r\nbyO9XjrtBDbKgXo1PfQWGoj6wGAJtqn/BtWsKqqJh4A=\r\n-----END RSA PRIVATE KEY-----\r\n";

is(
    Digest::MD5::md5_hex( Crypt::Format::pem2der($rsa1024) ),
    '3f933039e47608686c60e9bf658f9944',
    'expected parse of a 1,024-bit RSA key',
);

my $rsa2048 = "-----BEGIN RSA PRIVATE KEY-----\r\nMIIEowIBAAKCAQEA75fIJY1my1tAGs6eKhjBBPZtTe5b9d0TByVR1RcZjaqpXJ8W\r\nlTEEieHWPt4AFUp0rKvFBoDEwmP8o2/EYQZBfBITWLoVzp1isKE/o+Dm3Y77dQgd\r\nMLBZby8Ohx7kPJPTJMghymV4xZPL8ZI4T8n/Xbd8cPyKW81XaYh0GLk5iF77w3/q\r\npPEcy/fkiIXmkausIJ9CQK9S4oTgpp4fhO13/M8bXPhfNv1j2IvxkB2RsfrvnUfq\r\n2GRrKENmG0PAh51J2ixyy+xSbK12Z1lW8QdPvuayzQnj2ru6+GG0UqQOD0IRA83b\r\n1aBtafzsay4lcwCkB/DKO008SKhFI3wQxw98YQIDAQABAoIBAHsh5UGvXwHp3pMo\r\nVs7JtAEp6FjhxC8iM9I7UsgRvBc7exjXxdJcw7lc8C+VBjPq9PV8vaAu82/31PHl\r\n0eYPQf5Sh9DUqbpq1jpyVHOTdPKutfqade3846mpZGz66k9bpWrE0+Dhr2TTJT/8\r\nZqZS6MOwNesXTsAJUwAwmYHPR4sWTvea6Gm8e9GQ/DOFaYhve50dsFwUsIobQ2oW\r\nEU0xZeq++CYpwWfgojsTCG1eGOCOaojyVNvBW19AprSO+qS+mhHU2mvq5zqeaq55\r\nSAcXt3BY6acSlUdEMCtLVqI/aEBnrQ1SKhzTuMWyxfzIS/NNcX7lHe5FYkE3H2Cd\r\nVsgQsbECgYEA+nOtdEvtx3xsNq7nl8xpJoFSqgNDqC2zian+9Pwmi3OgaUClH1eP\r\n2ebvyNsoHBzssk7nRQ3L6gH7AjIIsRbghEejplq6dFQSMAUTMNfqOGvF0drrsimq\r\ngHw877Cx02hksjFBT/jU5+hOvbp2kI50hu+sUdELoRgh38eVzCB3SQUCgYEA9OaF\r\nyyyr0mcvdCQ648qgNzlNgsEiFkvOwGf8ZMjFE37/kH/N4BGEMCyBiZcbVuaYDhxK\r\nLm3P4eT//mL3X9Pm9QsRNuhB9vwJwbyjqhEPDl7ebuOwonUIgdJY4RPheStQxMs2\r\ncSlEZCql4I7oLNGv2pIYRgL/f6udqEFEyar/1K0CgYA+v+ThknSM2puyR7g2zDw8\r\nLYKsngzBglHNWA5NCzANGHdEZ7H3XFTqX3YMePxfrs+PDT3ci0xf4Qcm0apj1DuE\r\naP6Tm3/DzZyQ83SPdEl2wWna3mLXTKEvd/E8jKTBNxKjoruecdXGFOpFlwZFyatg\r\nc4RVK28ieY1jJ/pcHnZEkQKBgDvYZVOL/ATzgC4ieF2X82TrVNyh84F9Tu3Hu26p\r\nfTdRboRSJu4dea8IATOtQFoRCZFRKnOEFCvAeSoh5w98ydCRvsgrI4uGdZ/pSBlU\r\nB9jcKADzFQPuE4Ed9OgzooKoqhkdC5XFntfXcCea5HOnXhDMaLAbJXJ+bo1iPbwG\r\nVHQVAoGBANux7Zl/liG+TBOmnhld7e8OUiAZ7XNd3JZvWZHqR+qAYLd9wUDyW0/Z\r\n6JCBUwR/lNnE6X6rE0jxqIKZP9LZ+a/wfy0Ar9rW7Dv+85TmXH0aeVdJEIC0E5UO\r\nU54MPiltDD0l1hZCfa2IqBdn6hC8gWYc5S6eEwec97HHHGVmwTFF\r\n-----END RSA PRIVATE KEY-----\r\n";

is(
    Digest::MD5::md5_hex( Crypt::Format::pem2der($rsa2048) ),
    '8b83970f208e8bba1ca43139e8a7f4a8',
    'expected parse of a 2,048-bit RSA key',
);

my $dec = Crypt::Format::pem2der("-----BEGIN WHATEVER-----\nAAAA\n----END WHATEVER-----");

is(
    $dec,
    "\0\0\0",
    'decode without trailing whitespace',
);
