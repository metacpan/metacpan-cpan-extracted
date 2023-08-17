use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);


my $unix = $^O eq 'MSWin32' ? 0 : 1;

if ($unix == 0) {
    # skip
    plan skip_all => "This test is not available on Windows";
}
ok($unix, "Running on Unix");

ok(curl_available(), "`curl` is available");
sub curl_available {
    eval {
        my $got = `curl --version`;
    };
    if ($@) {
        return 0;
    } else {
        return 1;
    }
    
}
done_testing();