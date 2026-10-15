use strict;
use warnings;

use Config;
use Test::More;

BEGIN {
    plan 'skip_all' => 'perl was built without ithreads' unless $Config{'useithreads'};
}

use threads;
use Crypt::Passwd::XS ();

# Each ithread is an OS thread, so concurrent unix_yescrypt_crypt() calls must
# not share an output buffer.  With one, a thread can return an empty string or
# another thread's hash.
my $threads    = 8;
my $iterations = 200;

my @vectors = (
    [ 'test1234', '$y$j5T$abcdefgh',   '$y$j5T$abcdefgh$.yCbNxmm3ocCRtD3gSSUvH1UujnjVMiv0oKzMDnl2r7' ],
    [ '',         '$y$j5T$abcdefgh',   '$y$j5T$abcdefgh$p9Oxoj5X7HzycbqQ1sEdPQIabvfLhlWqwjnJ6ONdUb4' ],
    [ 'test1234', '$y$j5T/.$abcdefgh', '$y$j5T/.$abcdefgh$JX14JrllGaYRK7ieVbXZv8F5lb5EodIZXUAsOVG/cc1' ],
    [ 'test1234', '$y$j2/$abcdefgh',   '$y$j2/$abcdefgh$oFJ2SuVPsUE3Px52cpnOFFnN4x4UugXx7e.EnlJXRLB' ],
);

my @workers = map {
    my $vector = $vectors[ $_ % @vectors ];
    threads->create(
        sub {
            my ( $pass, $salt, $crypted ) = @$vector;
            my $mismatches = 0;
            for ( 1 .. $iterations ) {
                $mismatches++ if Crypt::Passwd::XS::unix_yescrypt_crypt( $pass, $salt ) ne $crypted;
            }
            return $mismatches;
        }
    );
} 0 .. $threads - 1;

my $mismatches = 0;
$mismatches += $_->join() for @workers;

is( $mismatches, 0, "$threads concurrent threads each get their own yescrypt hash" );

done_testing();
