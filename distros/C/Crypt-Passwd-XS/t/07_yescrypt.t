use strict;
use warnings;

use Test::More 'tests' => 36;
use Time::HiRes ();
use Crypt::Passwd::XS ();

# Known-answer vectors produced by libxcrypt 4.5.2 (the yescrypt implementation
# shipped by Debian, Ubuntu, Fedora and RHEL 10).  $y$j9T$ is the distro default
# (N=4096, r=32); the rest use small N so the test stays fast.
my $j9t_salt = '$y$j9T$PKXc3hCOSyMqdaEQArI62/';
my $j9t_hash = $j9t_salt . '$EP73pbb9EC06uqK4QjM1bmX9ldEld3UiLtFldtyR5P0';

my $checks = [
    [ 'test1234', $j9t_salt,         $j9t_hash ],
    [ 'test1234', $j9t_hash,         $j9t_hash ],    # a stored hash works as the setting
    [ 'pw',       '$y$j9T$abcdefgh', '$y$j9T$abcdefgh$UGYCVcUwcoG0k8SZZ.Uz3i0RYQNy1YmYj4I4poBPer2' ],

    # Other flavors, cost settings and the t parameter
    [ 'test1234', '$y$j5T$abcdefgh',   '$y$j5T$abcdefgh$.yCbNxmm3ocCRtD3gSSUvH1UujnjVMiv0oKzMDnl2r7' ],
    [ 'test1234', '$y$j5T/.$abcdefgh', '$y$j5T/.$abcdefgh$JX14JrllGaYRK7ieVbXZv8F5lb5EodIZXUAsOVG/cc1' ],
    [ 'test1234', '$y$j5T/1$abcdefgh', '$y$j5T/1$abcdefgh$vShdiOWCmEuT1X/MkIYTOZcigHOT9gx.X8U9LQ0Bg69' ],
    [ 'test1234', '$y$.5T$abcdefgh',   '$y$.5T$abcdefgh$p1lZ30ABEhi/wQOvbEU5JiFxZesdC/5mrVFYSXlpfl/' ],
    [ 'test1234', '$y$/5T$abcdefgh',   '$y$/5T$abcdefgh$SoZ4eMMBAcaYISxozB03zuApKzBhHEPDe.bre..B0m3' ],
    [ 'test1234', '$y$j51$abcdefgh',   '$y$j51$abcdefgh$FgwMzCyUrjq9nxOXUww0F91dliysY36jx6X80obf4X/' ],
    [ 'test1234', '$y$j2/$abcdefgh',   '$y$j2/$abcdefgh$oFJ2SuVPsUE3Px52cpnOFFnN4x4UugXx7e.EnlJXRLB' ],
    [ 'test1234', '$y$j5T$',           '$y$j5T$$b.4p2nFDQYj9tJ9M.SGE/LicHtGXdxbJFuMCsoZcdY5' ],

    # Empty and undef passwords
    [ '',    '$y$j5T$abcdefgh', '$y$j5T$abcdefgh$p9Oxoj5X7HzycbqQ1sEdPQIabvfLhlWqwjnJ6ONdUb4' ],
    [ undef, '$y$j5T$abcdefgh', '$y$j5T$abcdefgh$p9Oxoj5X7HzycbqQ1sEdPQIabvfLhlWqwjnJ6ONdUb4' ],

    # High-bit bytes (UTF-8 for "ünï")
    [ "\xc3\xbcn\xc3\xaf", '$y$j5T$abcdefgh', '$y$j5T$abcdefgh$VdDdLG0rbY3QoGhupJQHDHyG/Vj.QO9/r83td/Lp/YD' ],

    # The hash field of the setting is ignored, however odd it looks
    [ 'test1234', '$y$j5T$abcdefgh$trailing', '$y$j5T$abcdefgh$.yCbNxmm3ocCRtD3gSSUvH1UujnjVMiv0oKzMDnl2r7' ],
];

foreach my $check_ref (@$checks) {
    my ( $pass, $salt, $crypted ) = @$check_ref;
    is( Crypt::Passwd::XS::unix_yescrypt_crypt( $pass, $salt ), $crypted, "unix_yescrypt_crypt: $salt" );
}

# crypt() dispatches on the $y$ prefix
is( Crypt::Passwd::XS::crypt( 'test1234', $j9t_salt ), $j9t_hash, 'crypt() dispatches $y$' );

# Missing salt, and the scrypt ($7$) scheme that yescrypt_r() would also accept
is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', undef ), '', 'undef salt returns empty string' );
is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', '' ),    '', 'empty salt returns empty string' );
is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', '$7$CU..../....abcdefgh' ), '', 'scrypt $7$ setting is refused' );

# Malformed settings return an empty string
foreach my $setting (
    '$y$',
    '$y$j',
    '$y$j9T',
    '$y$!5T$abcdefgh',           # bad flavor character
    '$y$j5T$ab+',                # bad base64 character in the salt
    '$y$j5T$abcdefgh$a$b',       # '$' inside the salt field
  ) {
    is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', $setting ), '', "rejects $setting" );
}

# Parameters we do not support: p > 1, hash upgrades (g) and a ROM
is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', '$y$j5T.7$abcdefgh' ), '', 'rejects p > 1' );
is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', '$y$j5T1.$abcdefgh' ), '', 'rejects g = 1' );
is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', '$y$j5T5.$abcdefgh' ), '', 'rejects a ROM' );

# Exactly at the 1 GiB cost cap: 1 MiB V array, t = 1023 (libxcrypt 4.5.2)
is(
    Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', '$y$j5T/s5C$abcdefgh' ),
    '$y$j5T/s5C$abcdefgh$0MkFmThkhKVLXfpOLiK0DOs.ls5tzFP15GAwyjJXKyA',
    'setting at the cost cap is accepted'
);

# Settings over the 1 GiB cost cap (V array size times t + 1) are refused up
# front, not attempted.  $y$jFT$ is exactly 1 GiB (accepted, but too heavy to
# run here); $y$jGT$ is 2 GiB and $y$jLT$ is 64 GiB.  With t, $y$jFT/.$ (1 GiB,
# t = 1) and $y$j5T/s5D$ (1 MiB, t = 1024) are just over the cap.
#
# r is capped at 32 (the most libxcrypt generates) because the buffers outside
# the V array and the work outside the V passes grow with r: $y$j5U$ is r = 33
# with a tiny V, and $y$j/y3vrD$ (N = 4, r = 2^21) fits the budget exactly but
# would take 1.5 GiB and several seconds.
my $start = Time::HiRes::time();
foreach my $setting ( '$y$jGT$salt', '$y$jLT$salt', '$y$jFT/.$abcdefgh', '$y$j5T/s5D$abcdefgh', '$y$j5U$abcdefgh', '$y$j/y3vrD$abcdefgh' ) {
    is( Crypt::Passwd::XS::unix_yescrypt_crypt( 'test1234', $setting ), '', "over-cap $setting is refused" );
}
cmp_ok( Time::HiRes::time() - $start, '<', 5, 'over-cap settings are refused without doing work' );
