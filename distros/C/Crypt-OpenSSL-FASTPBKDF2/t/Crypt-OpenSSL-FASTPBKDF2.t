# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-OpenSSL-FASTPBKDF2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Crypt::OpenSSL::FASTPBKDF2', qw/fastpbkdf2_hmac_sha1 fastpbkdf2_hmac_sha256 fastpbkdf2_hmac_sha512/) };

use constant HMAC_SUBS => {
#   sha0 => $subref
    sha1 => \&fastpbkdf2_hmac_sha1,
    sha256 => \&fastpbkdf2_hmac_sha256,
    sha512 => \&fastpbkdf2_hmac_sha512,
};

use constant HMAC_DATA => {
#   sha0 => [ [password, salt, iterations, hex_output_expected] ... ]
    sha1 => [
        ['password', 'salt', 1, '0c60c80f961f0e71f3a9b524af6012062fe037a6'],
        ['password', 'salt', 2, 'ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957'],
        ['password', 'salt', 4096, '4b007901b765489abead49d926f721d065a429c1'],
        # ['password', 'salt', 16777216, 'eefe3d61cd4da4e4e9945b3d6ba2158c2634e984'],
        ['passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 4096, '3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038'],
        ["pass\x00\x77\x6f\x72\x64", "sa\x00\x6c\x74", 4096, '56fa6aa75548099dcc37d7f03425e0c3'],
    ],
    sha256 => [
        ['passwd', 'salt', 1, '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783'],
        ['Password', 'NaCl', 80000, '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d'],
        ['password', 'salt', 1, '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b'],
        ['password', 'salt', 2, 'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43'],
        ['password', 'salt', 4096, 'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a'],
        ['passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 4096, '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1c635518c7dac47e9'],
        ['', 'salt', 1024, '9e83f279c040f2a11aa4a02b24c418f2d3cb39560c9627fa4f47e3bcc2897c3d'],
        ['password', '', 1024, 'ea5808411eb0c7e830deab55096cee582761e22a9bc034e3ece925225b07bf46'],
        ["pass\x00\x77\x6f\x72\x64", "sa\x00\x6c\x74", 4096, '89b69d0516f829893c696226650a8687'],
    ],
    sha512 => [
        ['password', 'salt', 1, '867f70cf1ade02cff3752599a3a53dc4af34c7a669815ae5d513554e1c8cf252'],
        ['pass?word', 'sa?lt', 1, '1152b919494add6c32d7b61db35aa875c5efc25be376a1f724b5e9d19338c8ca'],
        ['password', 'salt', 2, 'e1d9c16aa681708a45f5c7c4e215ceb66e011a2e9f0040713f18aefdb866d53c'],
        ['password', 'salt', 4096, 'd197b1b33db0143e018b12f3d1d1479e6cdebdcc97c5c0f87f6902e072f457b5'],
        ['passwordPASSWORDpassword', 'saltSALTsaltSALTsaltSALTsaltSALTsalt', 1, '6e23f27638084b0f7ea1734e0d9841f55dd29ea60a834466f3396bac801fac1eeb63802f03a0b4acd7603e3699c8b74437be83ff01ad7f55dac1ef60f4d56480c35ee68fd52c6936'],
    ],
};

# This must match the number of main tests (subtests each count as main test)
my $number_of_tests = 1 + keys %{HMAC_SUBS()};

# Test against expected hmac_data
sub data_test($) {
    my $hmac = shift;
    my $test_sub = HMAC_SUBS()->{$hmac};
    my $test_data = HMAC_DATA()->{$hmac};

    subtest "HMAC $hmac"=>sub {
        plan tests => 1 + scalar @$test_data;
        my @buffer;

        # Data Test
        foreach my $t (@$test_data) {
            my ($pw, $salt, $iterations, $expected) = @$t;
            my $out_len = length($expected)/2;
            my $output = $test_sub->($pw, $salt, $iterations, $out_len, \@buffer);
            is( unpack('H*', $output), $expected, $hmac.' data' );
        }

        # Buffer Test
        my @buf_expected = map { $_->[3] } @$test_data;
        my @buf_output = map { unpack('H*', $_) } @buffer;
        is_deeply(\@buf_output, \@buf_expected, $hmac.' buffer');
    };
};

data_test($_) foreach (keys %{HMAC_DATA()});
done_testing($number_of_tests);
